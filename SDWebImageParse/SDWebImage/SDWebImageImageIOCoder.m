/*
 * This file is part of the SDWebImage package.
 * (c) Olivier Poitrey <rs@dailymotion.com>
 *
 * For the full copyright and license information, please view the LICENSE
 * file that was distributed with this source code.
 */

#import "SDWebImageImageIOCoder.h"
#import "SDWebImageCoderHelper.h"
#import "NSImage+WebCache.h"
#import <ImageIO/ImageIO.h>
#import "NSData+ImageContentType.h"

#if SD_UIKIT || SD_WATCH
// wwt 每个像素含有的字节
static const size_t kBytesPerPixel = 4;
// wwt 每个像素组成元素的位数
static const size_t kBitsPerComponent = 8;

/* wwt 当设置SDWebImageScaleDownLargeImages标识的解码后图片的最大尺寸（MB）
 * Defines the maximum size in MB of the decoded image when the flag `SDWebImageScaleDownLargeImages` is set
 * Suggested value for iPad1 and iPhone 3GS: 60.
 * Suggested value for iPad2 and iPhone 4: 120.
 * Suggested value for iPhone 3G and iPod 2 and earlier devices: 30.
 */
static const CGFloat kDestImageSizeMB = 60.0f;

/* wwt 当设置SDWebImageScaleDownLargeImages标识时，解码图片使用的图块的最大大小（MB）
 * Defines the maximum size in MB of a tile used to decode image when the flag `SDWebImageScaleDownLargeImages` is set
 * Suggested value for iPad1 and iPhone 3GS: 20.
 * Suggested value for iPad2 and iPhone 4: 40.
 * Suggested value for iPhone 3G and iPod 2 and earlier devices: 10.
 */
static const CGFloat kSourceImageTileSizeMB = 20.0f;

// wwt 1M有多少字节
static const CGFloat kBytesPerMB = 1024.0f * 1024.0f;
// wwt 1M有多少像素
static const CGFloat kPixelsPerMB = kBytesPerMB / kBytesPerPixel;
// wwt 解压后的图片的总像素（应该是最大）
static const CGFloat kDestTotalPixels = kDestImageSizeMB * kPixelsPerMB;
// wwt 解压图片使用的图块的总像素（应该是最大）
static const CGFloat kTileTotalPixels = kSourceImageTileSizeMB * kPixelsPerMB;

// wwt 图块交界的地方重叠的像素
static const CGFloat kDestSeemOverlap = 2.0f;   // the numbers of pixels to overlap the seems where tiles meet.
#endif

@implementation SDWebImageImageIOCoder {
        size_t _width, _height;
#if SD_UIKIT || SD_WATCH
        UIImageOrientation _orientation;
#endif
        CGImageSourceRef _imageSource;
}

// wwt CoreFoundation的对象arc不管理，需要手动管理
- (void)dealloc {
    if (_imageSource) {
        CFRelease(_imageSource);
        _imageSource = NULL;
    }
}

+ (instancetype)sharedCoder {
    static SDWebImageImageIOCoder *coder;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        coder = [[SDWebImageImageIOCoder alloc] init];
    });
    return coder;
}

#pragma mark - Decode
// wwt ImageIOCoder不支持WebP类型，HEIC需要根据设备判断iOS11+支持
- (BOOL)canDecodeFromData:(nullable NSData *)data {
    switch ([NSData sd_imageFormatForImageData:data]) {
        case SDImageFormatWebP:
            // Do not support WebP decoding
            return NO;
        case SDImageFormatHEIC:
            // Check HEIC decoding compatibility
            return [[self class] canDecodeFromHEICFormat];
        default:
            return YES;
    }
}

// wwt ImageIOCoder不支持WebP类型，HEIC需要根据设备判断iOS11+支持
- (BOOL)canIncrementallyDecodeFromData:(NSData *)data {
    switch ([NSData sd_imageFormatForImageData:data]) {
        case SDImageFormatWebP:
            // Do not support WebP progressive decoding
            return NO;
        case SDImageFormatHEIC:
            // Check HEIC decoding compatibility
            return [[self class] canDecodeFromHEICFormat];
        default:
            return YES;
    }
}

