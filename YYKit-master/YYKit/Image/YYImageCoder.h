//
//  YYImageCoder.h
//  YYKit <https://github.com/ibireme/YYKit>
//
//  Created by ibireme on 15/5/13.
//  Copyright (c) 2015 ibireme.
//
//  This source code is licensed under the MIT-style license found in the
//  LICENSE file in the root directory of this source tree.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

/**
 图片消息的类型
 Image file type.
 */
typedef NS_ENUM(NSUInteger, YYImageType) {
    YYImageTypeUnknown = 0, ///< unknown
    YYImageTypeJPEG,        ///< jpeg, jpg
    YYImageTypeJPEG2000,    ///< jp2
    YYImageTypeTIFF,        ///< tiff, tif
    YYImageTypeBMP,         ///< bmp
    YYImageTypeICO,         ///< ico
    YYImageTypeICNS,        ///< icns
    YYImageTypeGIF,         ///< gif
    YYImageTypePNG,         ///< png
    YYImageTypeWebP,        ///< webp
    YYImageTypeOther,       ///< other image format
};


/**
 当下一帧被渲染到画布之前，当前帧使用的区域的对应处理方法
 Dispose method specifies how the area used by the current frame is to be treated
 before rendering the next frame on the canvas.
 */
typedef NS_ENUM(NSUInteger, YYImageDisposeMethod) {
    
    /**
     不处理保持原样
     No disposal is done on this frame before rendering the next; the contents
     of the canvas are left as is.
     */
    YYImageDisposeNone = 0,
    
    /**
     在渲染下一帧之前画布被处理成完全透明的黑色
     The frame's region of the canvas is to be cleared to fully transparent black
     before rendering the next frame.
     */
    YYImageDisposeBackground,
    
    /**
     在渲染下一帧以前框架的帧区域将会恢复为之前的内容
     The frame's region of the canvas is to be reverted to the previous contents
     before rendering the next frame.
     */
    YYImageDisposePrevious,
};

/**
 如何处理当前帧的透明像素和之前画布的头平像素的混合操作
 Blend operation specifies how transparent pixels of the current frame are
 blended with those of the previous canvas.
 */
typedef NS_ENUM(NSUInteger, YYImageBlendOperation) {
    
    /**
     帧的所有颜色分量（含alpha）都会覆盖当前帧画布区域的内容
     All color components of the frame, including alpha, overwrite the current
     contents of the frame's canvas region.
     */
    YYImageBlendNone = 0,
    
    /**
     这帧应该给予alpha合成输出到缓冲区
     The frame should be composited onto the output buffer based on its alpha.
     */
    YYImageBlendOver,
};

/**
 图像帧对象
 An image frame object.
 */
@interface YYImageFrame : NSObject <NSCopying>
// 帧索引从0开始
@property (nonatomic) NSUInteger index;    ///< Frame index (zero based)
// 帧宽度
@property (nonatomic) NSUInteger width;    ///< Frame width
// 帧高度
@property (nonatomic) NSUInteger height;   ///< Frame height
// x方向偏移量，@note 左下
@property (nonatomic) NSUInteger offsetX;  ///< Frame origin.x in canvas (left-bottom based)
// y方向偏移量
@property (nonatomic) NSUInteger offsetY;  ///< Frame origin.y in canvas (left-bottom based)
// 帧持续时间，单位s
@property (nonatomic) NSTimeInterval duration;          ///< Frame duration in seconds
// 渲染下一帧的时候，如何处理当前帧
@property (nonatomic) YYImageDisposeMethod dispose;     ///< Frame dispose method.
// 帧的混合方法
@property (nonatomic) YYImageBlendOperation blend;      ///< Frame blend operation.
// 图片的cocoa对象
@property (nullable, nonatomic, strong) UIImage *image; ///< The image.
// 类的方法，根据UIImage对象生成YYImageFrame对象
+ (instancetype)frameWithImage:(UIImage *)image;
@end


#pragma mark - Decoder

