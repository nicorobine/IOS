/*
 * This file is part of the SDWebImage package.
 * (c) Olivier Poitrey <rs@dailymotion.com>
 *
 * For the full copyright and license information, please view the LICENSE
 * file that was distributed with this source code.
 */

#import "SDWebImageDownloaderOperation.h"
#import "SDWebImageManager.h"
#import "NSImage+WebCache.h"
#import "SDWebImageCodersManager.h"

#define LOCK(lock) dispatch_semaphore_wait(lock, DISPATCH_TIME_FOREVER);
#define UNLOCK(lock) dispatch_semaphore_signal(lock);

NSString *const SDWebImageDownloadStartNotification = @"SDWebImageDownloadStartNotification";
NSString *const SDWebImageDownloadReceiveResponseNotification = @"SDWebImageDownloadReceiveResponseNotification";
NSString *const SDWebImageDownloadStopNotification = @"SDWebImageDownloadStopNotification";
NSString *const SDWebImageDownloadFinishNotification = @"SDWebImageDownloadFinishNotification";

// wwt 下载进度回调block在字典中的key
static NSString *const kProgressCallbackKey = @"progress";
// wwt 下载完成回调block在字典中的key
static NSString *const kCompletedCallbackKey = @"completed";

// wwt 定义SD字典类型 装逼用的，不过也直观
typedef NSMutableDictionary<NSString *, id> SDCallbacksDictionary;

@interface SDWebImageDownloaderOperation ()

// wwt 回调block数组
@property (strong, nonatomic, nonnull) NSMutableArray<SDCallbacksDictionary *> *callbackBlocks;

// wwt 自定义operation使用，更改完成和运行状态
@property (assign, nonatomic, getter = isExecuting) BOOL executing;
@property (assign, nonatomic, getter = isFinished) BOOL finished;

// wwt 图片数据
@property (strong, nonatomic, nullable) NSMutableData *imageData;

// wwt NSURLCache中的缓存的数据
@property (copy, nonatomic, nullable) NSData *cachedData; // for `SDWebImageDownloaderIgnoreCachedResponse`

// wwt 这个属性是weak的，因为它是被管理这个session的对象传入的，如果sessin变为nil，我们将无法运行。任务是和operation关联在一起的

// This is weak because it is injected by whoever manages this session. If this gets nil-ed out, we won't be able to run
// the task associated with this operation
@property (weak, nonatomic, nullable) NSURLSession *unownedSession;

// wwt 如果我们不传入session，就需要设置这个值。同时我们有责任使这个值无效
// This is set if we're using not using an injected NSURLSession. We're responsible of invalidating this one
@property (strong, nonatomic, nullable) NSURLSession *ownedSession;

// wwt 请求的任务
@property (strong, nonatomic, readwrite, nullable) NSURLSessionTask *dataTask;

// wwt 回调的旗语锁，保证线程安全的访问callbackBlocks
@property (strong, nonatomic, nonnull) dispatch_semaphore_t callbacksLock; // a lock to keep the access to `callbackBlocks` thread-safe

// wwt 图片解码使用的队列
@property (strong, nonatomic, nonnull) dispatch_queue_t coderQueue; // the queue to do image decoding

// wwt 后台任务Id，用来在后台任务完成时结束后台任务
#if SD_UIKIT
@property (assign, nonatomic) UIBackgroundTaskIdentifier backgroundTaskId;
#endif

// wwt 实现图片编码、解码解压缩的对象，该对象需要实现SDWebImageProgressiveCoder协议
@property (strong, nonatomic, nullable) id<SDWebImageProgressiveCoder> progressiveCoder;

@end

@implementation SDWebImageDownloaderOperation

@synthesize executing = _executing;
@synthesize finished = _finished;

// wwt 默认初始化
- (nonnull instancetype)init {
    return [self initWithRequest:nil inSession:nil options:0];
}

