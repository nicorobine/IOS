//
//  UIView+NBTransform.m
//  Animation
//
//  Created by NicoRobine on 2018/5/4.
//  Copyright © 2018年 dreamdreamdream. All rights reserved.
//

#import "UIView+NBTransform.h"
#import <objc/runtime.h>

const NSString* tempKey = @"nbtransfrom_temp_key";
const NSString* nextAniStop = @"next_animation_stop";

@implementation UIView (NBTransform)

- (void)nbTransform_circleColor_toColor:(UIColor *)toColor duration:(CGFloat)duration startPoint:(CGPoint)startPoint
{
    CALayer *tempLayer = objc_getAssociatedObject(self, &tempKey);
    
    if (!tempLayer) {
        
        tempLayer = [CALayer layer];
        tempLayer.bounds = self.bounds;
        tempLayer.position = self.center;
        tempLayer.backgroundColor = self.backgroundColor.CGColor;
        [self.layer addSublayer:tempLayer];
        objc_setAssociatedObject(self, &tempKey, tempLayer, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    
    tempLayer.contents = nil;
    tempLayer.backgroundColor = toColor.CGColor;
    
    CGFloat height = self.bounds.size.height;
    CGFloat width = self.bounds.size.width;
    
    UIBezierPath* startPath = [UIBezierPath bezierPathWithOvalInRect:CGRectMake(startPoint.x, startPoint.y, 2, 2)];
    UIBezierPath* endPath = [UIBezierPath bezierPathWithArcCenter:startPoint radius:sqrt(height*height+width*width) startAngle:0 endAngle:M_PI*2 clockwise:YES];
    
    CAShapeLayer* maskLayer = [CAShapeLayer new];
    maskLayer.path = endPath.CGPath;
    tempLayer.mask = maskLayer;
    
    CABasicAnimation* animation = [CABasicAnimation animationWithKeyPath:@"path"];
    animation.delegate = self;
    animation.fromValue = (__bridge id)startPath.CGPath;
    animation.toValue = (__bridge id)endPath.CGPath;
    animation.duration = 1;
    animation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
    [animation setValue:@"NBCircleColor_value" forKey:@"NBCircleColor_key"];
    [maskLayer addAnimation:animation forKey:@"NBCircleColor"];
}

- (void)nbTransform_circleImage_toImage:(UIImage *)toImage duration:(CGFloat)duration startPoint:(CGPoint)startPoint
{
    CALayer *tempLayer = objc_getAssociatedObject(self, &tempKey);
    
    if (!tempLayer) {
        
        tempLayer = [CALayer layer];
        tempLayer.bounds = self.bounds;
        tempLayer.position = self.center;
        tempLayer.backgroundColor = self.backgroundColor.CGColor;
        [self.layer addSublayer:tempLayer];
        objc_setAssociatedObject(self, &tempKey, tempLayer, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    
    tempLayer.contents = (__bridge id)toImage.CGImage;
    
    CGFloat height = self.bounds.size.height;
    CGFloat width = self.bounds.size.width;
    
    UIBezierPath* startPath = [UIBezierPath bezierPathWithOvalInRect:CGRectMake(startPoint.x, startPoint.y, 2, 2)];
    UIBezierPath* endPath = [UIBezierPath bezierPathWithArcCenter:startPoint radius:sqrt(height*height+width*width) startAngle:0 endAngle:M_PI*2 clockwise:YES];
    
    CAShapeLayer* maskLayer = [CAShapeLayer new];
    maskLayer.path = endPath.CGPath;
    tempLayer.mask = maskLayer;
    
    CABasicAnimation* animation = [CABasicAnimation animationWithKeyPath:@"path"];
    animation.delegate = self;
    animation.fromValue = (__bridge id)startPath.CGPath;
    animation.toValue = (__bridge id)endPath.CGPath;
    animation.duration = 1;
    animation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
    [animation setValue:@"NBCircleImage_value" forKey:@"NBCircleImage_key"];
    [maskLayer addAnimation:animation forKey:@"NBCircleImage"];
}

- (void)nbTransform_beginZoom_max:(CGFloat)max min:(CGFloat)min
{
    [UIView animateWithDuration:0.3 animations:^{
        self.transform = CGAffineTransformMakeScale(max, max);
    } completion:^(BOOL finished) {
        [UIView animateWithDuration:0.3 animations:^{
            self.transform = CGAffineTransformMakeScale(min, min);
        } completion:^(BOOL finished) {
            NSNumber* nextStop = objc_getAssociatedObject(self, &nextAniStop);
            if ([nextStop boolValue]) {
                
                [UIView animateWithDuration:0.3 animations:^{
                    self.transform = CGAffineTransformMakeScale(1, 1);
                } completion:^(BOOL finished) {
                    self.transform = CGAffineTransformMakeScale(1, 1);
                    objc_setAssociatedObject(self, &nextAniStop, @(0), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
                }];
            } else {
                [self nbTransform_beginZoom_max:max min:min];
            }
        }];
    }];
}

- (void)nbTransform_stopZoom
{
    objc_setAssociatedObject(self, &nextAniStop, @(1), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

#pragma mark - delegate

#pragma mark CAAnimationDelegate

- (void)animationDidStop:(CAAnimation *)anim finished:(BOOL)flag
{
    if (flag) {
        
        CALayer* tempLayer = objc_getAssociatedObject(self, &tempKey);
        
        if ([anim valueForKey:@"NBCircleImage_key"]) {
            
            self.layer.contents = nil;
            self.backgroundColor = [UIColor colorWithCGColor:tempLayer.backgroundColor];
        }
        else if ([anim valueForKey:@"NBCircleColor_key"]) {
            
            self.layer.contents = tempLayer.contents;
        }
    }
}

@end