// wwt 将data解码,并设置方向
- (UIImage *)decodedImageWithData:(NSData *)data {
    if (!data) {
        return nil;
    }
    
    UIImage *image = [[UIImage alloc] initWithData:data];
    
#if SD_MAC
    return image;
#else
    if (!image) {
        return nil;
    }
    
    UIImageOrientation orientation = [[self class] sd_imageOrientationFromImageData:data];
    if (orientation != UIImageOrientationUp) {
        image = [[UIImage alloc] initWithCGImage:image.CGImage scale:image.scale orientation:orientation];
    }
    
    return image;
#endif
}

// wwt 逐行解码图像数据
- (UIImage *)incrementallyDecodedImageWithData:(NSData *)data finished:(BOOL)finished {
    if (!_imageSource) {
        _imageSource = CGImageSourceCreateIncremental(NULL);
    }
    UIImage *image;
    
    // The following code is from http://www.cocoaintheshell.com/2011/05/progressive-images-download-imageio/
    // Thanks to the author @Nyx0uf
    
    // Update the data source, we must pass ALL the data, not just the new bytes
    CGImageSourceUpdateData(_imageSource, (__bridge CFDataRef)data, finished);
    
    if (_width + _height == 0) {
        CFDictionaryRef properties = CGImageSourceCopyPropertiesAtIndex(_imageSource, 0, NULL);
        if (properties) {
            NSInteger orientationValue = 1;
            CFTypeRef val = CFDictionaryGetValue(properties, kCGImagePropertyPixelHeight);
            if (val) CFNumberGetValue(val, kCFNumberLongType, &_height);
            val = CFDictionaryGetValue(properties, kCGImagePropertyPixelWidth);
            if (val) CFNumberGetValue(val, kCFNumberLongType, &_width);
            val = CFDictionaryGetValue(properties, kCGImagePropertyOrientation);
            if (val) CFNumberGetValue(val, kCFNumberNSIntegerType, &orientationValue);
            CFRelease(properties);
            
            // When we draw to Core Graphics, we lose orientation information,
            // which means the image below born of initWithCGIImage will be
            // oriented incorrectly sometimes. (Unlike the image born of initWithData
            // in didCompleteWithError.) So save it here and pass it on later.
#if SD_UIKIT || SD_WATCH
            _orientation = [SDWebImageCoderHelper imageOrientationFromEXIFOrientation:orientationValue];
#endif
        }
    }
    
    if (_width + _height > 0) {
        // Create the image
        CGImageRef partialImageRef = CGImageSourceCreateImageAtIndex(_imageSource, 0, NULL);
        
#if SD_UIKIT || SD_WATCH
        // Workaround for iOS anamorphic image
        if (partialImageRef) {
            const size_t partialHeight = CGImageGetHeight(partialImageRef);
            CGColorSpaceRef colorSpace = SDCGColorSpaceGetDeviceRGB();
            CGContextRef bmContext = CGBitmapContextCreate(NULL, _width, _height, 8, 0, colorSpace, kCGBitmapByteOrderDefault | kCGImageAlphaPremultipliedFirst);
            if (bmContext) {
                CGContextDrawImage(bmContext, (CGRect){.origin.x = 0.0f, .origin.y = 0.0f, .size.width = _width, .size.height = partialHeight}, partialImageRef);
                CGImageRelease(partialImageRef);
                partialImageRef = CGBitmapContextCreateImage(bmContext);
                CGContextRelease(bmContext);
            }
            else {
                CGImageRelease(partialImageRef);
                partialImageRef = nil;
            }
        }
#endif
        
        if (partialImageRef) {
#if SD_UIKIT || SD_WATCH
            image = [[UIImage alloc] initWithCGImage:partialImageRef scale:1 orientation:_orientation];
#elif SD_MAC
            image = [[UIImage alloc] initWithCGImage:partialImageRef size:NSZeroSize];
#endif
            CGImageRelease(partialImageRef);
        }
    }
    
    if (finished) {
        if (_imageSource) {
            CFRelease(_imageSource);
            _imageSource = NULL;
        }
    }
    
    return image;
}

