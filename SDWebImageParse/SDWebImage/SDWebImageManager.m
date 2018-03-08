/*
 * This file is part of the SDWebImage package.
 * (c) Olivier Poitrey <rs@dailymotion.com>
 *
 * For the full copyright and license information, please view the LICENSE
 * file that was distributed with this source code.
 */

#import "SDWebImageManager.h"
#import "NSImage+WebCache.h"
#import <objc/message.h>

@interface SDWebImageCombinedOperation : NSObject <SDWebImageOperation>

// wwt 是否已经取消
@property (assign, nonatomic, getter = isCancelled) BOOL cancelled;
// wwt 下载的token
@property (strong, nonatomic, nullable) SDWebImageDownloadToken *downloadToken;
// wwt 缓存op
@property (strong, nonatomic, nullable) NSOperation *cacheOperation;
// wwt 这个保存的是执行下载的manager，因为可能使用的不是单例
@property (weak, nonatomic, nullable) SDWebImageManager *manager;

@end

@interface SDWebImageManager ()

// wwt 缓存器
@property (strong, nonatomic, readwrite, nonnull) SDImageCache *imageCache;
// wwt 下载器
@property (strong, nonatomic, readwrite, nonnull) SDWebImageDownloader *imageDownloader;

// wwt 失败的URL，SD默认设置失败的URL不再下载
@property (strong, nonatomic, nonnull) NSMutableSet<NSURL *> *failedURLs;

// wwt 正在运行的op
@property (strong, nonatomic, nonnull) NSMutableArray<SDWebImageCombinedOperation *> *runningOperations;

@end

@implementation SDWebImageManager

+ (nonnull instancetype)sharedManager {
    static dispatch_once_t once;
    static id instance;
    dispatch_once(&once, ^{
        instance = [self new];
    });
    return instance;
}

// wwt 初始化
- (nonnull instancetype)init {
    SDImageCache *cache = [SDImageCache sharedImageCache];
    SDWebImageDownloader *downloader = [SDWebImageDownloader sharedDownloader];
    return [self initWithCache:cache downloader:downloader];
}

- (nonnull instancetype)initWithCache:(nonnull SDImageCache *)cache downloader:(nonnull SDWebImageDownloader *)downloader {
    if ((self = [super init])) {
        _imageCache = cache;
        _imageDownloader = downloader;
        _failedURLs = [NSMutableSet new];
        _runningOperations = [NSMutableArray new];
    }
    return self;
}

// wwt 根据URL获取缓存图片的key
- (nullable NSString *)cacheKeyForURL:(nullable NSURL *)url {
    if (!url) {
        return @"";
    }

    if (self.cacheKeyFilter) {
        return self.cacheKeyFilter(url);
    } else {
        return url.absoluteString;
    }
}

// wwt 根据key缩放图片@1x,@2x,@3x
- (nullable UIImage *)scaledImageForKey:(nullable NSString *)key image:(nullable UIImage *)image {
    return SDScaledImageForKey(key, image);
}

// wwt 根据URL判断图片是否已经缓存了
- (void)cachedImageExistsForURL:(nullable NSURL *)url
                     completion:(nullable SDWebImageCheckCacheCompletionBlock)completionBlock {
    // wwt 获取缓存的key
    NSString *key = [self cacheKeyForURL:url];
    
    // wwt 验证是否已经在内存中缓存了，如果内存已经缓存了直接完成，如果没有缓存查询硬盘
    BOOL isInMemoryCache = ([self.imageCache imageFromMemoryCacheForKey:key] != nil);
    
    if (isInMemoryCache) {
        // making sure we call the completion block on the main queue
        dispatch_async(dispatch_get_main_queue(), ^{
            if (completionBlock) {
                completionBlock(YES);
            }
        });
        return;
    }
    
    [self.imageCache diskImageExistsWithKey:key completion:^(BOOL isInDiskCache) {
        // the completion block of checkDiskCacheForImageWithKey:completion: is always called on the main queue, no need to further dispatch
        if (completionBlock) {
            completionBlock(isInDiskCache);
        }
    }];
}