// wwt 指定request和session的初始化
- (nonnull instancetype)initWithRequest:(nullable NSURLRequest *)request
                              inSession:(nullable NSURLSession *)session
                                options:(SDWebImageDownloaderOptions)options {
    if ((self = [super init])) {
        // wwt copy一份请求，防止request对象被释放
        _request = [request copy];
        // wwt 默认解压图片，如果有内存警告，需要设置成NO，但是性能会下降，解压会放到试图展示的时候
        _shouldDecompressImages = YES;
        // wwt 下载设置
        _options = options;
        // wwt 初始化回调block数组
        _callbackBlocks = [NSMutableArray new];
        // 为异步operation做准备
        _executing = NO;
        _finished = NO;
        _expectedSize = 0;
        _unownedSession = session;
        // wwt 创建旗语锁
        _callbacksLock = dispatch_semaphore_create(1);
        // wwt 创建解码队列
        _coderQueue = dispatch_queue_create("com.hackemist.SDWebImageDownloaderOperationCoderQueue", DISPATCH_QUEUE_SERIAL);
    }
    return self;
}

// wwt 设置过程和完成block，返回回调block字典作为token
- (nullable id)addHandlersForProgress:(nullable SDWebImageDownloaderProgressBlock)progressBlock
                            completed:(nullable SDWebImageDownloaderCompletedBlock)completedBlock {
    SDCallbacksDictionary *callbacks = [NSMutableDictionary new];
    if (progressBlock) callbacks[kProgressCallbackKey] = [progressBlock copy];
    if (completedBlock) callbacks[kCompletedCallbackKey] = [completedBlock copy];
    
    // wwt 添加回调block时是线程安全的
    LOCK(self.callbacksLock);
    [self.callbackBlocks addObject:callbacks];
    UNLOCK(self.callbacksLock);
    return callbacks;
}

// wwt 根据关键字获取回调block
- (nullable NSArray<id> *)callbacksForKey:(NSString *)key {
    
    // wwt 线程安全的获取回调数组
    // wwt @note NSArray对象的-valueForKey:能够获取到它NSDictionary类型的元素的key对应的对象
    LOCK(self.callbacksLock);
    NSMutableArray<id> *callbacks = [[self.callbackBlocks valueForKey:key] mutableCopy];
    UNLOCK(self.callbacksLock);
    // wwt 这里删除NSNull类型的对象，因为并不是所有的对象都设置了现在进程回调block
    // We need to remove [NSNull null] because there might not always be a progress block for each callback
    [callbacks removeObjectIdenticalTo:[NSNull null]];
    return [callbacks copy]; // strip mutability here
}

// wwt 根据token取消
- (BOOL)cancel:(nullable id)token {
    // wwt 标记是否应该移除
    BOOL shouldCancel = NO;
    // wwt 线程安全的移除token（也就是存放block的字典）
    // wwt 也许调用了多次addHandlersForProgress:completed:方法，只有所有回调block被清除的时候才会真正的取消op
    LOCK(self.callbacksLock);
    [self.callbackBlocks removeObjectIdenticalTo:token];
    if (self.callbackBlocks.count == 0) {
        shouldCancel = YES;
    }
    UNLOCK(self.callbacksLock);
    if (shouldCancel) {
        [self cancel];
    }
    return shouldCancel;
}

