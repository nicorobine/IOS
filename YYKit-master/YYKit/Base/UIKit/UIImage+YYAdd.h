//
//  UIImage+YYAdd.h
//  YYKit <https://github.com/ibireme/YYKit>
//
//  Created by ibireme on 13/4/4.
//  Copyright (c) 2015 ibireme.
//
//  This source code is licensed under the MIT-style license found in the
//  LICENSE file in the root directory of this source tree.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

/**
 Provide some commen method for `UIImage`.
 Image process is based on CoreGraphic and vImage.
 
 为UIImage提供了一些常用的方法，图像处理给予CoreGraphics和vImage
 */
@interface UIImage (YYAdd)

#pragma mark - Create image
///=============================================================================
/// @name Create image
///=============================================================================

/**
 Create an animated image with GIF data. After created, you can access
 the images via property '.images'. If the data is not animated gif, this
 function is same as [UIImage imageWithData:data scale:scale];
 
 创建一个GIF格式数据的动态图片，你可以通过.images访问这些图片，如果数据不是gif动态图，这个方法和imagewithData:scale
 的作用一样
 需要注意的是，它得到了更好的展示体验，但是使用了更大的内存，只适合展示比较小的gif动态图，如果动态emoji，如果想要展示大的gif
 使用YYImage
 
 @discussion     It has a better display performance, but costs more memory
                 (width * height * frames Bytes). It only suited to display small 
                 gif such as animated emoticon. If you want to display large gif, 
                 see `YYImage`.
 
 @param data     GIF data.
 
 @param scale    The scale factor
 
 @return A new image created from GIF, or nil when an error occurs.
 */
+ (nullable UIImage *)imageWithSmallGIFData:(NSData *)data scale:(CGFloat)scale;

/**
 Whether the data is animated GIF.
 
 判断data是否是动态gif
 
 @param data Image data
 
 @return Returns YES only if the data is gif and contains more than one frame,
         otherwise returns NO.
 */
+ (BOOL)isAnimatedGIFData:(NSData *)data;

/**
 Whether the file in the specified path is GIF.
 
 判断路径的file是否是gif动态图
 
 @param path An absolute file path.
 
 @return Returns YES if the file is gif, otherwise returns NO.
 */
+ (BOOL)isAnimatedGIFFile:(NSString *)path;

/**
 Create an image from a PDF file data or path.
 
 根据PDF文件路径创建一个图片
 需要注意的是如果是多页的PDF文件只会取第一页的内容，图片的scale会取自屏幕，大小曲子pdf的原始大小
 
 @discussion If the PDF has multiple page, is just return's the first page's
 content. Image's scale is equal to current screen's scale, size is same as 
 PDF's origin size.
 
 @param dataOrPath PDF data in `NSData`, or PDF file path in `NSString`.
 
 @return A new image create from PDF, or nil when an error occurs.
 */
+ (nullable UIImage *)imageWithPDF:(id)dataOrPath;

/**
 Create an image from a PDF file data or path.
 
 根据PDF文件路径或者数据创建图片（可以指定大小，如果必要图片会被拉伸）
 
 @discussion If the PDF has multiple page, is just return's the first page's
 content. Image's scale is equal to current screen's scale.
 
 @param dataOrPath  PDF data in `NSData`, or PDF file path in `NSString`.
 
 @param size     The new image's size, PDF's content will be stretched as needed.
 
 @return A new image create from PDF, or nil when an error occurs.
 */
+ (nullable UIImage *)imageWithPDF:(id)dataOrPath size:(CGSize)size;

/**
 Create a square image from apple emoji.
 
 根据苹果的emoji创建一个正方形的图片
 
 @discussion It creates a square image from apple emoji, image's scale is equal
 to current screen's scale. The original emoji image in `AppleColorEmoji` font 
 is in size 160*160 px.
 
 @param emoji single emoji, such as @"😄".
 
 @param size  image's size.
 
 @return Image from emoji, or nil when an error occurs.
 */
+ (nullable UIImage *)imageWithEmoji:(NSString *)emoji size:(CGFloat)size;

/**
 Create and return a 1x1 point size image with the given color.
 
 创建并返回一个1*1点大小的指定颜色的图片
 
 @param color  The color.
 */
+ (nullable UIImage *)imageWithColor:(UIColor *)color;

/**
 Create and return a pure color image with the given color and size.
 
 根据指定的颜色和大小创建一个纯色的图片
 
 @param color  The color.
 @param size   New image's type.
 */
+ (nullable UIImage *)imageWithColor:(UIColor *)color size:(CGSize)size;