/**
 An image decoder to decode image data.
 
 @discussion This class supports decoding animated WebP, APNG, GIF and system
 image format such as PNG, JPG, JP2, BMP, TIFF, PIC, ICNS and ICO. It can be used 
 to decode complete image data, or to decode incremental image data during image 
 download. This class is thread-safe.
 
 @note 这个类支持解压动画的WebP, APNG, GIF,PNG,JPG,JP2,BMP,TIFF,PIC,ICNS,ICO格式的图片，同时可以用来解压完整的图片数据和图片下载过程中渐增的图片数据。这个类是线程安全的
 
 Example:
 
    // Decode single image:
    NSData *data = [NSData dataWithContentOfFile:@"/tmp/image.webp"];
    YYImageDecoder *decoder = [YYImageDecoder decoderWithData:data scale:2.0];
    UIImage image = [decoder frameAtIndex:0 decodeForDisplay:YES].image;
 
    // Decode image during download:
    NSMutableData *data = [NSMutableData new];
    YYImageDecoder *decoder = [[YYImageDecoder alloc] initWithScale:2.0];
    while(newDataArrived) {
        [data appendData:newData];
        [decoder updateData:data final:NO];
        if (decoder.frameCount > 0) {
            UIImage image = [decoder frameAtIndex:0 decodeForDisplay:YES].image;
            // progressive display...
        }
    }
    [decoder updateData:data final:YES];
    UIImage image = [decoder frameAtIndex:0 decodeForDisplay:YES].image;
    // final display...
 
 */
@interface YYImageDecoder : NSObject
// 要解压的图片数据
@property (nullable, nonatomic, readonly) NSData *data;    ///< Image data.
// imageData的图片类型
@property (nonatomic, readonly) YYImageType type;          ///< Image data type.
// 图片的缩放比例
@property (nonatomic, readonly) CGFloat scale;             ///< Image scale.
// 帧数
@property (nonatomic, readonly) NSUInteger frameCount;     ///< Image frame count.
// 图片循环次数，0代表无穷大
@property (nonatomic, readonly) NSUInteger loopCount;      ///< Image loop count, 0 means infinite.
// 图片画布大小
@property (nonatomic, readonly) NSUInteger width;          ///< Image canvas width.
@property (nonatomic, readonly) NSUInteger height;         ///< Image canvas height.
// 是否完成
@property (nonatomic, readonly, getter=isFinalized) BOOL finalized;

/**
 Creates an image decoder.
 
 @param scale  Image's scale.
 @return An image decoder.
 
 根据比例生成解码器
 */
- (instancetype)initWithScale:(CGFloat)scale NS_DESIGNATED_INITIALIZER;

/**
 Updates the incremental image with new data.
 
 @discussion You can use this method to decode progressive/interlaced/baseline
 image when you do not have the complete image data. The `data` was retained by
 decoder, you should not modify the data in other thread during decoding.
 
 @param data  The data to add to the image decoder. Each time you call this 
 function, the 'data' parameter must contain all of the image file data 
 accumulated so far.
 
 @param final  A value that specifies whether the data is the final set. 
 Pass YES if it is, NO otherwise. When the data is already finalized, you can
 not update the data anymore.
 
 @return Whether succeed.
 
 @note 根据新数据更新渐进的图片；可以使用这个方法处理渐进/隔行扫描/基线或者没有完整图像数据的图片；解码器保留了data数据，在解码过程中你不能在其他线程解码修改数据
 */
- (BOOL)updateData:(nullable NSData *)data final:(BOOL)final;

/**
 Convenience method to create a decoder with specified data.
 @param data  Image data.
 @param scale Image's scale.
 @return A new decoder, or nil if an error occurs.
 
 @note 一个便利的方式直接使用data生成解码器
 */
+ (nullable instancetype)decoderWithData:(NSData *)data scale:(CGFloat)scale;