// wwt operation开始执行，直接在start方法实现，并没有重写-main方法
- (void)start {
    // wwt 线程安全
    // wwt 判断是否op是否取消了，如果取消了更改finished状态，重新设置
    @synchronized (self) {
        if (self.isCancelled) {
            self.finished = YES;
            [self reset];
            return;
        }

#if SD_UIKIT
        Class UIApplicationClass = NSClassFromString(@"UIApplication");
        BOOL hasApplication = UIApplicationClass && [UIApplicationClass respondsToSelector:@selector(sharedApplication)];
        // wwt 如果有应用程序单例和允许后台下载
        if (hasApplication && [self shouldContinueWhenAppEntersBackground]) {
            // wwt weakSelf和StrongSelf的经典写法
            __weak __typeof__ (self) wself = self;
            UIApplication * app = [UIApplicationClass performSelector:@selector(sharedApplication)];
            self.backgroundTaskId = [app beginBackgroundTaskWithExpirationHandler:^{
                // wwt 这里使用strongself防止weakSelf被释放
                __strong __typeof (wself) sself = wself;

                if (sself) {
                    [sself cancel];

                    [app endBackgroundTask:sself.backgroundTaskId];
                    sself.backgroundTaskId = UIBackgroundTaskInvalid;
                }
            }];
        }
#endif
        // wwt 这里判断传入的session是否为nil，如果没有传入session，则使用默认的session
        NSURLSession *session = self.unownedSession;
        if (!session) {
            NSURLSessionConfiguration *sessionConfig = [NSURLSessionConfiguration defaultSessionConfiguration];
            sessionConfig.timeoutIntervalForRequest = 15;
            
            /**
             *  Create the session for this task
             *  We send nil as delegate queue so that the session creates a serial operation queue for performing all delegate
             *  method calls and completion handler calls.
             */
            session = [NSURLSession sessionWithConfiguration:sessionConfig
                                                    delegate:self
                                               delegateQueue:nil];
            self.ownedSession = session;
        }
        
        // wwt 处理从NSURLCache获取数据的情况
        if (self.options & SDWebImageDownloaderIgnoreCachedResponse) {
            // Grab the cached data for later check
            NSURLCache *URLCache = session.configuration.URLCache;
            if (!URLCache) {
                URLCache = [NSURLCache sharedURLCache];
            }
            NSCachedURLResponse *cachedResponse;
            // wwt 因为cachedResponseForRequest:不是线程安全的，这里需要加锁
            // NSURLCache's `cachedResponseForRequest:` is not thread-safe, see https://developer.apple.com/documentation/foundation/nsurlcache#2317483
            @synchronized (URLCache) {
                cachedResponse = [URLCache cachedResponseForRequest:self.request];
            }
            if (cachedResponse) {
                self.cachedData = cachedResponse.data;
            }
        }
        
        // wwt 根据session建立数据任务
        self.dataTask = [session dataTaskWithRequest:self.request];
        self.executing = YES;
    }
    
    // wwt 开始任务
    if (self.dataTask) {
        [self.dataTask resume];
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wunguarded-availability"
        // wwt 设置下载优先级
        if ([self.dataTask respondsToSelector:@selector(setPriority:)]) {
            if (self.options & SDWebImageDownloaderHighPriority) {
                self.dataTask.priority = NSURLSessionTaskPriorityHigh;
            } else if (self.options & SDWebImageDownloaderLowPriority) {
                self.dataTask.priority = NSURLSessionTaskPriorityLow;
            }
        }
#pragma clang diagnostic pop
        // wwt 回调进度block
        for (SDWebImageDownloaderProgressBlock progressBlock in [self callbacksForKey:kProgressCallbackKey]) {
            progressBlock(0, NSURLResponseUnknownLength, self.request.URL);
        }
        // 在主线程中发送通知，🤔️暂时不知道为什么用weakself
        __weak typeof(self) weakSelf = self;
        dispatch_async(dispatch_get_main_queue(), ^{
            [[NSNotificationCenter defaultCenter] postNotificationName:SDWebImageDownloadStartNotification object:weakSelf];
        });
    }
    // wwt 如果没能初始化任务，执行错误回调
    else {
        [self callCompletionBlocksWithError:[NSError errorWithDomain:NSURLErrorDomain code:NSURLErrorUnknown userInfo:@{NSLocalizedDescriptionKey : @"Task can't be initialized"}]];
        [self done];
        return;
    }

#if SD_UIKIT
    Class UIApplicationClass = NSClassFromString(@"UIApplication");
    if(!UIApplicationClass || ![UIApplicationClass respondsToSelector:@selector(sharedApplication)]) {
        return;
    }
    
    // wwt 如果后台任务没有结束，结束后台任务
    if (self.backgroundTaskId != UIBackgroundTaskInvalid) {
        UIApplication * app = [UIApplication performSelector:@selector(sharedApplication)];
        [app endBackgroundTask:self.backgroundTaskId];
        self.backgroundTaskId = UIBackgroundTaskInvalid;
    }
#endif
}

// wwt 线程安全的取消
- (void)cancel {
    @synchronized (self) {
        [self cancelInternal];
    }
}

// wwt n内部取消
- (void)cancelInternal {
    // wwt 已经取消了直接返回
    if (self.isFinished) return;
    [super cancel];
    
    // wwt 如果有任务，结束任务，发送下载停止通知，更改op运行状态
    if (self.dataTask) {
        [self.dataTask cancel];
        __weak typeof(self) weakSelf = self;
        dispatch_async(dispatch_get_main_queue(), ^{
            [[NSNotificationCenter defaultCenter] postNotificationName:SDWebImageDownloadStopNotification object:weakSelf];
        });

        // As we cancelled the task, its callback won't be called and thus won't
        // maintain the isFinished and isExecuting flags.
        if (self.isExecuting) self.executing = NO;
        if (!self.isFinished) self.finished = YES;
    }

    [self reset];
}