/**
 Create and return an image with custom draw code.
 
 创建并返回一个可以自定义绘图代码的图片
 
 @param size      The image size.
 @param drawBlock The draw block.
 
 @return The new image.
 */
+ (nullable UIImage *)imageWithSize:(CGSize)size drawBlock:(void (^)(CGContextRef context))drawBlock;

#pragma mark - Image Info
///=============================================================================
/// @name Image Info
///=============================================================================

/**
 Whether this image has alpha channel.
 图片是否含有alpha通道
 */
- (BOOL)hasAlphaChannel;


#pragma mark - Modify Image
///=============================================================================
/// @name Modify Image
///=============================================================================

/**
 Draws the entire image in the specified rectangle, content changed with
 the contentMode.
 
 根据contentMode将整个图片绘制到指定的矩形
 
 这个方式在当前图形上下文中，以图像原来的的方向绘制整个图像。在默认坐标系总，图片位于指定矩形远点的右下方。
 这个方法会适用应用于当前图形上下文的所有变换
 
 @discussion This method draws the entire image in the current graphics context, 
 respecting the image's orientation setting. In the default coordinate system, 
 images are situated down and to the right of the origin of the specified 
 rectangle. This method respects any transforms applied to the current graphics 
 context, however.
 
 @param rect        The rectangle in which to draw the image.
 
 @param contentMode Draw content mode
 
 @param clips       A Boolean value that determines whether content are confined to the rect.
 */
- (void)drawInRect:(CGRect)rect withContentMode:(UIViewContentMode)contentMode clipsToBounds:(BOOL)clips;

/**
 Returns a new image which is scaled from this image.
 The image will be stretched as needed.
 
 返回一个警告缩放的新图片，如果必要图片会被拉伸
 
 @param size  The new size to be scaled, values should be positive.
 
 @return      The new image with the given size.
 */
- (nullable UIImage *)imageByResizeToSize:(CGSize)size;

/**
 Returns a new image which is scaled from this image.
 The image content will be changed with thencontentMode.
 
 返回一个根据本图片缩放后的新图片，会根据contentMode更改图片的内容
 
 @param size        The new size to be scaled, values should be positive.
 
 @param contentMode The content mode for image content.
 
 @return The new image with the given size.
 */
- (nullable UIImage *)imageByResizeToSize:(CGSize)size contentMode:(UIViewContentMode)contentMode;

/**
 Returns a new image which is cropped from this image.
 
 返回此图像裁剪后的新图像
 
 @param rect  Image's inner rect.
 
 @return      The new image, or nil if an error occurs.
 */
- (nullable UIImage *)imageByCropToRect:(CGRect)rect;

/**
 Returns a new image which is edge inset from this image.
 
 根据本图像返回一个带边框的新图像
 
 @param insets  Inset (positive) for each of the edges, values can be negative to 'outset'.
 
 @param color   Extend edge's fill color, nil means clear color.
 
 @return        The new image, or nil if an error occurs.
 */
- (nullable UIImage *)imageByInsetEdge:(UIEdgeInsets)insets withColor:(nullable UIColor *)color;

/**
 Rounds a new image with a given corner size.
 
 返回一个带圆角的新图像
 
 @param radius  The radius of each corner oval. Values larger than half the
                rectangle's width or height are clamped appropriately to half
                the width or height.
 */
- (nullable UIImage *)imageByRoundCornerRadius:(CGFloat)radius;

/**
 Rounds a new image with a given corner size.
 
 返回一个指定边界圆角，边界宽度和颜色的新图像对象
 
 @param radius       The radius of each corner oval. Values larger than half the
                     rectangle's width or height are clamped appropriately to
                     half the width or height.

 @param borderWidth  The inset border line width. Values larger than half the rectangle's
                     width or height are clamped appropriately to half the width 
                     or height.
 
 @param borderColor  The border stroke color. nil means clear color.
 */
- (nullable UIImage *)imageByRoundCornerRadius:(CGFloat)radius
                                   borderWidth:(CGFloat)borderWidth
                                   borderColor:(nullable UIColor *)borderColor;

/**
 Rounds a new image with a given corner size.
 
 返回一个指定边界圆角，边界宽度和颜色，和边界交汇类型的新图像对象
 
 @param radius       The radius of each corner oval. Values larger than half the
                     rectangle's width or height are clamped appropriately to
                     half the width or height.
 
 @param corners      A bitmask value that identifies the corners that you want
                     rounded. You can use this parameter to round only a subset
                     of the corners of the rectangle.
 
 @param borderWidth  The inset border line width. Values larger than half the rectangle's
                     width or height are clamped appropriately to half the width 
                     or height.
 
 @param borderColor  The border stroke color. nil means clear color.
 
 @param borderLineJoin The border line join.
 */