/**
 Decodes and returns a frame from a specified index.
 @param index  Frame image index (zero-based).
 @param decodeForDisplay Whether decode the image to memory bitmap for display.
    If NO, it will try to returns the original frame data without blend.
 @return A new frame with image, or nil if an error occurs.
 
 @note 解码并返回指定索引的帧;decodeForDisplay决定是否解码成bitmap，如果是NO会尝试返回没有经过混合的原始帧数据
 */
- (nullable YYImageFrame *)frameAtIndex:(NSUInteger)index decodeForDisplay:(BOOL)decodeForDisplay;

/**
 Returns the frame duration from a specified index.
 @param index  Frame image (zero-based).
 @return Duration in seconds.
 
 @note 返回指定帧的持续时间
 */
- (NSTimeInterval)frameDurationAtIndex:(NSUInteger)index;

/**
 Returns the frame's properties. See "CGImageProperties.h" in ImageIO.framework
 for more information.
 
 @param index  Frame image index (zero-based).
 @return The ImageIO frame property.
 
 @note 返回帧的属性字典
 */
- (nullable NSDictionary *)framePropertiesAtIndex:(NSUInteger)index;

/**
 Returns the image's properties. See "CGImageProperties.h" in ImageIO.framework
 for more information.
 
 @note 返回帧的属性字典
 */
- (nullable NSDictionary *)imageProperties;

@end



#pragma mark - Encoder

/**
 An image encoder to encode image to data.
 
 @discussion It supports encoding single frame image with the type defined in YYImageType.
 It also supports encoding multi-frame image with GIF, APNG and WebP.
 
 Example:
    
    YYImageEncoder *jpegEncoder = [[YYImageEncoder alloc] initWithType:YYImageTypeJPEG];
    jpegEncoder.quality = 0.9;
    [jpegEncoder addImage:image duration:0];
    NSData jpegData = [jpegEncoder encode];
 
    YYImageEncoder *gifEncoder = [[YYImageEncoder alloc] initWithType:YYImageTypeGIF];
    gifEncoder.loopCount = 5;
    [gifEncoder addImage:image0 duration:0.1];
    [gifEncoder addImage:image1 duration:0.15];
    [gifEncoder addImage:image2 duration:0.2];
    NSData gifData = [gifEncoder encode];
 
 @warning It just pack the images together when encoding multi-frame image. If you
 want to reduce the image file size, try imagemagick/ffmpeg for GIF and WebP,
 and apngasm for APNG.
 
 @note 支持单帧图片的压缩，以及GIF, APNG和WebP多帧图片的压缩；不过需要注意的是对于多帧图片只是把帧压缩到一起
 */
@interface YYImageEncoder : NSObject

// 图像的类型
@property (nonatomic, readonly) YYImageType type; ///< Image type.
// 循环次数,0代表无限循环；只针对多帧图片
@property (nonatomic) NSUInteger loopCount;       ///< Loop count, 0 means infinit, only available for GIF/APNG/WebP.
// 是否无损，只针对webP图片
@property (nonatomic) BOOL lossless;              ///< Lossless, only available for WebP.
// 压缩质量，只针对JPG/JP2/WebP类型
@property (nonatomic) CGFloat quality;            ///< Compress quality, 0.0~1.0, only available for JPG/JP2/WebP.

- (instancetype)init UNAVAILABLE_ATTRIBUTE;
+ (instancetype)new UNAVAILABLE_ATTRIBUTE;

/**
 Create an image encoder with a specified type.
 @param type Image type.
 @return A new encoder, or nil if an error occurs.
 
 @note 根据图片类型生成编码器
 */
- (nullable instancetype)initWithType:(YYImageType)type NS_DESIGNATED_INITIALIZER;

/**
 Add an image to encoder.
 @param image    Image.
 @param duration Image duration for animation. Pass 0 to ignore this parameter.
 
 @note 向编码器添加一个图片
 */
- (void)addImage:(UIImage *)image duration:(NSTimeInterval)duration;

/**
 Add an image with image data to encoder.
 @param data    Image data.
 @param duration Image duration for animation. Pass 0 to ignore this parameter.
 
 @note 向编码器添加一个图片数据
 */