// wwt 更新op的状态
- (void)done {
    self.finished = YES;
    self.executing = NO;
    [self reset];
}

// wwt 清除回调block，使session无效，dataTask置为nil
- (void)reset {
    LOCK(self.callbacksLock);
    [self.callbackBlocks removeAllObjects];
    UNLOCK(self.callbacksLock);
    self.dataTask = nil;
    
    if (self.ownedSession) {
        [self.ownedSession invalidateAndCancel];
        self.ownedSession = nil;
    }
}

// wwt 重写finished方法
- (void)setFinished:(BOOL)finished {
    [self willChangeValueForKey:@"isFinished"];
    _finished = finished;
    [self didChangeValueForKey:@"isFinished"];
}

// wwt 重写executing方法
- (void)setExecuting:(BOOL)executing {
    [self willChangeValueForKey:@"isExecuting"];
    _executing = executing;
    [self didChangeValueForKey:@"isExecuting"];
}

// wwt 是否是并发的
- (BOOL)isConcurrent {
    return YES;
}

#pragma mark NSURLSessionDataDelegate

// wwt 请求收到响应的回调
- (void)URLSession:(NSURLSession *)session
          dataTask:(NSURLSessionDataTask *)dataTask
didReceiveResponse:(NSURLResponse *)response
 completionHandler:(void (^)(NSURLSessionResponseDisposition disposition))completionHandler {
    // wwt 允许继续加载
    NSURLSessionResponseDisposition disposition = NSURLSessionResponseAllow;
    // wwt 获取预估数据大小
    NSInteger expected = (NSInteger)response.expectedContentLength;
    expected = expected > 0 ? expected : 0;
    self.expectedSize = expected;
    self.response = response;
    NSInteger statusCode = [response respondsToSelector:@selector(statusCode)] ? ((NSHTTPURLResponse *)response).statusCode : 200;
    BOOL valid = statusCode < 400;
    //'304 Not Modified' is an exceptional one. It should be treated as cancelled if no cache data
    //URLSession current behavior will return 200 status code when the server respond 304 and URLCache hit. But this is not a standard behavior and we just add a check
    if (statusCode == 304 && !self.cachedData) {
        valid = NO;
    }
    
    // wwt 如果response返回状态正常执行进度回调block，否则disposition设置为取消
    if (valid) {
        for (SDWebImageDownloaderProgressBlock progressBlock in [self callbacksForKey:kProgressCallbackKey]) {
            progressBlock(0, expected, self.request.URL);
        }
    } else {
        // wwt 不要调用[self.dataTask cancel]可能弄乱URLSession的生命周期
        // Status code invalid and marked as cancelled. Do not call `[self.dataTask cancel]` which may mass up URLSession life cycle
        disposition = NSURLSessionResponseCancel;
    }
    
    // wwt 发送接收到反馈的通知
    __weak typeof(self) weakSelf = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        [[NSNotificationCenter defaultCenter] postNotificationName:SDWebImageDownloadReceiveResponseNotification object:weakSelf];
    });
    
    // wwt 执行状态block
    if (completionHandler) {
        completionHandler(disposition);
    }
}

