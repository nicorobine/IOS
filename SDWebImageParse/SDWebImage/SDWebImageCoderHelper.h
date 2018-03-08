/*
 * This file is part of the SDWebImage package.
 * (c) Olivier Poitrey <rs@dailymotion.com>
 *
 * For the full copyright and license information, please view the LICENSE
 * file that was distributed with this source code.
 */

#import <Foundation/Foundation.h>
#import "SDWebImageCompat.h"
#import "SDWebImageFrame.h"

@interface SDWebImageCoderHelper : NSObject

/**
 wwt 根据帧数组返回一个动画图像
 对于UIKit 会使用这个补丁创建一个动画图像。因为UIImage提供的+[UIImage animatedImageWithImages:duration:]方法只能用每个图像持续时间的平均值。所以当帧持续时间不同的时候就不好使了。因此这里重复帧指定的时间进行工作
 对于AppKit NSImage只支持GIF格式的图片。这个放回会试着将帧编码为GIF格式，然后创建一个用于渲染的动画NSImage对象。需要注意的是如果帧包含完整的Alpha通道，动画图像可能会丢失一些细节，因为GIF格式的图像只支持1位的alpha通道
 Return an animated image with frames array.
 For UIKit, this will apply the patch and then create animated UIImage. The patch is because that `+[UIImage animatedImageWithImages:duration:]` just use the average of duration for each image. So it will not work if different frame has different duration. Therefore we repeat the specify frame for specify times to let it work.
 For AppKit, NSImage does not support animates other than GIF. This will try to encode the frames to GIF format and then create an animated NSImage for rendering. Attention the animated image may loss some detail if the input frames contain full alpha channel because GIF only supports 1 bit alpha channel. (For 1 pixel, either transparent or not)

 @param frames The frames array. If no frames or frames is empty, return nil
 @return A animated image for rendering on UIImageView(UIKit) or NSImageView(AppKit)
 */
+ (UIImage * _Nullable)animatedImageWithFrames:(NSArray<SDWebImageFrame *> * _Nullable)frames;

/**
 Return frames array from an animated image.
 For UIKit, this will unapply the patch for the description above and then create frames array. This will also work for normal animated UIImage.
 For AppKit, NSImage does not support animates other than GIF. This will try to decode the GIF imageRep and then create frames array.

 @param animatedImage A animated image. If it's not animated, return nil
 @return The frames array
 */
+ (NSArray<SDWebImageFrame *> * _Nullable)framesFromAnimatedImage:(UIImage * _Nullable)animatedImage;

#if SD_UIKIT || SD_WATCH
/**
 Convert an EXIF image orientation to an iOS one.

 @param exifOrientation EXIF orientation
 @return iOS orientation
 */
+ (UIImageOrientation)imageOrientationFromEXIFOrientation:(NSInteger)exifOrientation;
/**
 Convert an iOS orientation to an EXIF image orientation.

 @param imageOrientation iOS orientation
 @return EXIF orientation
 */
+ (NSInteger)exifOrientationFromImageOrientation:(UIImageOrientation)imageOrientation;
#endif

@end
