/*
 * This file is part of the SDWebImage package.
 * (c) Olivier Poitrey <rs@dailymotion.com>
 *
 * For the full copyright and license information, please view the LICENSE
 * file that was distributed with this source code.
 */

#import <Foundation/Foundation.h>
#import "SDWebImageCompat.h"

@interface SDWebImageFrame : NSObject

// This class is used for creating animated images via `animatedImageWithFrames` in `SDWebImageCoderHelper`. Attention if you need to specify animated images loop count, use `sd_imageLoopCount` property in `UIImage+MultiFormat`.

// wwt 该类用于通过“SDWebImageCoderHelper”中的`animatedImageWithFrames`创建动画图像。 注意，如果您需要指定动画图像循环计数，请在`UIImage + MultiFormat`中使用`sd_imageLoopCount`属性。

/**
 wwt 当前帧的图像，不能设置成一个动画图像
 The image of current frame. You should not set an animated image.
 */
@property (nonatomic, strong, readonly, nonnull) UIImage *image;
/**
 wwt 当前帧显示的时间长度，以秒为单位，不能设为0
 
 The duration of current frame to be displayed. The number is seconds but not milliseconds. You should not set this to zero.
 */
@property (nonatomic, readonly, assign) NSTimeInterval duration;

/**
 wwt 使用指定的图像和帧长度创建一个实例对象
 
 Create a frame instance with specify image and duration

 @param image current frame's image
 @param duration current frame's duration
 @return frame instance
 */
+ (instancetype _Nonnull)frameWithImage:(UIImage * _Nonnull)image duration:(NSTimeInterval)duration;

@end
