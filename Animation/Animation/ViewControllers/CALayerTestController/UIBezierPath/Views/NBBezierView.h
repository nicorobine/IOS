//
//  NBBezierView.h
//  Animation
//
//  Created by NicoRobine on 2018/3/28.
//  Copyright © 2018年 dreamdreamdream. All rights reserved.
//

/**
 ***************---这里是对UIBezierPath类的说明---***************
 #mark - 形状
 // 初始化贝塞尔曲线(无形状)
 + (instancetype)bezierPath;
 // 绘制矩形贝塞尔曲线
 + (instancetype)bezierPathWithRect:(CGRect)rect;
 // 绘制椭圆（圆形）曲线
 + (instancetype)bezierPathWithOvalInRect:(CGRect)rect;
 // 绘制含有圆角的贝塞尔曲线
 + (instancetype)bezierPathWithRoundedRect:(CGRect)rect cornerRadius:(CGFloat)cornerRadius;
 // 绘制可选择圆角方位的贝塞尔曲线
 + (instancetype)bezierPathWithRoundedRect:(CGRect)rect byRoundingCorners:(UIRectCorner)corners cornerRadii:(CGSize)cornerRadii;
 // 绘制圆弧曲线
 + (instancetype)bezierPathWithArcCenter:(CGPoint)center radius:(CGFloat)radius startAngle:(CGFloat)startAngle endAngle:(CGFloat)endAngle clockwise:(BOOL)clockwise;
 //根据CGPathRef绘制贝塞尔曲线
 + (instancetype)bezierPathWithCGPath:(CGPathRef)CGPath;
 
 #mark - 位置和线
 // 贝塞尔曲线开始的点
 - (void)moveToPoint:(CGPoint)point;
 //添加直线到该点
 - (void)addLineToPoint:(CGPoint)point;
 // 添加二次曲线到该点
 - (void)addCurveToPoint:(CGPoint)endPoint controlPoint1:(CGPoint)controlPoint1 controlPoint2:(CGPoint)controlPoint2;
 // 添加曲线到该点
 - (void)addQuadCurveToPoint:(CGPoint)endPoint controlPoint:(CGPoint)controlPoint;
 // 添加圆弧 注:上一个点会以直线的形式连接到圆弧的起点
 - (void)addArcWithCenter:(CGPoint)center radius:(CGFloat)radius startAngle:(CGFloat)startAngle endAngle:(CGFloat)endAngle clockwise:(BOOL)clockwise NS_AVAILABLE_IOS(4_0);
 //闭合曲线
 - (void)closePath;
 
 //去掉所有曲线点
 - (void)removeAllPoints;
 //边框宽度
 @property(nonatomic) CGFloat lineWidth;
 //端点类型
 @property(nonatomic) CGLineCap lineCapStyle;
 //线条连接类型
 @property(nonatomic) CGLineJoin lineJoinStyle;
 typedef CF_ENUM(int32_t, CGLineJoin) {
 kCGLineJoinMiter, // 线条连接处为非交叉部分不stroke
 kCGLineJoinRound, // 线条连接处为圆角
 kCGLineJoinBevel  // 线条连接处为两条线覆盖的区域都stroke
 };

 // 最大斜接长度 斜接长度指的是在两条线交汇处内角和外角之间的距离
 @property(nonatomic) CGFloat miterLimit;
 //虚线类型
 - (void)setLineDash:(nullable const CGFloat *)pattern count:(NSInteger)count phase:(CGFloat)phase;
 //填充贝塞尔曲线内部
 - (void)fill;
 //绘制贝塞尔曲线边框
 - (void)stroke;
 
 作者：CornBallast
 链接：https://www.jianshu.com/p/31092016d22c
 來源：简书
 著作权归作者所有。商业转载请联系作者获得授权，非商业转载请注明出处。
 */

#import <UIKit/UIKit.h>

@interface NBBezierView : UIView

@end