- (void)addImageWithData:(NSData *)data duration:(NSTimeInterval)duration;

/**
 Add an image from a file path to encoder.
 @param path     Image file path.
 @param duration Image duration for animation. Pass 0 to ignore this parameter.
 
 @note 根据路径向编码器添加一个图片
 */
- (void)addImageWithFile:(NSString *)path duration:(NSTimeInterval)duration;

/**
 Encodes the image and returns the image data.
 @return The image data, or nil if an error occurs.
 
 @note 对图片进行编码
 */
- (nullable NSData *)encode;

/**
 Encodes the image to a file.
 @param path The file path (overwrite if exist).
 @return Whether succeed.
 
 @note 将编码的图片写入磁盘
 */
- (BOOL)encodeToFile:(NSString *)path;

/**
 Convenience method to encode single frame image.
 @param image   The image.
 @param type    The destination image type.
 @param quality Image quality, 0.0~1.0.
 @return The image data, or nil if an error occurs.
 
 @note 快捷的编码单帧图片的方法
 */
+ (nullable NSData *)encodeImage:(UIImage *)image type:(YYImageType)type quality:(CGFloat)quality;

/**
 Convenience method to encode image from a decoder.
 @param decoder The image decoder.
 @param type    The destination image type;
 @param quality Image quality, 0.0~1.0.
 @return The image data, or nil if an error occurs.
 
 @note 根据指定编码器快捷的编码图片
 */
+ (nullable NSData *)encodeImageWithDecoder:(YYImageDecoder *)decoder type:(YYImageType)type quality:(CGFloat)quality;

@end


#pragma mark - UIImage

@interface UIImage (YYImageCoder)

/**
 Decompress this image to bitmap, so when the image is displayed on screen, 
 the main thread won't be blocked by additional decode. If the image has already
 been decoded or unable to decode, it just returns itself.
 
 @return an image decoded, or just return itself if no needed.
 @see isDecodedForDisplay
 
 @note 将图片解压为位图，所以当图片展示到屏幕上的时候，主线程不会被额外的解压操作阻塞
 */
- (instancetype)imageByDecoded;

/**
 Wherher the image can be display on screen without additional decoding.
 @warning It just a hint for your code, change it has no other effect.
 
 @note 标记图片是否已经被解压了，只是代码的标识，改变这个值没有任何作用
 */
@property (nonatomic) BOOL isDecodedForDisplay;

/**
 Saves this image to iOS Photos Album. 
 
 @discussion  This method attempts to save the original data to album if the
 image is created from an animated GIF/APNG, otherwise, it will save the image 
 as JPEG or PNG (based on the alpha information).
 
 @param completionBlock The block invoked (in main thread) after the save operation completes.
    assetURL: An URL that identifies the saved image file. If the image is not saved, assetURL is nil.
    error: If the image is not saved, an error object that describes the reason for failure, otherwise nil.
 
 @note 将图片保存到相册，如果是GIF/APNG类型的图片会保存原始数据，其他类型的会保存成JPEG或者PNG（保留alpha通道）
 */
- (void)saveToAlbumWithCompletionBlock:(nullable void(^)(NSURL * _Nullable assetURL, NSError * _Nullable error))completionBlock;

/**
 Return a 'best' data representation for this image.
 
 @discussion The convertion based on these rule:
 1. If the image is created from an animated GIF/APNG/WebP, it returns the original data.
 2. It returns PNG or JPEG(0.9) representation based on the alpha information.
 
 @return Image data, or nil if an error occurs.
 
 @note 返回图片的最佳数据表示，GIF/APNG/WebP类型返回原始数据，其他的返回PNG或JPEG类型的数据（含alpha通道）
 */
- (nullable NSData *)imageDataRepresentation;

@end



#pragma mark - Helper

/// Detect a data's image type by reading the data's header 16 bytes (very fast).
// 通过读取16字节的数据头监测数据头像的类型（速度非常快）
CG_EXTERN YYImageType YYImageDetectType(CFDataRef data);