// wwt 解压指定的图片
- (UIImage *)decompressedImageWithImage:(UIImage *)image
                                   data:(NSData *__autoreleasing  _Nullable *)data
                                options:(nullable NSDictionary<NSString*, NSObject*>*)optionsDict {
#if SD_MAC
    return image;
#endif
#if SD_UIKIT || SD_WATCH
    BOOL shouldScaleDown = NO;
    if (optionsDict != nil) {
        NSNumber *scaleDownLargeImagesOption = nil;
        if ([optionsDict[SDWebImageCoderScaleDownLargeImagesKey] isKindOfClass:[NSNumber class]]) {
            scaleDownLargeImagesOption = (NSNumber *)optionsDict[SDWebImageCoderScaleDownLargeImagesKey];
        }
        if (scaleDownLargeImagesOption != nil) {
            shouldScaleDown = [scaleDownLargeImagesOption boolValue];
        }
    }
    if (!shouldScaleDown) {
        return [self sd_decompressedImageWithImage:image];
    } else {
        UIImage *scaledDownImage = [self sd_decompressedAndScaledDownImageWithImage:image];
        if (scaledDownImage && !CGSizeEqualToSize(scaledDownImage.size, image.size)) {
            // if the image is scaled down, need to modify the data pointer as well
            SDImageFormat format = [NSData sd_imageFormatForImageData:*data];
            NSData *imageData = [self encodedDataWithImage:scaledDownImage format:format];
            if (imageData) {
                *data = imageData;
            }
        }
        return scaledDownImage;
    }
#endif
}

// wwt 将图片解压（删除alpha通道）
#if SD_UIKIT || SD_WATCH
- (nullable UIImage *)sd_decompressedImageWithImage:(nullable UIImage *)image {
    if (![[self class] shouldDecodeImage:image]) {
        return image;
    }
    
    // wwt 当有内存警告的时候自动释放bitMap上下文和所有的变量，释放内存
    // autorelease the bitmap context and all vars to help system to free memory when there are memory warning.
    // on iOS7, do not forget to call [[SDImageCache sharedImageCache] clearMemory];
    @autoreleasepool{
        
        CGImageRef imageRef = image.CGImage;
        CGColorSpaceRef colorspaceRef = [[self class] colorSpaceForImageRef:imageRef];
        
        size_t width = CGImageGetWidth(imageRef);
        size_t height = CGImageGetHeight(imageRef);
        
        // wwt CGBitmapContextCreate不支持kCGImageAlphaNone（没有alpha通道的模式），由于这里的原始图片没有alpha信息
        //     所以使用kCGImageAlphaNoneSkipLast
        // kCGImageAlphaNone is not supported in CGBitmapContextCreate.
        // Since the original image here has no alpha info, use kCGImageAlphaNoneSkipLast
        // to create bitmap graphics contexts without alpha info.
        CGContextRef context = CGBitmapContextCreate(NULL,
                                                     width,
                                                     height,
                                                     kBitsPerComponent,
                                                     0,
                                                     colorspaceRef,
                                                     kCGBitmapByteOrderDefault|kCGImageAlphaNoneSkipLast);
        if (context == NULL) {
            return image;
        }
        
        // Draw the image into the context and retrieve the new bitmap image without alpha
        CGContextDrawImage(context, CGRectMake(0, 0, width, height), imageRef);
        CGImageRef imageRefWithoutAlpha = CGBitmapContextCreateImage(context);
        UIImage *imageWithoutAlpha = [[UIImage alloc] initWithCGImage:imageRefWithoutAlpha scale:image.scale orientation:image.imageOrientation];
        CGContextRelease(context);
        CGImageRelease(imageRefWithoutAlpha);
        
        return imageWithoutAlpha;
    }
}

