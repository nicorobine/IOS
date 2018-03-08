/*
 * This file is part of the SDWebImage package.
 * (c) Olivier Poitrey <rs@dailymotion.com>
 *
 * For the full copyright and license information, please view the LICENSE
 * file that was distributed with this source code.
 */

#import "SDWebImageDownloader.h"
#import "SDWebImageDownloaderOperation.h"

// wwt 旗语锁
#define LOCK(lock) dispatch_semaphore_wait(lock, DISPATCH_TIME_FOREVER);
#define UNLOCK(lock) dispatch_semaphore_signal(lock);

@interface SDWebImageDownloadToken ()

@property (nonatomic, weak, nullable) NSOperation<SDWebImageDownloaderOperationInterface> *downloadOperation;

@end

@implementation SDWebImageDownloadToken

// wwt 取消下载
- (void)cancel {
    if (self.downloadOperation) {
        SDWebImageDownloadToken *cancelToken = self.downloadOperationCancelToken;
        if (cancelToken) {
            [self.downloadOperation cancel:cancelToken];
        }
    }
}

@end


@interface SDWebImageDownloader () <NSURLSessionTaskDelegate, NSURLSessionDataDelegate>

// wwt 下载队列
@property (strong, nonatomic, nonnull) NSOperationQueue *downloadQueue;

@property (weak, nonatomic, nullable) NSOperation *lastAddedOperation;

@property (assign, nonatomic, nullable) Class operationClass;
// wwt 下载操作和URL组成的键值对字典
@property (strong, nonatomic, nonnull) NSMutableDictionary<NSURL *, SDWebImageDownloaderOperation *> *URLOperations;
// wwt http头字典
@property (strong, nonatomic, nullable) SDHTTPHeadersMutableDictionary *HTTPHeaders;
// wwt 线程安全的访问URLOperations的锁
@property (strong, nonatomic, nonnull) dispatch_semaphore_t operationsLock; // a lock to keep the access to `URLOperations` thread-safe
// wwt 线程安全的访问HTTPHeaders的锁
@property (strong, nonatomic, nonnull) dispatch_semaphore_t headersLock; // a lock to keep the access to `HTTPHeaders` thread-safe

// wwt 任务运行的session
// The session in which data tasks will run
@property (strong, nonatomic) NSURLSession *session;

@end

@implementation SDWebImageDownloader

+ (void)initialize {
    // wwt 如果SDNetworkActivityIndicator可用的话，绑定它。使用的时候在导入SDWebImage头的同时导入SDNetworkActivityIndicator.h
    // Bind SDNetworkActivityIndicator if available (download it here: http://github.com/rs/SDNetworkActivityIndicator )
    // To use it, just add #import "SDNetworkActivityIndicator.h" in addition to the SDWebImage import
    if (NSClassFromString(@"SDNetworkActivityIndicator")) {

// wwt 因为检查不到selector的定义，消除找不到方法的警告
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
        id activityIndicator = [NSClassFromString(@"SDNetworkActivityIndicator") performSelector:NSSelectorFromString(@"sharedActivityIndicator")];
#pragma clang diagnostic pop
        
        // wwt 移除以前添加的观察者，添加新的观察者
        // Remove observer in case it was previously added.
        [[NSNotificationCenter defaultCenter] removeObserver:activityIndicator name:SDWebImageDownloadStartNotification object:nil];
        [[NSNotificationCenter defaultCenter] removeObserver:activityIndicator name:SDWebImageDownloadStopNotification object:nil];

        [[NSNotificationCenter defaultCenter] addObserver:activityIndicator
                                                 selector:NSSelectorFromString(@"startActivity")
                                                     name:SDWebImageDownloadStartNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:activityIndicator
                                                 selector:NSSelectorFromString(@"stopActivity")
                                                     name:SDWebImageDownloadStopNotification object:nil];
    }
}

// wwt 单例模式
+ (nonnull instancetype)sharedDownloader {
    static dispatch_once_t once;
    static id instance;
    dispatch_once(&once, ^{
        instance = [self new];
    });
    return instance;
}

// wwt 初始化方法
- (nonnull instancetype)init {
    return [self initWithSessionConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration]];
}