/// Convert YYImageType to UTI (such as kUTTypeJPEG).
// 将YYImageType转换为UTI类型
CG_EXTERN CFStringRef _Nullable YYImageTypeToUTType(YYImageType type);

/// Convert UTI (such as kUTTypeJPEG) to YYImageType.
// 将UTI类型转换为YYImageType
CG_EXTERN YYImageType YYImageTypeFromUTType(CFStringRef uti);

/// Get image type's file extension (such as @"jpg").
// 根据YYImageType获取图片后缀
CG_EXTERN NSString *_Nullable YYImageTypeGetExtension(YYImageType type);



/// Returns the shared DeviceRGB color space.
// 返回共享的deviceRGB颜色空间
CG_EXTERN CGColorSpaceRef YYCGColorSpaceGetDeviceRGB(void);

/// Returns the shared DeviceGray color space.
// 返回共享的deviceGray颜色空间
CG_EXTERN CGColorSpaceRef YYCGColorSpaceGetDeviceGray(void);

/// Returns whether a color space is DeviceRGB.
// 返回指定颜色空间是不是deviceRGB
CG_EXTERN BOOL YYCGColorSpaceIsDeviceRGB(CGColorSpaceRef space);

/// Returns whether a color space is DeviceGray.
// 返回指定颜色空间是不是deviceGray
CG_EXTERN BOOL YYCGColorSpaceIsDeviceGray(CGColorSpaceRef space);



/// Convert EXIF orientation value to UIImageOrientation.
// @note EXIF 可交换图像文件格式（Exchangeable image file format），为数码相机制定的记录数码照片的属性信息和拍摄数据
// 根据EXIF值获取图片UIImageOrientation的方向
CG_EXTERN UIImageOrientation YYUIImageOrientationFromEXIFValue(NSInteger value);

/// Convert UIImageOrientation to EXIF orientation value.
// 根据UIImageOrientation的方向获取EXIF值
CG_EXTERN NSInteger YYUIImageOrientationToEXIFValue(UIImageOrientation orientation);



/**
 Create a decoded image.
 创建一个解码的图片
 
 @discussion If the source image is created from a compressed image data (such as
 PNG or JPEG), you can use this method to decode the image. After decoded, you can
 access the decoded bytes with CGImageGetDataProvider() and CGDataProviderCopyData()
 without additional decode process. If the image has already decoded, this method
 just copy the decoded bytes to the new image.
 
 @param imageRef          The source image.
 @param decodeForDisplay  If YES, this method will decode the image and convert
          it to BGRA8888 (premultiplied) or BGRX8888 format for CALayer display.
 
 @return A decoded image, or NULL if an error occurs.
 
 @note 如果原图片是根据压缩的图片数据创建出来的，可以用这个方法解码图片，解压之后就可以直接使用CGImageGetDataProvider()和CGDataProviderCopyData()访问解压的字节而不用进行额外的解压过程。如果图片已经解压了，这个方法只会复制数据到一个新的imageRef
 */
CG_EXTERN CGImageRef _Nullable YYCGImageCreateDecodedCopy(CGImageRef imageRef, BOOL decodeForDisplay);

/**
 Create an image copy with an orientation.
 
 @param imageRef       Source image
 @param orientation    Image orientation which will applied to the image.
 @param destBitmapInfo Destimation image bitmap, only support 32bit format (such as ARGB8888).
 @return A new image, or NULL if an error occurs.
 
 @note 根据方向创建一个图片的copy
 */
CG_EXTERN CGImageRef _Nullable YYCGImageCreateCopyWithOrientation(CGImageRef imageRef,
                                                                  UIImageOrientation orientation,
                                                                  CGBitmapInfo destBitmapInfo);