// wwt 解压需要缩小的图片
- (nullable UIImage *)sd_decompressedAndScaledDownImageWithImage:(nullable UIImage *)image {
    if (![[self class] shouldDecodeImage:image]) {
        return image;
    }
    
    if (![[self class] shouldScaleDownImage:image]) {
        return [self sd_decompressedImageWithImage:image];
    }
    
    CGContextRef destContext;
    
    // autorelease the bitmap context and all vars to help system to free memory when there are memory warning.
    // on iOS7, do not forget to call [[SDImageCache sharedImageCache] clearMemory];
    @autoreleasepool {
        CGImageRef sourceImageRef = image.CGImage;
        
        CGSize sourceResolution = CGSizeZero;
        sourceResolution.width = CGImageGetWidth(sourceImageRef);
        sourceResolution.height = CGImageGetHeight(sourceImageRef);
        float sourceTotalPixels = sourceResolution.width * sourceResolution.height;
        // Determine the scale ratio to apply to the input image
        // that results in an output image of the defined size.
        // see kDestImageSizeMB, and how it relates to destTotalPixels.
        float imageScale = kDestTotalPixels / sourceTotalPixels;
        CGSize destResolution = CGSizeZero;
        destResolution.width = (int)(sourceResolution.width*imageScale);
        destResolution.height = (int)(sourceResolution.height*imageScale);
        
        // current color space
        CGColorSpaceRef colorspaceRef = [[self class] colorSpaceForImageRef:sourceImageRef];
        
        // kCGImageAlphaNone is not supported in CGBitmapContextCreate.
        // Since the original image here has no alpha info, use kCGImageAlphaNoneSkipLast
        // to create bitmap graphics contexts without alpha info.
        destContext = CGBitmapContextCreate(NULL,
                                            destResolution.width,
                                            destResolution.height,
                                            kBitsPerComponent,
                                            0,
                                            colorspaceRef,
                                            kCGBitmapByteOrderDefault|kCGImageAlphaNoneSkipLast);
        
        if (destContext == NULL) {
            return image;
        }
        CGContextSetInterpolationQuality(destContext, kCGInterpolationHigh);
        
        // Now define the size of the rectangle to be used for the
        // incremental blits from the input image to the output image.
        // we use a source tile width equal to the width of the source
        // image due to the way that iOS retrieves image data from disk.
        // iOS must decode an image from disk in full width 'bands', even
        // if current graphics context is clipped to a subrect within that
        // band. Therefore we fully utilize all of the pixel data that results
        // from a decoding opertion by achnoring our tile size to the full
        // width of the input image.
        CGRect sourceTile = CGRectZero;
        sourceTile.size.width = sourceResolution.width;
        // The source tile height is dynamic. Since we specified the size
        // of the source tile in MB, see how many rows of pixels high it
        // can be given the input image width.
        sourceTile.size.height = (int)(kTileTotalPixels / sourceTile.size.width );
        sourceTile.origin.x = 0.0f;
        // The output tile is the same proportions as the input tile, but
        // scaled to image scale.
        CGRect destTile;
        destTile.size.width = destResolution.width;
        destTile.size.height = sourceTile.size.height * imageScale;
        destTile.origin.x = 0.0f;
        // The source seem overlap is proportionate to the destination seem overlap.
        // this is the amount of pixels to overlap each tile as we assemble the ouput image.
        float sourceSeemOverlap = (int)((kDestSeemOverlap/destResolution.height)*sourceResolution.height);
        CGImageRef sourceTileImageRef;
        // calculate the number of read/write operations required to assemble the
        // output image.
        int iterations = (int)( sourceResolution.height / sourceTile.size.height );
        // If tile height doesn't divide the image height evenly, add another iteration
        // to account for the remaining pixels.
        int remainder = (int)sourceResolution.height % (int)sourceTile.size.height;
        if(remainder) {
            iterations++;
        }
        // Add seem overlaps to the tiles, but save the original tile height for y coordinate calculations.
        float sourceTileHeightMinusOverlap = sourceTile.size.height;
        sourceTile.size.height += sourceSeemOverlap;
        destTile.size.height += kDestSeemOverlap;
        for( int y = 0; y < iterations; ++y ) {
            @autoreleasepool {
                sourceTile.origin.y = y * sourceTileHeightMinusOverlap + sourceSeemOverlap;
                destTile.origin.y = destResolution.height - (( y + 1 ) * sourceTileHeightMinusOverlap * imageScale + kDestSeemOverlap);
                sourceTileImageRef = CGImageCreateWithImageInRect( sourceImageRef, sourceTile );
                if( y == iterations - 1 && remainder ) {
                    float dify = destTile.size.height;
                    destTile.size.height = CGImageGetHeight( sourceTileImageRef ) * imageScale;
                    dify -= destTile.size.height;
                    destTile.origin.y += dify;
                }
                CGContextDrawImage( destContext, destTile, sourceTileImageRef );
                CGImageRelease( sourceTileImageRef );
            }
        }
        
        CGImageRef destImageRef = CGBitmapContextCreateImage(destContext);
        CGContextRelease(destContext);
        if (destImageRef == NULL) {
            return image;
        }
        UIImage *destImage = [[UIImage alloc] initWithCGImage:destImageRef scale:image.scale orientation:image.imageOrientation];
        CGImageRelease(destImageRef);
        if (destImage == nil) {
            return image;
        }
        return destImage;
    }
}
#endif