// wwt 初始化方法（具体的）
- (nonnull instancetype)initWithSessionConfiguration:(nullable NSURLSessionConfiguration *)sessionConfiguration {
    if ((self = [super init])) {
        // wwt 使用默认的下载操作
        _operationClass = [SDWebImageDownloaderOperation class];
        // wwt 默认解压图像
        _shouldDecompressImages = YES;
        // wwt 下载顺序为先进先出
        _executionOrder = SDWebImageDownloaderFIFOExecutionOrder;
        // wwt 初始化下载队列，默认最大并发6个
        _downloadQueue = [NSOperationQueue new];
        _downloadQueue.maxConcurrentOperationCount = 6;
        _downloadQueue.name = @"com.hackemist.SDWebImageDownloader";
        // wwt 初始化URLOperation
        _URLOperations = [NSMutableDictionary new];
        
        // wwt 根据是否支持webP格式设置httpHeaders
#ifdef SD_WEBP
        _HTTPHeaders = [@{@"Accept": @"image/webp,image/*;q=0.8"} mutableCopy];
#else
        _HTTPHeaders = [@{@"Accept": @"image/*;q=0.8"} mutableCopy];
#endif
        // wwt 初始化op锁和httpHeaders的锁
        _operationsLock = dispatch_semaphore_create(1);
        _headersLock = dispatch_semaphore_create(1);
        // wwt 默认超时时间
        _downloadTimeout = 15.0;
        
        // wwt 创建session配置
        [self createNewSessionWithConfiguration:sessionConfiguration];
    }
    return self;
}

// wwt 配置session
// wwt @note 需要注意的是设置新的configuration的时候会取消以前的所有下载操作
- (void)createNewSessionWithConfiguration:(NSURLSessionConfiguration *)sessionConfiguration {
    // wwt 取消所有进行的下载
    [self cancelAllDownloads];
    
    // wwt 已经存在session，使session无效
    if (self.session) {
        [self.session invalidateAndCancel];
    }
    
    // wwt 设置超时时间
    sessionConfiguration.timeoutIntervalForRequest = self.downloadTimeout;

    /**
     * wwt 为这次任务创建session。代理队列传入nil是让session自己创建一个代理队列
     *  Create the session for this task
     *  We send nil as delegate queue so that the session creates a serial operation queue for performing all delegate
     *  method calls and completion handler calls.
     */
    self.session = [NSURLSession sessionWithConfiguration:sessionConfiguration
                                                 delegate:self
                                            delegateQueue:nil];
}

// wwt 是session无效
- (void)invalidateSessionAndCancel:(BOOL)cancelPendingOperations {
    // wwt 单例模式不支持
    if (self == [SDWebImageDownloader sharedDownloader]) {
        return;
    }
    // wwt 根据是否取消等待的操作，决定session是否取消
    if (cancelPendingOperations) {
        [self.session invalidateAndCancel];
    } else {
        [self.session finishTasksAndInvalidate];
    }
}

// wwt 对象被释放的时候取消所有操作
- (void)dealloc {
    [self.session invalidateAndCancel];
    self.session = nil;

    [self.downloadQueue cancelAllOperations];
}

// wwt 为httpHeader添加一个字段（线程安全）
- (void)setValue:(nullable NSString *)value forHTTPHeaderField:(nullable NSString *)field {
    LOCK(self.headersLock);
    if (value) {
        self.HTTPHeaders[field] = value;
    } else {
        [self.HTTPHeaders removeObjectForKey:field];
    }
    UNLOCK(self.headersLock);
}

// wwt 根据http标题头字段的名字获取相应的值
- (nullable NSString *)valueForHTTPHeaderField:(nullable NSString *)field {
    if (!field) {
        return nil;
    }
    return [[self allHTTPHeaderFields] objectForKey:field];
}

// wwt 获取httpHeader的所有字段（线程安全）
- (nonnull SDHTTPHeadersDictionary *)allHTTPHeaderFields {
    LOCK(self.headersLock);
    SDHTTPHeadersDictionary *allHTTPHeaderFields = [self.HTTPHeaders copy];
    UNLOCK(self.headersLock);
    return allHTTPHeaderFields;
}