// wwt 验证图片是否有硬盘缓存
- (void)diskImageExistsForURL:(nullable NSURL *)url
                   completion:(nullable SDWebImageCheckCacheCompletionBlock)completionBlock {
    NSString *key = [self cacheKeyForURL:url];
    
    [self.imageCache diskImageExistsWithKey:key completion:^(BOOL isInDiskCache) {
        // the completion block of checkDiskCacheForImageWithKey:completion: is always called on the main queue, no need to further dispatch
        if (completionBlock) {
            completionBlock(isInDiskCache);
        }
    }];
}

// wwt 加载图片
- (id <SDWebImageOperation>)loadImageWithURL:(nullable NSURL *)url
                                     options:(SDWebImageOptions)options
                                    progress:(nullable SDWebImageDownloaderProgressBlock)progressBlock
                                   completed:(nullable SDInternalCompletionBlock)completedBlock {
    // wwt 不设置完成block调用这个方法没有意义
    // Invoking this method without a completedBlock is pointless
    NSAssert(completedBlock != nil, @"If you mean to prefetch the image, use -[SDWebImagePrefetcher prefetchURLs] instead");
    
    // wwt 处理url传入的不是URL对象而是字符串路径的情况
    // Very common mistake is to send the URL using NSString object instead of NSURL. For some strange reason, Xcode won't
    // throw any warning for this type mismatch. Here we failsafe this error by allowing URLs to be passed as NSString.
    if ([url isKindOfClass:NSString.class]) {
        url = [NSURL URLWithString:(NSString *)url];
    }
    
    // wwt 防止url传入的是NSNULL，避免引起崩溃
    // Prevents app crashing on argument type error like sending NSNull instead of NSURL
    if (![url isKindOfClass:NSURL.class]) {
        url = nil;
    }
    
    // wwt op的组合对象，记录manger，cancelled，token等信息
    SDWebImageCombinedOperation *operation = [SDWebImageCombinedOperation new];
    operation.manager = self;

    // wwt 判断是不是下载失败的URL
    BOOL isFailedUrl = NO;
    if (url) {
        @synchronized (self.failedURLs) {
            isFailedUrl = [self.failedURLs containsObject:url];
        }
    }
    
    // wwt 处理曾经下载失败的URL是否重新下载的问题
    if (url.absoluteString.length == 0 || (!(options & SDWebImageRetryFailed) && isFailedUrl)) {
        [self callCompletionBlockForOperation:operation completion:completedBlock error:[NSError errorWithDomain:NSURLErrorDomain code:NSURLErrorFileDoesNotExist userInfo:nil] url:url];
        return operation;
    }
    
    // wwt 添加到正在运行的op数组
    @synchronized (self.runningOperations) {
        [self.runningOperations addObject:operation];
    }
    
    // wwt 获取缓存的URL的key
    NSString *key = [self cacheKeyForURL:url];
    
    SDImageCacheOptions cacheOptions = 0;
    // wwt 设置SDImageCacheOptions
    if (options & SDWebImageQueryDataWhenInMemory) cacheOptions |= SDImageCacheQueryDataWhenInMemory;
    if (options & SDWebImageQueryDiskSync) cacheOptions |= SDImageCacheQueryDiskSync;
    
    // wwt 防止循环引用
    __weak SDWebImageCombinedOperation *weakOperation = operation;
    
    // wwt 根据key从缓存中查找图片
    operation.cacheOperation = [self.imageCache queryCacheOperationForKey:key options:cacheOptions done:^(UIImage *cachedImage, NSData *cachedData, SDImageCacheType cacheType) {
        __strong __typeof(weakOperation) strongOperation = weakOperation;
        
        // wwt 如果没有找到op，或者op已经被取消了，将op从正在运行的数组中移除
        if (!strongOperation || strongOperation.isCancelled) {
            [self safelyRemoveOperationFromRunning:strongOperation];
            return;
        }
        
        // wwt 验证是否要从网络上下载图片，如果不是设置了只从缓存中加载图片，而且没有找到图片或者每次都刷新缓存，而且没有实现代理或者实现了代理且代理方法返回yes，才会从网络上下载
        // Check whether we should download image from network
        BOOL shouldDownload = (!(options & SDWebImageFromCacheOnly))
            && (!cachedImage || options & SDWebImageRefreshCached)
            && (![self.delegate respondsToSelector:@selector(imageManager:shouldDownloadImageForURL:)] || [self.delegate imageManager:self shouldDownloadImageForURL:url]);
        
        
        if (shouldDownload) {
            // wwt 如果图像从缓存中找到了，但是设置了SDWebImageRefreshCached标识，试着重新下载图像🤔️
            if (cachedImage && options & SDWebImageRefreshCached) {
                // If image was found in the cache but SDWebImageRefreshCached is provided, notify about the cached image
                // AND try to re-download it in order to let a chance to NSURLCache to refresh it from server.
                [self callCompletionBlockForOperation:strongOperation completion:completedBlock image:cachedImage data:cachedData error:nil cacheType:cacheType finished:YES url:url];
            }
            
            // wwt 同步一些下载选项
            // download if no image or requested to refresh anyway, and download allowed by delegate
            SDWebImageDownloaderOptions downloaderOptions = 0;
            if (options & SDWebImageLowPriority) downloaderOptions |= SDWebImageDownloaderLowPriority;
            if (options & SDWebImageProgressiveDownload) downloaderOptions |= SDWebImageDownloaderProgressiveDownload;
            if (options & SDWebImageRefreshCached) downloaderOptions |= SDWebImageDownloaderUseNSURLCache;
            if (options & SDWebImageContinueInBackground) downloaderOptions |= SDWebImageDownloaderContinueInBackground;
            if (options & SDWebImageHandleCookies) downloaderOptions |= SDWebImageDownloaderHandleCookies;
            if (options & SDWebImageAllowInvalidSSLCertificates) downloaderOptions |= SDWebImageDownloaderAllowInvalidSSLCertificates;
            if (options & SDWebImageHighPriority) downloaderOptions |= SDWebImageDownloaderHighPriority;
            if (options & SDWebImageScaleDownLargeImages) downloaderOptions |= SDWebImageDownloaderScaleDownLargeImages;
            
            if (cachedImage && options & SDWebImageRefreshCached) {
                // wwt 如果图像已经缓存了，但是仍要强制刷新，强制关闭逐行加载图片
                // force progressive off if image already cached but forced refreshing
                downloaderOptions &= ~SDWebImageDownloaderProgressiveDownload;
                // wwt 如果图像已经缓存但是仍要强制刷新刷新，忽略从NSURLCache中读取图像
                // ignore image read from NSURLCache if image if cached but force refreshing
                downloaderOptions |= SDWebImageDownloaderIgnoreCachedResponse;
            }
            
            // wwt 循环引用主要看有没有形成引用方向一致的闭合环，如果形成了就是循环引用。要想打破循环引用可以将其中的一个引用变为弱引用，或者找到一个第三者介入来拆开其中的一个引用。这里如果在completedblock中再引用combinedOp就会形成闭合环
            // `SDWebImageCombinedOperation` -> `SDWebImageDownloadToken` -> `downloadOperationCancelToken`, which is a `SDCallbacksDictionary` and retain the completed block bellow, so we need weak-strong again to avoid retain cycle
            __weak typeof(strongOperation) weakSubOperation = strongOperation;
            strongOperation.downloadToken = [self.imageDownloader downloadImageWithURL:url options:downloaderOptions progress:progressBlock completed:^(UIImage *downloadedImage, NSData *downloadedData, NSError *error, BOOL finished) {
                __strong typeof(weakSubOperation) strongSubOperation = weakSubOperation;
                
                // wwt 如果op被取消了或者被释放了什么都不做
                if (!strongSubOperation || strongSubOperation.isCancelled) {
                    // Do nothing if the operation was cancelled
                    // See #699 for more details
                    // if we would call the completedBlock, there could be a race condition between this block and another completedBlock for the same object, so if this one is called second, we will overwrite the new data
                    // wwt 如果我们在这里调用了完成block，这个完成block会和另一个完成block争夺同一个对象，所以如果这个完成block被后调用，我们会覆盖新的数据
                } else if (error) {
                    // wwt 如果出错了，如果不是因为网络原因，加入失败数组
                    // wwt 1.没有网络；2.取消了；3.超时了；4.请求国际漫游的数据，但是国际漫游被禁用；5.蜂窝网络不允许链接；6.无法解析主机名；7.链接主机失败；8.客户端或者服务器连接，在正在加载的过程中断开链接
                    [self callCompletionBlockForOperation:strongSubOperation completion:completedBlock error:error url:url];

                    if (   error.code != NSURLErrorNotConnectedToInternet
                        && error.code != NSURLErrorCancelled
                        && error.code != NSURLErrorTimedOut
                        && error.code != NSURLErrorInternationalRoamingOff
                        && error.code != NSURLErrorDataNotAllowed
                        && error.code != NSURLErrorCannotFindHost
                        && error.code != NSURLErrorCannotConnectToHost
                        && error.code != NSURLErrorNetworkConnectionLost) {
                        @synchronized (self.failedURLs) {
                            [self.failedURLs addObject:url];
                        }
                    }
                }
                else {
                    // wwt 如果设置了再次尝试下载以前失败的URL，则把URL从失败数组中移除
                    if ((options & SDWebImageRetryFailed)) {
                        @synchronized (self.failedURLs) {
                            [self.failedURLs removeObject:url];
                        }
                    }
                    
                    // wwt 是否缓存到磁盘
                    BOOL cacheOnDisk = !(options & SDWebImageCacheMemoryOnly);
                    
                    // wwt 我们已经在单例模式下的downloader对图像进行了缩放，如果不使用单例使用自定义的downloader，这里对图像进行缩放
                    // We've done the scale process in SDWebImageDownloader with the shared manager, this is used for custom manager and avoid extra scale.
                    if (self != [SDWebImageManager sharedManager] && self.cacheKeyFilter && downloadedImage) {
                        downloadedImage = [self scaledImageForKey:key image:downloadedImage];
                    }
                    
                    // wwt 如果需要刷新缓存，而且找到了缓存，而且没有下载成功
                    if (options & SDWebImageRefreshCached && cachedImage && !downloadedImage) {
                        // wwt 图片刷新遇到了NSURLCache的情况，不要回调完成block
                        // Image refresh hit the NSURLCache cache, do not call the completion block
                    }
                    
                    // wwt 如果图片下载成功了，而且不是动图或者设置了可以转换动图，而且设置了图像转换代理，则让代理执行转换操作，并将转换后的图像写入缓存，并执行完成block
                    else if (downloadedImage && (!downloadedImage.images || (options & SDWebImageTransformAnimatedImage)) && [self.delegate respondsToSelector:@selector(imageManager:transformDownloadedImage:withURL:)]) {
                        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
                            UIImage *transformedImage = [self.delegate imageManager:self transformDownloadedImage:downloadedImage withURL:url];

                            if (transformedImage && finished) {
                                BOOL imageWasTransformed = ![transformedImage isEqual:downloadedImage];
                                // pass nil if the image was transformed, so we can recalculate the data from the image
                                [self.imageCache storeImage:transformedImage imageData:(imageWasTransformed ? nil : downloadedData) forKey:key toDisk:cacheOnDisk completion:nil];
                            }
                            
                            [self callCompletionBlockForOperation:strongSubOperation completion:completedBlock image:transformedImage data:downloadedData error:nil cacheType:SDImageCacheTypeNone finished:finished url:url];
                        });
                    }
                    else {
                        // wwt 下载到了图片且完成了下载，则缓存图像
                        if (downloadedImage && finished) {
                            [self.imageCache storeImage:downloadedImage imageData:downloadedData forKey:key toDisk:cacheOnDisk completion:nil];
                        }
                        // wwt 执行完成block
                        [self callCompletionBlockForOperation:strongSubOperation completion:completedBlock image:downloadedImage data:downloadedData error:nil cacheType:SDImageCacheTypeNone finished:finished url:url];
                    }
                }
                
                // wwt 如果下载完成了，删除正在运行的op
                if (finished) {
                    [self safelyRemoveOperationFromRunning:strongSubOperation];
                }
            }];
        }
        // wwt 如果从缓存中查到了，执行完成block，并把op从正在运行的数组中删除
        else if (cachedImage) {
            [self callCompletionBlockForOperation:strongOperation completion:completedBlock image:cachedImage data:cachedData error:nil cacheType:cacheType finished:YES url:url];
            [self safelyRemoveOperationFromRunning:strongOperation];
        }
        
        // 如果缓存中没有，而且代理方法禁止了下载图片，执行完成block，并将op从在运行的数组中删除
        else {
            // Image not in cache and download disallowed by delegate
            [self callCompletionBlockForOperation:strongOperation completion:completedBlock image:nil data:nil error:nil cacheType:SDImageCacheTypeNone finished:YES url:url];
            [self safelyRemoveOperationFromRunning:strongOperation];
        }
    }];

    return operation;
}

