/*
 * This file is part of the SDWebImage package.
 * (c) Olivier Poitrey <rs@dailymotion.com>
 *
 * For the full copyright and license information, please view the LICENSE
 * file that was distributed with this source code.
 */

#import <Foundation/Foundation.h>
#import "SDWebImageCompat.h"
#import "NSData+ImageContentType.h"

/**
 wwt 一个决定是否在解压缩的时候缩小大图的布尔值，这是一个字典的key
 
 A Boolean value indicating whether to scale down large images during decompressing. (NSNumber)
 */
FOUNDATION_EXPORT NSString * _Nonnull const SDWebImageCoderScaleDownLargeImagesKey;

/**
 wwt 返回一个CGColorSpaceCreateDeviceRGB创建的共享设备颜色空间
 
 Return the shared device-dependent RGB color space created with CGColorSpaceCreateDeviceRGB.

 @return The device-dependent RGB color space
 */
CG_EXTERN CGColorSpaceRef _Nonnull SDCGColorSpaceGetDeviceRGB(void);

/**
 wwt 检测CGImageRef是否包含alpha（透明度）通道
 
 Check whether CGImageRef contains alpha channel.

 @param imageRef The CGImageRef
 @return Return YES if CGImageRef contains alpha channel, otherwise return NO
 */
CG_EXTERN BOOL SDCGImageRefContainsAlpha(_Nullable CGImageRef imageRef);


/**
 wwt 这是一个提供自定义图片加/解码的图片编码器协议，协议的这些方法都需要实现，需要注意的是，这些方法都不是在主线程回调
 
 This is the image coder protocol to provide custom image decoding/encoding.
 These methods are all required to implement.
 @note Pay attention that these methods are not called from main queue.
 */
@protocol SDWebImageCoder <NSObject>

@required
#pragma mark - Decoding
/**
 wwt 如果这个编码器能够解析某些数据返回YES，如果不能，数据需要传递给其他编码器
 
 Returns YES if this coder can decode some data. Otherwise, the data should be passed to another coder.
 
 @param data The image data so we can look at it
 @return YES if this coder can decode the data, NO otherwise
 */
- (BOOL)canDecodeFromData:(nullable NSData *)data;

/**
 wwt 将图片数据解码为图片
 
 Decode the image data to image.

 @param data The image data to be decoded
 @return The decoded image from data
 */
- (nullable UIImage *)decodedImageWithData:(nullable NSData *)data;

/**
 
 wwt 使用原始图片和图片数据解压图片，image：要解压缩的图片对象；data：原始图片数据；optionsDict：解压的设置，比如可以设置是否将大图缩放了
 
 Decompress the image with original image and image data.

 @param image The original image to be decompressed
 @param data The pointer to original image data. The pointer itself is nonnull but image data can be null. This data will set to cache if needed. If you do not need to modify data at the sametime, ignore this param.
 @param optionsDict A dictionary containing any decompressing options. Pass {SDWebImageCoderScaleDownLargeImagesKey: @(YES)} to scale down large images
 @return The decompressed image
 */
- (nullable UIImage *)decompressedImageWithImage:(nullable UIImage *)image
                                            data:(NSData * _Nullable * _Nonnull)data
                                         options:(nullable NSDictionary<NSString*, NSObject*>*)optionsDict;

#pragma mark - Encoding

/**
 wwt 如果编码器能够编码某些图片返回YES
 
 Returns YES if this coder can encode some image. Otherwise, it should be passed to another coder.
 
 @param format The image format
 @return YES if this coder can encode the image, NO otherwise
 */
- (BOOL)canEncodeToFormat:(SDImageFormat)format;

/**
 wwt 将图片编码为图片数据 image：要编码的图片；format：编码的格式（SDImageFormatUndefined）也是可以编码的
 
 Encode the image to image data.

 @param image The image to be encoded
 @param format The image format to encode, you should note `SDImageFormatUndefined` format is also  possible
 @return The encoded image data
 */
- (nullable NSData *)encodedDataWithImage:(nullable UIImage *)image format:(SDImageFormat)format;

@end


/**
 wwt 这个图片编码协议提供了定制的逐行图像解码
 
 This is the image coder protocol to provide custom progressive image decoding.
 These methods are all required to implement.
 @note Pay attention that these methods are not called from main queue.
 */
@protocol SDWebImageProgressiveCoder <SDWebImageCoder>

@required
/**
 wwt 如果解码器可以递增的解码某些数据返回YES
 
 Returns YES if this coder can incremental decode some data. Otherwise, it should be passed to another coder.
 
 @param data The image data so we can look at it
 @return YES if this coder can decode the data, NO otherwise
 */
- (BOOL)canIncrementallyDecodeFromData:(nullable NSData *)data;

/**
 wwt 逐步将图像数据解码成图像 data：当前已经下载的数据；finished：下载是否完成。需要注意的是因为需要保持解码的上下文，会为每个下载操作分配一个同类型的新实例对象来避免冲突
 
 Incremental decode the image data to image.
 
 @param data The image data has been downloaded so far
 @param finished Whether the download has finished
 @warning because incremental decoding need to keep the decoded context, we will alloc a new instance with the same class for each download operation to avoid conflicts
 @return The decoded image from data
 */
- (nullable UIImage *)incrementallyDecodedImageWithData:(nullable NSData *)data finished:(BOOL)finished;

@end