#pragma mark - Encode
// wwt 是否可以编码执行的格式
- (BOOL)canEncodeToFormat:(SDImageFormat)format {
    switch (format) {
        case SDImageFormatWebP:
            // Do not support WebP encoding
            return NO;
        case SDImageFormatHEIC:
            // Check HEIC encoding compatibility
            return [[self class] canEncodeToHEICFormat];
        default:
            return YES;
    }
}

// wwt 对图片使用指定的格式编码
- (NSData *)encodedDataWithImage:(UIImage *)image format:(SDImageFormat)format {
    if (!image) {
        return nil;
    }
    
    if (format == SDImageFormatUndefined) {
        BOOL hasAlpha = SDCGImageRefContainsAlpha(image.CGImage);
        if (hasAlpha) {
            format = SDImageFormatPNG;
        } else {
            format = SDImageFormatJPEG;
        }
    }
    
    NSMutableData *imageData = [NSMutableData data];
    CFStringRef imageUTType = [NSData sd_UTTypeFromSDImageFormat:format];
    
    // Create an image destination.
    CGImageDestinationRef imageDestination = CGImageDestinationCreateWithData((__bridge CFMutableDataRef)imageData, imageUTType, 1, NULL);
    if (!imageDestination) {
        // Handle failure.
        return nil;
    }
    
    NSMutableDictionary *properties = [NSMutableDictionary dictionary];
#if SD_UIKIT || SD_WATCH
    NSInteger exifOrientation = [SDWebImageCoderHelper exifOrientationFromImageOrientation:image.imageOrientation];
    [properties setValue:@(exifOrientation) forKey:(__bridge_transfer NSString *)kCGImagePropertyOrientation];
#endif
    
    // Add your image to the destination.
    CGImageDestinationAddImage(imageDestination, image.CGImage, (__bridge CFDictionaryRef)properties);
    
    // Finalize the destination.
    if (CGImageDestinationFinalize(imageDestination) == NO) {
        // Handle failure.
        imageData = nil;
    }
    
    CFRelease(imageDestination);
    
    return [imageData copy];
}

#pragma mark - Helper
// wwt 不解码动图，不解码使用alpha通道的图片
+ (BOOL)shouldDecodeImage:(nullable UIImage *)image {
    // Prevent "CGBitmapContextCreateImage: invalid context 0x0" error
    if (image == nil) {
        return NO;
    }
    
    // do not decode animated images
    if (image.images != nil) {
        return NO;
    }
    
    CGImageRef imageRef = image.CGImage;
    
    BOOL hasAlpha = SDCGImageRefContainsAlpha(imageRef);
    // do not decode images with alpha
    if (hasAlpha) {
        return NO;
    }
    
    return YES;
}

// wwt 是否可以解码HEIC类型的图片 iOS11支持
+ (BOOL)canDecodeFromHEICFormat {
    static BOOL canDecode = NO;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wunguarded-availability"
#if TARGET_OS_SIMULATOR || SD_WATCH
        canDecode = NO;
#elif SD_MAC
        NSProcessInfo *processInfo = [NSProcessInfo processInfo];
        if ([processInfo respondsToSelector:@selector(operatingSystemVersion)]) {
            // macOS 10.13+
            canDecode = processInfo.operatingSystemVersion.minorVersion >= 13;
        } else {
            canDecode = NO;
        }
#elif SD_UIKIT
        NSProcessInfo *processInfo = [NSProcessInfo processInfo];
        if ([processInfo respondsToSelector:@selector(operatingSystemVersion)]) {
            // iOS 11+ && tvOS 11+
            canDecode = processInfo.operatingSystemVersion.majorVersion >= 11;
        } else {
            canDecode = NO;
        }
#endif
#pragma clang diagnostic pop
    });
    return canDecode;
}