- (nullable UIImage *)imageByRoundCornerRadius:(CGFloat)radius
                                       corners:(UIRectCorner)corners
                                   borderWidth:(CGFloat)borderWidth
                                   borderColor:(nullable UIColor *)borderColor
                                borderLineJoin:(CGLineJoin)borderLineJoin;

/**
 Returns a new rotated image (relative to the center).
 
 返回一个旋转锅指定弧度的图片
 
 @param radians   Rotated radians in counterclockwise.⟲
 
 @param fitSize   YES: new image's size is extend to fit all content.
                  NO: image's size will not change, content may be clipped.
 */
- (nullable UIImage *)imageByRotate:(CGFloat)radians fitSize:(BOOL)fitSize;

/**
 Returns a new image rotated counterclockwise by a quarter‑turn (90°). ⤺
 The width and height will be exchanged.
 返回一个逆时针转动90的图片，宽度和高度也做相应的转换
 */
- (nullable UIImage *)imageByRotateLeft90;

/**
 Returns a new image rotated clockwise by a quarter‑turn (90°). ⤼
 The width and height will be exchanged.
 返回一个顺时针转动90的图片，宽度和高度也做相应的转换
 */
- (nullable UIImage *)imageByRotateRight90;

/**
 Returns a new image rotated 180° . ↻
 返回一个转动180度的图片
 */
- (nullable UIImage *)imageByRotate180;

/**
 Returns a vertically flipped image. ⥯
 返回一个垂直翻转的图像
 */
- (nullable UIImage *)imageByFlipVertical;

/**
 Returns a horizontally flipped image. ⇋
 返回一个垂直翻转的图像
 */
- (nullable UIImage *)imageByFlipHorizontal;


#pragma mark - Image Effect
///=============================================================================
/// @name Image Effect
///=============================================================================

/**
 Tint the image in alpha channel with the given color.
 
 返回渲染指定颜色的图像
 
 @param color  The color.
 */
- (nullable UIImage *)imageByTintColor:(UIColor *)color;

/**
 Returns a grayscaled image.
 
 返回灰度图片
 */
- (nullable UIImage *)imageByGrayscale;

/**
 Applies a blur effect to this image. Suitable for blur any content.
 返回一个添加模糊效果的图像
 */
- (nullable UIImage *)imageByBlurSoft;

/**
 Applies a blur effect to this image. Suitable for blur any content except pure white.
 (same as iOS Control Panel)
 对此图像应用模糊效果，适用于模糊除纯白色的任何图片
 */
- (nullable UIImage *)imageByBlurLight;

/**
 Applies a blur effect to this image. Suitable for displaying black text.
 (same as iOS Navigation Bar White)
 对此图像应用模糊效果，适合显示黑色文本
 */
- (nullable UIImage *)imageByBlurExtraLight;

/**
 Applies a blur effect to this image. Suitable for displaying white text.
 (same as iOS Notification Center)
 对此图像添加模糊效果，适合显示白色文本
 */
- (nullable UIImage *)imageByBlurDark;

/**
 Applies a blur and tint color to this image.
 
 使用指定颜色模糊图像
 
 @param tintColor  The tint color.
 */
- (nullable UIImage *)imageByBlurWithTint:(UIColor *)tintColor;

/**
 Applies a blur, tint color, and saturation adjustment to this image,
 optionally within the area specified by @a maskImage.
 
 @param blurRadius     The radius of the blur in points, 0 means no blur effect.
 
 @param tintColor      An optional UIColor object that is uniformly blended with
                       the result of the blur and saturation operations. The
                       alpha channel of this color determines how strong the
                       tint is. nil means no tint.
 
 @param tintBlendMode  The @a tintColor blend mode. Default is kCGBlendModeNormal (0).
 
 @param saturation     A value of 1.0 produces no change in the resulting image.
                       Values less than 1.0 will desaturation the resulting image
                       while values greater than 1.0 will have the opposite effect.
                       0 means gray scale.
 
 @param maskImage      If specified, @a inputImage is only modified in the area(s)
                       defined by this mask.  This must be an image mask or it
                       must meet the requirements of the mask parameter of
                       CGContextClipToMask.
 
 @return               image with effect, or nil if an error occurs (e.g. no
                       enough memory).
 */
- (nullable UIImage *)imageByBlurRadius:(CGFloat)blurRadius
                              tintColor:(nullable UIColor *)tintColor
                               tintMode:(CGBlendMode)tintBlendMode
                             saturation:(CGFloat)saturation
                              maskImage:(nullable UIImage *)maskImage;

@end

NS_ASSUME_NONNULL_END