// wwt 设置最大下载并发数
- (void)setMaxConcurrentDownloads:(NSInteger)maxConcurrentDownloads {
    _downloadQueue.maxConcurrentOperationCount = maxConcurrentDownloads;
}

// wwt 当前下载的数目
- (NSUInteger)currentDownloadCount {
    return _downloadQueue.operationCount;
}

// wwt 当前最大并发下载数
- (NSInteger)maxConcurrentDownloads {
    return _downloadQueue.maxConcurrentOperationCount;
}

// wwt 获取session配置
- (NSURLSessionConfiguration *)sessionConfiguration {
    return self.session.configuration;
}

// wwt 设置执行下载操作的类，如果不是NSOperaton的子类或者没有实现SDWebImageDownloaderOperationInterface协议，则使用默认的下载操作
- (void)setOperationClass:(nullable Class)operationClass {
    if (operationClass && [operationClass isSubclassOfClass:[NSOperation class]] && [operationClass conformsToProtocol:@protocol(SDWebImageDownloaderOperationInterface)]) {
        _operationClass = operationClass;
    } else {
        _operationClass = [SDWebImageDownloaderOperation class];
    }
}

// wwt 下载图片
- (nullable SDWebImageDownloadToken *)downloadImageWithURL:(nullable NSURL *)url
                                                   options:(SDWebImageDownloaderOptions)options
                                                  progress:(nullable SDWebImageDownloaderProgressBlock)progressBlock
                                                 completed:(nullable SDWebImageDownloaderCompletedBlock)completedBlock {
    __weak SDWebImageDownloader *wself = self;

    return [self addProgressCallback:progressBlock completedBlock:completedBlock forURL:url createCallback:^SDWebImageDownloaderOperation *{
        __strong __typeof (wself) sself = wself;
        // wwt 配置超时时间
        NSTimeInterval timeoutInterval = sself.downloadTimeout;
        if (timeoutInterval == 0.0) {
            timeoutInterval = 15.0;
        }
        
        // wwt 为了避免重复缓存（NSURLCache和SDImageCache），除非设置了标识，否则金庸NSURLCache的缓存
        // In order to prevent from potential duplicate caching (NSURLCache + SDImageCache) we disable the cache for image requests if told otherwise
        NSURLRequestCachePolicy cachePolicy = options & SDWebImageDownloaderUseNSURLCache ? NSURLRequestUseProtocolCachePolicy : NSURLRequestReloadIgnoringLocalCacheData;
        // wwt 初始化request
        NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:url
                                                                    cachePolicy:cachePolicy
                                                                timeoutInterval:timeoutInterval];
        
        // wwt 是否管理cookies
        request.HTTPShouldHandleCookies = (options & SDWebImageDownloaderHandleCookies);
        // wwt 这是属性设置为yes，代表每次请求不去验证上次的请求是否已经返回（需要服务器保证请求和返回的顺序）；如果设置为NO则请求和响应时顺序的，只有前一个请求得到响应后才会进行下一个请求
        request.HTTPShouldUsePipelining = YES;
        
        // wwt 如果有设置httpHeader的block则执行block设置请求头，如果没有直接获取
        // wwt @note 使用block可以为header添加或者删除头字段
        if (sself.headersFilter) {
            request.allHTTPHeaderFields = sself.headersFilter(url, [sself allHTTPHeaderFields]);
        }
        else {
            request.allHTTPHeaderFields = [sself allHTTPHeaderFields];
        }
        
        // wwt 初始化下载队列
        SDWebImageDownloaderOperation *operation = [[sself.operationClass alloc] initWithRequest:request inSession:sself.session options:options];
        operation.shouldDecompressImages = sself.shouldDecompressImages;
        
        // wwt 如果设置了证书传递给下载op，或者如果设置了账号密码，根据账号密码生成证书（但是并没有传递给op🤔️）
        if (sself.urlCredential) {
            operation.credential = sself.urlCredential;
        } else if (sself.username && sself.password) {
            operation.credential = [NSURLCredential credentialWithUser:sself.username password:sself.password persistence:NSURLCredentialPersistenceForSession];
        }
        
        // wwt 设置下载优先级
        if (options & SDWebImageDownloaderHighPriority) {
            operation.queuePriority = NSOperationQueuePriorityHigh;
        } else if (options & SDWebImageDownloaderLowPriority) {
            operation.queuePriority = NSOperationQueuePriorityLow;
        }

        [sself.downloadQueue addOperation:operation];
        
        // wwt 如果是后入先出，设置依赖，保证先执行这个下载op
        if (sself.executionOrder == SDWebImageDownloaderLIFOExecutionOrder) {
            // Emulate LIFO execution order by systematically adding new operations as last operation's dependency
            [sself.lastAddedOperation addDependency:operation];
            sself.lastAddedOperation = operation;
        }

        return operation;
    }];
}

