//
//  UIView+NBTransform.h
//  Animation
//
//  Created by NicoRobine on 2018/5/4.
//  Copyright © 2018年 dreamdreamdream. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIView (NBTransform) <CAAnimationDelegate>

- (void)nbTransform_circleColor_toColor:(UIColor *)toColor duration:(CGFloat)duration startPoint:(CGPoint)startPoint;

- (void)nbTransform_circleImage_toImage:(UIImage *)toImage duration:(CGFloat)duration startPoint:(CGPoint)startPoint;

- (void)nbTransform_beginZoom_max:(CGFloat)max min:(CGFloat)min;
- (void)nbTransform_stopZoom;
@end