// wwt 是否可以编码HEIC类型的图片
+ (BOOL)canEncodeToHEICFormat {
    static BOOL canEncode = NO;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSMutableData *imageData = [NSMutableData data];
        CFStringRef imageUTType = [NSData sd_UTTypeFromSDImageFormat:SDImageFormatHEIC];
        
        // Create an image destination.
        CGImageDestinationRef imageDestination = CGImageDestinationCreateWithData((__bridge CFMutableDataRef)imageData, imageUTType, 1, NULL);
        if (!imageDestination) {
            // Can't encode to HEIC
            canEncode = NO;
        } else {
            // Can encode to HEIC
            CFRelease(imageDestination);
            canEncode = YES;
        }
    });
    return canEncode;
}

// wwt 获取图片的方向
#if SD_UIKIT || SD_WATCH
#pragma mark EXIF orientation tag converter
+ (UIImageOrientation)sd_imageOrientationFromImageData:(nonnull NSData *)imageData {
    UIImageOrientation result = UIImageOrientationUp;
    CGImageSourceRef imageSource = CGImageSourceCreateWithData((__bridge CFDataRef)imageData, NULL);
    if (imageSource) {
        CFDictionaryRef properties = CGImageSourceCopyPropertiesAtIndex(imageSource, 0, NULL);
        if (properties) {
            CFTypeRef val;
            NSInteger exifOrientation;
            val = CFDictionaryGetValue(properties, kCGImagePropertyOrientation);
            if (val) {
                CFNumberGetValue(val, kCFNumberNSIntegerType, &exifOrientation);
                result = [SDWebImageCoderHelper imageOrientationFromEXIFOrientation:exifOrientation];
            } // else - if it's not set it remains at up
            CFRelease((CFTypeRef) properties);
        } else {
            //NSLog(@"NO PROPERTIES, FAIL");
        }
        CFRelease(imageSource);
    }
    return result;
}
#endif

// wwt 判断图片是否需要缩放
#if SD_UIKIT || SD_WATCH
+ (BOOL)shouldScaleDownImage:(nonnull UIImage *)image {
    BOOL shouldScaleDown = YES;
    
    CGImageRef sourceImageRef = image.CGImage;
    CGSize sourceResolution = CGSizeZero;
    sourceResolution.width = CGImageGetWidth(sourceImageRef);
    sourceResolution.height = CGImageGetHeight(sourceImageRef);
    float sourceTotalPixels = sourceResolution.width * sourceResolution.height;
    float imageScale = kDestTotalPixels / sourceTotalPixels;
    if (imageScale < 1) {
        shouldScaleDown = YES;
    } else {
        shouldScaleDown = NO;
    }
    
    return shouldScaleDown;
}

// wwt 返回图片的颜色空间，如果是不支持的颜色空间返回设备的RGB颜色空间
+ (CGColorSpaceRef)colorSpaceForImageRef:(CGImageRef)imageRef {
    // current
    CGColorSpaceModel imageColorSpaceModel = CGColorSpaceGetModel(CGImageGetColorSpace(imageRef));
    CGColorSpaceRef colorspaceRef = CGImageGetColorSpace(imageRef);
    
    BOOL unsupportedColorSpace = (imageColorSpaceModel == kCGColorSpaceModelUnknown ||
                                  imageColorSpaceModel == kCGColorSpaceModelMonochrome ||
                                  imageColorSpaceModel == kCGColorSpaceModelCMYK ||
                                  imageColorSpaceModel == kCGColorSpaceModelIndexed);
    if (unsupportedColorSpace) {
        colorspaceRef = SDCGColorSpaceGetDeviceRGB();
    }
    return colorspaceRef;
}
#endif

@end