// wwt 根据token取消下载操作
- (void)cancel:(nullable SDWebImageDownloadToken *)token {
    NSURL *url = token.url;
    if (!url) {
        return;
    }
    LOCK(self.operationsLock);
    SDWebImageDownloaderOperation *operation = [self.URLOperations objectForKey:url];
    if (operation) {
        BOOL canceled = [operation cancel:token.downloadOperationCancelToken];
        if (canceled) {
            [self.URLOperations removeObjectForKey:url];
        }
    }
    UNLOCK(self.operationsLock);
}

// wwt 设置进度和完成回调block，生成httpHeader
- (nullable SDWebImageDownloadToken *)addProgressCallback:(SDWebImageDownloaderProgressBlock)progressBlock
                                           completedBlock:(SDWebImageDownloaderCompletedBlock)completedBlock
                                                   forURL:(nullable NSURL *)url
                                           createCallback:(SDWebImageDownloaderOperation *(^)(void))createCallback {
    // wwt URL会作为回调字典的key，所有不能为空
    // The URL will be used as the key to the callbacks dictionary so it cannot be nil. If it is nil immediately call the completed block with no image or data.
    if (url == nil) {
        if (completedBlock != nil) {
            completedBlock(nil, nil, nil, NO);
        }
        return nil;
    }
    
    // wwt 获取下载队列（线程安全）
    LOCK(self.operationsLock);
    SDWebImageDownloaderOperation *operation = [self.URLOperations objectForKey:url];
    if (!operation) {
        operation = createCallback();
        __weak typeof(self) wself = self;
        // wwt 将下载操作添加到URLOperations中，并在完成后从URLOperations中移除
        operation.completionBlock = ^{
            __strong typeof(wself) sself = wself;
            if (!sself) {
                return;
            }
            LOCK(sself.operationsLock);
            [sself.URLOperations removeObjectForKey:url];
            UNLOCK(sself.operationsLock);
        };
        [self.URLOperations setObject:operation forKey:url];
    }
    UNLOCK(self.operationsLock);
    
    // wwt 添加进度和完成block
    id downloadOperationCancelToken = [operation addHandlersForProgress:progressBlock completed:completedBlock];
    
    // wwt 生成sdWebImageToken并返回
    SDWebImageDownloadToken *token = [SDWebImageDownloadToken new];
    token.downloadOperation = operation;
    token.url = url;
    token.downloadOperationCancelToken = downloadOperationCancelToken;

    return token;
}

// wwt 挂起下载队列
- (void)setSuspended:(BOOL)suspended {
    self.downloadQueue.suspended = suspended;
}

// wwt 取消所有下载
- (void)cancelAllDownloads {
    [self.downloadQueue cancelAllOperations];
}

#pragma mark Helper methods

// wwt 根据tastk获取下载op
- (SDWebImageDownloaderOperation *)operationWithTask:(NSURLSessionTask *)task {
    SDWebImageDownloaderOperation *returnOperation = nil;
    for (SDWebImageDownloaderOperation *operation in self.downloadQueue.operations) {
        if (operation.dataTask.taskIdentifier == task.taskIdentifier) {
            returnOperation = operation;
            break;
        }
    }
    return returnOperation;
}

#pragma mark NSURLSessionDataDelegate

// wwt 收到响应的代理
- (void)URLSession:(NSURLSession *)session
          dataTask:(NSURLSessionDataTask *)dataTask