/**
 Create an image copy with CGAffineTransform.
 
 @param imageRef       Source image.
 @param transform      Transform applied to image (left-bottom based coordinate system).
 @param destSize       Destination image size
 @param destBitmapInfo Destimation image bitmap, only support 32bit format (such as ARGB8888).
 @return A new image, or NULL if an error occurs.
 
 @note 根据放射转换创建一个新的图片
 */
CG_EXTERN CGImageRef _Nullable YYCGImageCreateAffineTransformCopy(CGImageRef imageRef,
                                                                  CGAffineTransform transform,
                                                                  CGSize destSize,
                                                                  CGBitmapInfo destBitmapInfo);

/**
 Encode an image to data with CGImageDestination.
 
 @param imageRef  The image.
 @param type      The image destination data type.
 @param quality   The quality (0.0~1.0)
 @return A new image data, or nil if an error occurs.
 
 @note 使用CGImageDestination将图片编码
 */
CG_EXTERN CFDataRef _Nullable YYCGImageCreateEncodedData(CGImageRef imageRef, YYImageType type, CGFloat quality);


/**
 Whether WebP is available in YYImage.
 @note 返回YYImage是否支持WebP
 */
CG_EXTERN BOOL YYImageWebPAvailable(void);

/**
 Get a webp image frame count;
 
 @param webpData WebP data.
 @return Image frame count, or 0 if an error occurs.
 
 @note 获取WebP图片的帧数
 */
CG_EXTERN NSUInteger YYImageGetWebPFrameCount(CFDataRef webpData);

/**
 Decode an image from WebP data, returns NULL if an error occurs.
 
 @param webpData          The WebP data.
 @param decodeForDisplay  If YES, this method will decode the image and convert it
                            to BGRA8888 (premultiplied) format for CALayer display.
                          解压成可以使用CALayer直接展示的图片
 @param useThreads        YES to enable multi-thread decode.
                            (speed up, but cost more CPU)
                          是否多线程解压（速度更快，但是消耗CPU）
 @param bypassFiltering   YES to skip the in-loop filtering.
                            (speed up, but may lose some smooth)
                          绕开过滤（速度更快，但是可以会丢失一些平滑）
 @param noFancyUpsampling YES to use faster pointwise upsampler.
                            (speed down, and may lose some details).
                          不使用高质量的采样，采用点采样（速度下降，可能丢失一些细节）
 @return The decoded image, or NULL if an error occurs.
 
 @note 解压WebP数据
 */
CG_EXTERN CGImageRef _Nullable YYCGImageCreateWithWebPData(CFDataRef webpData,
                                                           BOOL decodeForDisplay,
                                                           BOOL useThreads,
                                                           BOOL bypassFiltering,
                                                           BOOL noFancyUpsampling);
// YYImage预置枚举
typedef NS_ENUM(NSUInteger, YYImagePreset) {
    YYImagePresetDefault = 0,  ///< default preset.
    YYImagePresetPicture,      ///< digital picture, like portrait, inner shot
    YYImagePresetPhoto,        ///< outdoor photograph, with natural lighting
    YYImagePresetDrawing,      ///< hand or line drawing, with high-contrast details
    YYImagePresetIcon,         ///< small-sized colorful images
    YYImagePresetText          ///< text-like
};

/**
 Encode a CGImage to WebP data
 
 @param imageRef      image
 @param lossless      YES=lossless (similar to PNG), NO=lossy (similar to JPEG)
 @param quality       0.0~1.0 (0=smallest file, 1.0=biggest file)
                      For lossless image, try the value near 1.0; for lossy, try the value near 0.8.
 @param compressLevel 0~6 (0=fast, 6=slower-better). Default is 4.
 @param preset        Preset for different image type, default is YYImagePresetDefault.
 @return WebP data, or nil if an error occurs.
 
 @note 将CGImage转换为WebP数据
 */
CG_EXTERN CFDataRef _Nullable YYCGImageCreateEncodedWebPData(CGImageRef imageRef,
                                                             BOOL lossless,
                                                             CGFloat quality,
                                                             int compressLevel,
                                                             YYImagePreset preset);

NS_ASSUME_NONNULL_END
