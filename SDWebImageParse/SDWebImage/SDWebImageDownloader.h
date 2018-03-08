/*
 * This file is part of the SDWebImage package.
 * (c) Olivier Poitrey <rs@dailymotion.com>
 *
 * For the full copyright and license information, please view the LICENSE
 * file that was distributed with this source code.
 */

#import <Foundation/Foundation.h>
#import "SDWebImageCompat.h"
#import "SDWebImageOperation.h"

typedef NS_OPTIONS(NSUInteger, SDWebImageDownloaderOptions) {
    SDWebImageDownloaderLowPriority = 1 << 0,
    SDWebImageDownloaderProgressiveDownload = 1 << 1,

    /**
     * wwt 默认情况下请求不使用NSURLCache，设置成这个标识后会和默认策略一起使用
     * By default, request prevent the use of NSURLCache. With this flag, NSURLCache
     * is used with default policies.
     */
    SDWebImageDownloaderUseNSURLCache = 1 << 2,

    /**
     * wwt 如果图片数据是在NSURLCache在完成Block中回调图像数据（可能是nil），这个标识需要和SDWebImageDownloaderUseNSURLCache组合使用
     * Call completion block with nil image/imageData if the image was read from NSURLCache
     * (to be combined with `SDWebImageDownloaderUseNSURLCache`).
     */
    SDWebImageDownloaderIgnoreCachedResponse = 1 << 3,
    
    /**
     * wwt 在iOS 4.0+，当app进入后台后能够实现继续下载。这是通过向系统请求额外的后台运行时间用来完成这个请求实现的，如果后台任务到期了，后台任务将会被取消
     * In iOS 4+, continue the download of the image if the app goes to background. This is achieved by asking the system for
     * extra time in background to let the request finish. If the background task expires the operation will be cancelled.
     */
    SDWebImageDownloaderContinueInBackground = 1 << 4,

    /**
     * wwt 通过设置NSMutableURLRequest.HTTPShouldHandleCookies=YES，来管理保存在NSHTTPCookieStore中的cookies
     * Handles cookies stored in NSHTTPCookieStore by setting 
     * NSMutableURLRequest.HTTPShouldHandleCookies = YES;
     */
    SDWebImageDownloaderHandleCookies = 1 << 5,

    /**
     * wwt 启用以允许不被信任的SSL证书。一般情况下用来测试，生产中谨慎使用
     * Enable to allow untrusted SSL certificates.
     * Useful for testing purposes. Use with caution in production.
     */
    SDWebImageDownloaderAllowInvalidSSLCertificates = 1 << 6,

    /**
     * wwt 将图像置于高优先级队列中
     * Put the image in the high priority queue.
     */
    SDWebImageDownloaderHighPriority = 1 << 7,
    
    /**
     * wwt 压缩大图
     * Scale down the image
     */
    SDWebImageDownloaderScaleDownLargeImages = 1 << 8,
};

// wwt 图片下载执行顺序
typedef NS_ENUM(NSInteger, SDWebImageDownloaderExecutionOrder) {
    /**
     * wwt 默认先进先出
     * Default value. All download operations will execute in queue style (first-in-first-out).
     */
    SDWebImageDownloaderFIFOExecutionOrder,

    /**
     * wwt 后进先出
     * All download operations will execute in stack style (last-in-first-out).
     */
    SDWebImageDownloaderLIFOExecutionOrder
};

// wwt 开始下载的通知
FOUNDATION_EXPORT NSString * _Nonnull const SDWebImageDownloadStartNotification;
// wwt 下载停止的通知
FOUNDATION_EXPORT NSString * _Nonnull const SDWebImageDownloadStopNotification;

// wwt 下载进度的回调block
typedef void(^SDWebImageDownloaderProgressBlock)(NSInteger receivedSize, NSInteger expectedSize, NSURL * _Nullable targetURL);

// wwt 下载完成的回调block
typedef void(^SDWebImageDownloaderCompletedBlock)(UIImage * _Nullable image, NSData * _Nullable data, NSError * _Nullable error, BOOL finished);

// wwt http头的字典
typedef NSDictionary<NSString *, NSString *> SDHTTPHeadersDictionary;
typedef NSMutableDictionary<NSString *, NSString *> SDHTTPHeadersMutableDictionary;