didReceiveResponse:(NSURLResponse *)response
 completionHandler:(void (^)(NSURLSessionResponseDisposition disposition))completionHandler {
    
    // wwt 获取对应dataTask的op，让op处理响应的代理
    // Identify the operation that runs this task and pass it the delegate method
    SDWebImageDownloaderOperation *dataOperation = [self operationWithTask:dataTask];
    if ([dataOperation respondsToSelector:@selector(URLSession:dataTask:didReceiveResponse:completionHandler:)]) {
        [dataOperation URLSession:session dataTask:dataTask didReceiveResponse:response completionHandler:completionHandler];
    } else {
        if (completionHandler) {
            completionHandler(NSURLSessionResponseAllow);
        }
    }
}

- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveData:(NSData *)data {
    
    // wwt 获取对应dataTask的op，让op处理响应的代理
    // Identify the operation that runs this task and pass it the delegate method
    SDWebImageDownloaderOperation *dataOperation = [self operationWithTask:dataTask];
    if ([dataOperation respondsToSelector:@selector(URLSession:dataTask:didReceiveData:)]) {
        [dataOperation URLSession:session dataTask:dataTask didReceiveData:data];
    }
}

- (void)URLSession:(NSURLSession *)session
          dataTask:(NSURLSessionDataTask *)dataTask
 willCacheResponse:(NSCachedURLResponse *)proposedResponse
 completionHandler:(void (^)(NSCachedURLResponse *cachedResponse))completionHandler {

    // wwt 获取对应dataTask的op，让op处理响应的代理
    // Identify the operation that runs this task and pass it the delegate method
    SDWebImageDownloaderOperation *dataOperation = [self operationWithTask:dataTask];
    if ([dataOperation respondsToSelector:@selector(URLSession:dataTask:willCacheResponse:completionHandler:)]) {
        [dataOperation URLSession:session dataTask:dataTask willCacheResponse:proposedResponse completionHandler:completionHandler];
    } else {
        if (completionHandler) {
            completionHandler(proposedResponse);
        }
    }
}

#pragma mark NSURLSessionTaskDelegate

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error {
    
    // wwt 获取对应dataTask的op，让op处理响应的代理
    // Identify the operation that runs this task and pass it the delegate method
    SDWebImageDownloaderOperation *dataOperation = [self operationWithTask:task];
    if ([dataOperation respondsToSelector:@selector(URLSession:task:didCompleteWithError:)]) {
        [dataOperation URLSession:session task:task didCompleteWithError:error];
    }
}

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task willPerformHTTPRedirection:(NSHTTPURLResponse *)response newRequest:(NSURLRequest *)request completionHandler:(void (^)(NSURLRequest * _Nullable))completionHandler {
    
    // wwt 获取对应dataTask的op，让op处理响应的代理
    // Identify the operation that runs this task and pass it the delegate method
    SDWebImageDownloaderOperation *dataOperation = [self operationWithTask:task];
    if ([dataOperation respondsToSelector:@selector(URLSession:task:willPerformHTTPRedirection:newRequest:completionHandler:)]) {
        [dataOperation URLSession:session task:task willPerformHTTPRedirection:response newRequest:request completionHandler:completionHandler];
    } else {
        if (completionHandler) {
            completionHandler(request);
        }
    }
}

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didReceiveChallenge:(NSURLAuthenticationChallenge *)challenge completionHandler:(void (^)(NSURLSessionAuthChallengeDisposition disposition, NSURLCredential *credential))completionHandler {

    // wwt 获取对应dataTask的op，让op处理响应的代理
    // Identify the operation that runs this task and pass it the delegate method
    SDWebImageDownloaderOperation *dataOperation = [self operationWithTask:task];
    if ([dataOperation respondsToSelector:@selector(URLSession:task:didReceiveChallenge:completionHandler:)]) {
        [dataOperation URLSession:session task:task didReceiveChallenge:challenge completionHandler:completionHandler];
    } else {
        if (completionHandler) {
            completionHandler(NSURLSessionAuthChallengePerformDefaultHandling, nil);
        }
    }
}

@end