// wwt 接收到数据
- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveData:(NSData *)data {
    
    // wwt 存储收到的data
    if (!self.imageData) {
        self.imageData = [[NSMutableData alloc] initWithCapacity:self.expectedSize];
    }
    [self.imageData appendData:data];
    
    // wwt 如果是逐步下载模式
    if ((self.options & SDWebImageDownloaderProgressiveDownload) && self.expectedSize > 0) {
        // wwt 获取一份imageData的copy
        // Get the image data
        __block NSData *imageData = [self.imageData copy];
        // wwt imageData的大小
        // Get the total bytes downloaded
        const NSInteger totalSize = imageData.length;
        // wwt 判断是否已经下载完成
        // Get the finish status
        BOOL finished = (totalSize >= self.expectedSize);
        
        // wwt 如果没有解码器初始化解码器
        if (!self.progressiveCoder) {
            // We need to create a new instance for progressive decoding to avoid conflicts
            for (id<SDWebImageCoder>coder in [SDWebImageCodersManager sharedInstance].coders) {
                if ([coder conformsToProtocol:@protocol(SDWebImageProgressiveCoder)] &&
                    [((id<SDWebImageProgressiveCoder>)coder) canIncrementallyDecodeFromData:imageData]) {
                    self.progressiveCoder = [[[coder class] alloc] init];
                    break;
                }
            }
        }
        
        // wwt 在解码队列中逐步解码图片
        // progressive decode the image in coder queue
        dispatch_async(self.coderQueue, ^{
            UIImage *image = [self.progressiveCoder incrementallyDecodedImageWithData:imageData finished:finished];
            if (image) {
                // wwt 获取缓存关键字
                NSString *key = [[SDWebImageManager sharedManager] cacheKeyForURL:self.request.URL];
                // wwt 根据关键字缩放图片
                image = [self scaledImageForKey:key image:image];
                // wwt 如果需要解压缩图片，对图片进行解压缩
                if (self.shouldDecompressImages) {
                    image = [[SDWebImageCodersManager sharedInstance] decompressedImageWithImage:image data:&imageData options:@{SDWebImageCoderScaleDownLargeImagesKey: @(NO)}];
                }
                
                // wwt 不保存逐步解码的图片即使已经完成了
                // We do not keep the progressive decoding image even when `finished`=YES. Because they are for view rendering but not take full function from downloader options. And some coders implementation may not keep consistent between progressive decoding and normal decoding.
                // wwt 执行完成block，用来逐步更新试图
                [self callCompletionBlocksWithImage:image imageData:nil error:nil finished:NO];
            }
        });
    }
    
    // wwt 回调进度block
    for (SDWebImageDownloaderProgressBlock progressBlock in [self callbacksForKey:kProgressCallbackKey]) {
        progressBlock(self.imageData.length, self.expectedSize, self.request.URL);
    }
}

// wwt 是否使用NSURL缓存
- (void)URLSession:(NSURLSession *)session
          dataTask:(NSURLSessionDataTask *)dataTask
 willCacheResponse:(NSCachedURLResponse *)proposedResponse
 completionHandler:(void (^)(NSCachedURLResponse *cachedResponse))completionHandler {
    
    NSCachedURLResponse *cachedResponse = proposedResponse;

    if (!(self.options & SDWebImageDownloaderUseNSURLCache)) {
        // Prevents caching of responses
        cachedResponse = nil;
    }
    if (completionHandler) {
        completionHandler(cachedResponse);
    }
}

#pragma mark NSURLSessionTaskDelegate