typedef SDHTTPHeadersDictionary * _Nullable (^SDWebImageDownloaderHeadersFilterBlock)(NSURL * _Nullable url, SDHTTPHeadersDictionary * _Nullable headers);

/**
 *  A token associated with each download. Can be used to cancel a download
 */
@interface SDWebImageDownloadToken : NSObject <SDWebImageOperation>

/**
 wwt 下载的URL，不要修改
 The download's URL. This should be readonly and you should not modify
 */
@property (nonatomic, strong, nullable) NSURL *url;
/**
 wwt 取消的token，调用addHandlersForProgress:completed返回的字典，字典里面是回调block，可以根据token取消下载
 The cancel token taken from `addHandlersForProgress:completed`. This should be readonly and you should not modify
 @note use `-[SDWebImageDownloadToken cancel]` to cancel the token
 */
@property (nonatomic, strong, nullable) id downloadOperationCancelToken;

@end


/**
 * Asynchronous downloader dedicated and optimized for image loading.
 */
@interface SDWebImageDownloader : NSObject

/**
 * wwt 是否应该解压图片，解压图片占用内存多，但是性能好，默认解压，但是如果收到内存警告的情况下设置为NO，节省内存
 * Decompressing images that are downloaded and cached can improve performance but can consume lot of memory.
 * Defaults to YES. Set this to NO if you are experiencing a crash due to excessive memory consumption.
 */
@property (assign, nonatomic) BOOL shouldDecompressImages;

/**
 * wwt 最大并发下载
 *  The maximum number of concurrent downloads
 */
@property (assign, nonatomic) NSInteger maxConcurrentDownloads;

/**
 * wwt 当前下载的数量
 * Shows the current amount of downloads that still need to be downloaded
 */
@property (readonly, nonatomic) NSUInteger currentDownloadCount;

/**
 *  wwt 下载超时时间，默认15.0
 *  The timeout value (in seconds) for the download operation. Default: 15.0.
 */
@property (assign, nonatomic) NSTimeInterval downloadTimeout;

/**
 * 内部URLSession使用的配置
 * The configuration in use by the internal NSURLSession.
 * Mutating this object directly has no effect.
 *
 * @see createNewSessionWithConfiguration:
 */
@property (readonly, nonatomic, nonnull) NSURLSessionConfiguration *sessionConfiguration;


/**
 * wwt 下载操作的执行顺序，默认先进先出，也可后进先出
 * Changes download operations execution order. Default value is `SDWebImageDownloaderFIFOExecutionOrder`.
 */
@property (assign, nonatomic) SDWebImageDownloaderExecutionOrder executionOrder;

/**
 *  wwt 单例
 *  Singleton method, returns the shared instance
 *
 *  @return global shared instance of downloader class
 */
+ (nonnull instancetype)sharedDownloader;

/**
 *  wwt 设置请求的证书
 *  Set the default URL credential to be set for request operations.
 */
@property (strong, nonatomic, nullable) NSURLCredential *urlCredential;

/**
 * wwt 设置用户名
 * Set username
 */
@property (strong, nonatomic, nullable) NSString *username;

/**
 * wwt 设置密码
 * Set password
 */
@property (strong, nonatomic, nullable) NSString *password;

/**
 * wwt 设置http请求头的block，每次请求之前会调用这个block
 * Set filter to pick headers for downloading image HTTP request.
 *
 * This block will be invoked for each downloading image request, returned
 * NSDictionary will be used as headers in corresponding HTTP request.
 */
@property (nonatomic, copy, nullable) SDWebImageDownloaderHeadersFilterBlock headersFilter;

/**
 * wwt 初始化方法
 * Creates an instance of a downloader with specified session configuration.
 * @note `timeoutIntervalForRequest` is going to be overwritten.
 * @return new instance of downloader class
 */
- (nonnull instancetype)initWithSessionConfiguration:(nullable NSURLSessionConfiguration *)sessionConfiguration NS_DESIGNATED_INITIALIZER;

/**
 * wwt 为每一个下载请求添加一个httpheader的值
 * Set a value for a HTTP header to be appended to each download HTTP request.
 *
 * @param value The value for the header field. Use `nil` value to remove the header.
 * @param field The name of the header field to set.
 */
