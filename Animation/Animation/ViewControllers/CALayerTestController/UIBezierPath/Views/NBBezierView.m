//
//  NBBezierView.m
//  Animation
//
//  Created by NicoRobine on 2018/3/28.
//  Copyright © 2018年 dreamdreamdream. All rights reserved.
//

#import "NBBezierView.h"

@implementation NBBezierView

- (void)drawRect:(CGRect)rect
{
    // 矩形贝塞尔曲线
    UIBezierPath* bezierPath_Rect = [UIBezierPath bezierPathWithRect:CGRectMake(20, 20, 100, 100)];
    // 设置线宽
    bezierPath_Rect.lineWidth = 5.f;
    // 设置断点样式
    bezierPath_Rect.lineCapStyle = kCGLineCapButt;//kCGLineCapRound;kCGLineCapSquare;
    // 设置线交叉样式
    bezierPath_Rect.lineJoinStyle = kCGLineJoinMiter;//kCGLineJoinRound;//kCGLineJoinBevel;
//    bezierPath_Rect.miterLimit = 1;
    
    // 画线
    [bezierPath_Rect moveToPoint:CGPointMake(40, 40)];
    [bezierPath_Rect addLineToPoint:CGPointMake(80, 60)];
    [bezierPath_Rect addLineToPoint:CGPointMake(40, 80)];
    [bezierPath_Rect closePath];
    
    // 设置虚线模式
    CGFloat dash[] = {20.f, 1.f};
    [bezierPath_Rect setLineDash:dash count:2 phase:0];
    
    [bezierPath_Rect stroke];
    
    // 椭圆形（圆形）贝塞尔曲线
    UIBezierPath* bezierPath_oval = [UIBezierPath bezierPathWithOvalInRect:CGRectMake(150, 20, 80, 80)];
    bezierPath_oval.lineWidth = 10.f;
    [bezierPath_oval stroke];
    // 设置上下文颜色
    [[UIColor redColor] set];
    [bezierPath_oval fill];
    
    // 绘制圆角矩形
    UIBezierPath* bezierPath_RoundRect = [UIBezierPath bezierPathWithRoundedRect:CGRectMake(250, 20, 80, 80) cornerRadius:5.f];
    bezierPath_RoundRect.lineWidth = 10;
    [bezierPath_RoundRect stroke];
    [[UIColor greenColor] set];
    [bezierPath_RoundRect fill];
    
    // 回执可以指定圆角的矩形
    UIBezierPath* bezierPath_RoundRectCorners = [UIBezierPath bezierPathWithRoundedRect:CGRectMake(20, 140, 80, 80) byRoundingCorners:UIRectCornerTopLeft | UIRectCornerBottomRight cornerRadii:CGSizeMake(6.f, 6.f)];
    bezierPath_RoundRectCorners.lineWidth = 10.f;
    [bezierPath_RoundRectCorners stroke];
    [[UIColor purpleColor] set];
    [bezierPath_RoundRectCorners fill];
    
    // 绘制圆弧
    UIBezierPath* bezierPath_arc = [UIBezierPath bezierPathWithArcCenter:CGPointMake(170, 170) radius:25 startAngle:-M_PI_2 endAngle:M_PI_4*3 clockwise:YES];
    bezierPath_arc.lineWidth = 5;
    [bezierPath_arc stroke];
    [[UIColor lightGrayColor] set];
    [bezierPath_arc closePath];
    [bezierPath_arc fill];
    
    // 添加二次、三次被塞尔曲线
    UIBezierPath* bezierPath = [UIBezierPath bezierPath];
    bezierPath.lineWidth = 5.f;
    [bezierPath moveToPoint:CGPointMake(20, 370)];
    // 画直线
    [bezierPath addLineToPoint:CGPointMake(50, 380)];
    // 画一个控制点的曲线
    [bezierPath addQuadCurveToPoint:CGPointMake(100, 360) controlPoint:CGPointMake(70, 200)];
    // 画两个控制点的曲线
    [bezierPath addCurveToPoint:CGPointMake(200, 420) controlPoint1:CGPointMake(230, 340) controlPoint2:CGPointMake(140, 440)];
    // 画圆弧曲线
    [bezierPath addArcWithCenter:CGPointMake(250, 360) radius:100 startAngle:-M_PI_2 endAngle:M_PI_4 clockwise:YES];
    [bezierPath stroke];
    
    // 根据CGPath画线
    CGMutablePathRef path = CGPathCreateMutable();
    CGPathMoveToPoint(path, NULL, 20, 470);
    CGPathAddCurveToPoint(path, NULL, 80, 470, 180, 650, 220, 580);
    UIBezierPath* bezierPath_CGPath = [UIBezierPath bezierPathWithCGPath:path];
    bezierPath_CGPath.lineWidth = 3.f;
    [bezierPath_CGPath stroke];
    CGPathRelease(path);
    
    // 这里写一点动画
    CALayer* aniLayer = [CALayer layer];
    aniLayer.backgroundColor = [UIColor redColor].CGColor;
    aniLayer.position = CGPointMake(20, 370);
    aniLayer.bounds = CGRectMake(0, 0, 8, 8);
    aniLayer.cornerRadius = 5.f;
    [self.layer addSublayer:aniLayer];
    
    CAKeyframeAnimation* keyFrame = [CAKeyframeAnimation animationWithKeyPath:@"position"];
    keyFrame.repeatCount = NSIntegerMax;
    keyFrame.path = bezierPath.CGPath;
    keyFrame.duration = 10;
    keyFrame.beginTime = CACurrentMediaTime() + 1;
    [aniLayer addAnimation:keyFrame forKey:@"keyFrameAnimation"];
}

@end