// wwt 任务完成代理
- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error {
    // wwt 线程安全，在主线程发送停止和完成通知
    @synchronized(self) {
        self.dataTask = nil;
        __weak typeof(self) weakSelf = self;
        dispatch_async(dispatch_get_main_queue(), ^{
            [[NSNotificationCenter defaultCenter] postNotificationName:SDWebImageDownloadStopNotification object:weakSelf];
            if (!error) {
                [[NSNotificationCenter defaultCenter] postNotificationName:SDWebImageDownloadFinishNotification object:weakSelf];
            }
        });
    }
    
    // wwt 进行完成回调
    // make sure to call `[self done]` to mark operation as finished
    if (error) {
        [self callCompletionBlocksWithError:error];
        [self done];
    } else {
        if ([self callbacksForKey:kCompletedCallbackKey].count > 0) {
            /**
             *  If you specified to use `NSURLCache`, then the response you get here is what you need.
             */
            __block NSData *imageData = [self.imageData copy];
            if (imageData) {
                /**
                 * wwt 处理从NSURLCache中获取数据的情况
                 * if you specified to only use cached data via `SDWebImageDownloaderIgnoreCachedResponse`,
                 *  then we should check if the cached data is equal to image data
                 */
                if (self.options & SDWebImageDownloaderIgnoreCachedResponse && [self.cachedData isEqualToData:imageData]) {
                    // call completion block with nil
                    [self callCompletionBlocksWithImage:nil imageData:nil error:nil finished:YES];
                    [self done];
                } else {
                    // wwt 对图像数据解码
                    // decode the image in coder queue
                    dispatch_async(self.coderQueue, ^{
                        UIImage *image = [[SDWebImageCodersManager sharedInstance] decodedImageWithData:imageData];
                        NSString *key = [[SDWebImageManager sharedManager] cacheKeyForURL:self.request.URL];
                        image = [self scaledImageForKey:key image:image];
                        
                        BOOL shouldDecode = YES;
                        
                        // wwt 不支持webP和动态图的解压缩
                        // Do not force decoding animated GIFs and WebPs
                        if (image.images) {
                            shouldDecode = NO;
                        } else {
#ifdef SD_WEBP
                            SDImageFormat imageFormat = [NSData sd_imageFormatForImageData:imageData];
                            if (imageFormat == SDImageFormatWebP) {
                                shouldDecode = NO;
                            }
#endif
                        }
                        
                        // wwt 解压缩
                        if (shouldDecode) {
                            if (self.shouldDecompressImages) {
                                BOOL shouldScaleDown = self.options & SDWebImageDownloaderScaleDownLargeImages;
                                image = [[SDWebImageCodersManager sharedInstance] decompressedImageWithImage:image data:&imageData options:@{SDWebImageCoderScaleDownLargeImagesKey: @(shouldScaleDown)}];
                            }
                        }
                        
                        // wwt 回调完成block
                        CGSize imageSize = image.size;
                        if (imageSize.width == 0 || imageSize.height == 0) {
                            [self callCompletionBlocksWithError:[NSError errorWithDomain:SDWebImageErrorDomain code:0 userInfo:@{NSLocalizedDescriptionKey : @"Downloaded image has 0 pixels"}]];
                        } else {
                            [self callCompletionBlocksWithImage:image imageData:imageData error:nil finished:YES];
                        }
                        [self done];
                    });
                }
            } else {
                [self callCompletionBlocksWithError:[NSError errorWithDomain:SDWebImageErrorDomain code:0 userInfo:@{NSLocalizedDescriptionKey : @"Image data is nil"}]];
                [self done];
            }
        } else {
            [self done];
        }
    }
}

// wwt 验证证书
- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didReceiveChallenge:(NSURLAuthenticationChallenge *)challenge completionHandler:(void (^)(NSURLSessionAuthChallengeDisposition disposition, NSURLCredential *credential))completionHandler {
    
    NSURLSessionAuthChallengeDisposition disposition = NSURLSessionAuthChallengePerformDefaultHandling;
    __block NSURLCredential *credential = nil;
    
    if ([challenge.protectionSpace.authenticationMethod isEqualToString:NSURLAuthenticationMethodServerTrust]) {
        if (!(self.options & SDWebImageDownloaderAllowInvalidSSLCertificates)) {
            disposition = NSURLSessionAuthChallengePerformDefaultHandling;
        } else {
            credential = [NSURLCredential credentialForTrust:challenge.protectionSpace.serverTrust];
            disposition = NSURLSessionAuthChallengeUseCredential;
        }
    } else {
        if (challenge.previousFailureCount == 0) {
            if (self.credential) {
                credential = self.credential;
                disposition = NSURLSessionAuthChallengeUseCredential;
            } else {
                disposition = NSURLSessionAuthChallengeCancelAuthenticationChallenge;
            }
        } else {
            disposition = NSURLSessionAuthChallengeCancelAuthenticationChallenge;
        }
    }
    
    if (completionHandler) {
        completionHandler(disposition, credential);
    }
}

#pragma mark Helper methods
// wwt 根据key缩放图像
- (nullable UIImage *)scaledImageForKey:(nullable NSString *)key image:(nullable UIImage *)image {
    return SDScaledImageForKey(key, image);
}
// wwt 判断是否支持后台下载
- (BOOL)shouldContinueWhenAppEntersBackground {
    return self.options & SDWebImageDownloaderContinueInBackground;
}
// wwt 执行完成block的回调
- (void)callCompletionBlocksWithError:(nullable NSError *)error {
    [self callCompletionBlocksWithImage:nil imageData:nil error:error finished:YES];
}

- (void)callCompletionBlocksWithImage:(nullable UIImage *)image
                            imageData:(nullable NSData *)imageData
                                error:(nullable NSError *)error
                             finished:(BOOL)finished {
    NSArray<id> *completionBlocks = [self callbacksForKey:kCompletedCallbackKey];
    dispatch_main_async_safe(^{
        for (SDWebImageDownloaderCompletedBlock completedBlock in completionBlocks) {
            completedBlock(image, imageData, error, finished);
        }
    });
}

@end