- (void)setValue:(nullable NSString *)value forHTTPHeaderField:(nullable NSString *)field;

/**
 * wwt 返回指定的http标头字段的值
 * Returns the value of the specified HTTP header field.
 *
 * @return The value associated with the header field field, or `nil` if there is no corresponding header field.
 */
- (nullable NSString *)valueForHTTPHeaderField:(nullable NSString *)field;

/**
 * wwt 设置下载的operration类，这个类必须是NSOperation的子类而且要实现SDWebImageDownloaderOperationInterface协议
 * Sets a subclass of `SDWebImageDownloaderOperation` as the default
 * `NSOperation` to be used each time SDWebImage constructs a request
 * operation to download an image.
 *
 * @param operationClass The subclass of `SDWebImageDownloaderOperation` to set 
 *        as default. Passing `nil` will revert to `SDWebImageDownloaderOperation`.
 */
- (void)setOperationClass:(nullable Class)operationClass;

/**
 * wwt 根据给定的URL下载图片
 * Creates a SDWebImageDownloader async downloader instance with a given URL
 *
 * The delegate will be informed when the image is finish downloaded or an error has happen.
 *
 * @see SDWebImageDownloaderDelegate
 *
 * @param url            The URL to the image to download
 * @param options        The options to be used for this download
 * @param progressBlock  A block called repeatedly while the image is downloading
 *                       @note the progress block is executed on a background queue
 * @param completedBlock A block called once the download is completed.
 *                       If the download succeeded, the image parameter is set, in case of error,
 *                       error parameter is set with the error. The last parameter is always YES
 *                       if SDWebImageDownloaderProgressiveDownload isn't use. With the
 *                       SDWebImageDownloaderProgressiveDownload option, this block is called
 *                       repeatedly with the partial image object and the finished argument set to NO
 *                       before to be called a last time with the full image and finished argument
 *                       set to YES. In case of error, the finished argument is always YES.
 *
 * @return A token (SDWebImageDownloadToken) that can be passed to -cancel: to cancel this operation
 */
- (nullable SDWebImageDownloadToken *)downloadImageWithURL:(nullable NSURL *)url
                                                   options:(SDWebImageDownloaderOptions)options
                                                  progress:(nullable SDWebImageDownloaderProgressBlock)progressBlock
                                                 completed:(nullable SDWebImageDownloaderCompletedBlock)completedBlock;

/**
 * wwt 根据token取消下载
 * Cancels a download that was previously queued using -downloadImageWithURL:options:progress:completed:
 *
 * @param token The token received from -downloadImageWithURL:options:progress:completed: that should be canceled.
 */
- (void)cancel:(nullable SDWebImageDownloadToken *)token;

/**
 * wwt 设置下载队列暂停状态
 * Sets the download queue suspension state
 */
- (void)setSuspended:(BOOL)suspended;

/**
 * wwt 取消所有正在进行的下载
 * Cancels all download operations in the queue
 */
- (void)cancelAllDownloads;

/**
 * wwt 强制让SDWebImageDownloader使用一个新的根据sessionConfiguration初始化的session。需要注意的是如果使用了这个方法会取消在下载队列的所有任务，超时时间也会被重置
 * Forces SDWebImageDownloader to create and use a new NSURLSession that is
 * initialized with the given configuration.
 * @note All existing download operations in the queue will be cancelled.
 * @note `timeoutIntervalForRequest` is going to be overwritten.
 *
 * @param sessionConfiguration The configuration to use for the new NSURLSession
 */
- (void)createNewSessionWithConfiguration:(nonnull NSURLSessionConfiguration *)sessionConfiguration;

/**
 * 是托管的session无效，可以选择性的刮起操作
 * Invalidates the managed session, optionally canceling pending operations.
 * @note If you use custom downloader instead of the shared downloader, you need call this method when you do not use it to avoid memory leak
 * @param cancelPendingOperations Whether or not to cancel pending operations.
 * @note Calling this method on the shared downloader has no effect.
 */
- (void)invalidateSessionAndCancel:(BOOL)cancelPendingOperations;

@end