// wwt 将图像根据url存入缓存
- (void)saveImageToCache:(nullable UIImage *)image forURL:(nullable NSURL *)url {
    if (image && url) {
        NSString *key = [self cacheKeyForURL:url];
        [self.imageCache storeImage:image forKey:key toDisk:YES completion:nil];
    }
}

// wwt 取消所有正在运行的op
- (void)cancelAll {
    @synchronized (self.runningOperations) {
        NSArray<SDWebImageCombinedOperation *> *copiedOperations = [self.runningOperations copy];
        [copiedOperations makeObjectsPerformSelector:@selector(cancel)];
        [self.runningOperations removeObjectsInArray:copiedOperations];
    }
}

// wwt 判断是否有正在下载的操作
- (BOOL)isRunning {
    BOOL isRunning = NO;
    @synchronized (self.runningOperations) {
        isRunning = (self.runningOperations.count > 0);
    }
    return isRunning;
}

// wwt 线程安全的从正在运行的数组中移除combineOp
- (void)safelyRemoveOperationFromRunning:(nullable SDWebImageCombinedOperation*)operation {
    @synchronized (self.runningOperations) {
        if (operation) {
            [self.runningOperations removeObject:operation];
        }
    }
}

// wwt 调用完成block
- (void)callCompletionBlockForOperation:(nullable SDWebImageCombinedOperation*)operation
                             completion:(nullable SDInternalCompletionBlock)completionBlock
                                  error:(nullable NSError *)error
                                    url:(nullable NSURL *)url {
    [self callCompletionBlockForOperation:operation completion:completionBlock image:nil data:nil error:error cacheType:SDImageCacheTypeNone finished:YES url:url];
}

// wwt 如果op没有被取消，在主队列中调用完成block
- (void)callCompletionBlockForOperation:(nullable SDWebImageCombinedOperation*)operation
                             completion:(nullable SDInternalCompletionBlock)completionBlock
                                  image:(nullable UIImage *)image
                                   data:(nullable NSData *)data
                                  error:(nullable NSError *)error
                              cacheType:(SDImageCacheType)cacheType
                               finished:(BOOL)finished
                                    url:(nullable NSURL *)url {
    dispatch_main_async_safe(^{
        if (operation && !operation.isCancelled && completionBlock) {
            completionBlock(image, data, error, cacheType, finished, url);
        }
    });
}

@end


@implementation SDWebImageCombinedOperation

// wwt 取消正在下载的op
- (void)cancel {
    @synchronized(self) {
        self.cancelled = YES;
        if (self.cacheOperation) {
            [self.cacheOperation cancel];
            self.cacheOperation = nil;
        }
        if (self.downloadToken) {
            [self.manager.imageDownloader cancel:self.downloadToken];
        }
        [self.manager safelyRemoveOperationFromRunning:self];
    }
}

@end
