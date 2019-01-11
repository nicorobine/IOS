//
//  NBTransformSolidViewController.m
//  Animation
//
//  Created by NicoRobine on 2018/4/16.
//  Copyright © 2018年 dreamdreamdream. All rights reserved.
//

#import "NBTransformSolidViewController.h"
#import <GLKit/GLKit.h>

#define LIGHT_DIRECTION 0, 1, -0.5
#define AMBIENT_LIGHT 0.5

@interface NBTransformSolidViewController ()

@property (nonatomic, strong) UIView* view1;
@property (nonatomic, strong) UIView* view2;
@property (nonatomic, strong) UIView* view3;
@property (nonatomic, strong) UIView* view4;
@property (nonatomic, strong) UIView* view5;
@property (nonatomic, strong) UIView* view6;

@property (nonatomic, strong) NSArray* views;

@property (weak, nonatomic) IBOutlet UIView *containerView;

@property (assign, nonatomic) CGPoint viewCenter;

@end

@implementation NBTransformSolidViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self addTransformOfViews];
}

#pragma mark - private methods

// 为view添加变换
- (void)addTransformOfViews {
    
    CATransform3D transfrom = CATransform3DIdentity;
    // 视角距离屏幕距离设为500像素
    transfrom.m34 = -1.0/500;
    // 向下旋转45度
    transfrom = CATransform3DRotate(transfrom, -M_PI_4, 1, 0, 0);
    // 向左旋转45度
    transfrom = CATransform3DRotate(transfrom, -M_PI_4, 0, 1, 0);
    // 子视图也应用转换
    self.containerView.layer.sublayerTransform = transfrom;
    
    [self _addButtons];
    
    for (int i = 0; i<self.views.count; i++) {
        [self _addface:i withTransform:[self _transfromOfIndex:i]];
    }
}

// 设置光亮和阴影
- (void)applyLightingToFace:(CALayer *)face
{
//    // 增加光亮图层
//    CALayer *layer = [CALayer layer];
//    layer.frame = face.bounds;
//    [face addSublayer:layer];
//
//    // 将face图层的仿射变换转换（transfrom）为矩阵（matrix）
//    // 注：GLKMatrix4和CATransfrom3D有相同的结构，但是坐标类型有长度区别
//    CATransform3D transform = face.transform;
//    // 因为结构相同，直接从地址取
//    GLKMatrix4 matrix4 = *(GLKMatrix4 *)&transform;
//    // 转换为3*3矩阵GLKMatrix3
//    GLKMatrix3 matrix3 = GLKMatrix4GetMatrix3(matrix4);
//    // 获取正常的向量
//    GLKVector3 normal = GLKVector3Make(0, 0, 1);
//    normal = GLKMatrix3MultiplyVector3(matrix3, normal);
//    normal = GLKVector3Normalize(normal);
//    // 用光方向获得点积
//    GLKVector3 light = GLKVector3Normalize(GLKVector3Make(LIGHT_DIRECTION));
//    float dotProduct = GLKVector3DotProduct(light, normal);
//
//    // 设置光亮图层的透明度
//    CGFloat shadow = 1+ dotProduct - AMBIENT_LIGHT;
//    UIColor *color = [UIColor colorWithWhite:0 alpha:shadow];
//    layer.backgroundColor = color.CGColor;
    
    //add lighting layer
    CALayer *layer = [CALayer layer];
    layer.frame = face.bounds;
    [face addSublayer:layer];
    //convert the face transform to matrix
    //(GLKMatrix4 has the same structure as CATransform3D)
    //译者注：GLKMatrix4和CATransform3D内存结构一致，但坐标类型有长度区别，所以理论上应该做一次float到CGFloat的转换，感谢[@zihuyishi](https://github.com/zihuyishi)同学~
    CATransform3D transform = face.transform;
    GLKMatrix4 matrix4 = *(GLKMatrix4 *)&transform;
    GLKMatrix3 matrix3 = GLKMatrix4GetMatrix3(matrix4);
    //get face normal
    GLKVector3 normal = GLKVector3Make(0, 0, 1);
    normal = GLKMatrix3MultiplyVector3(matrix3, normal);
    normal = GLKVector3Normalize(normal);
    //get dot product with light direction
    GLKVector3 light = GLKVector3Normalize(GLKVector3Make(LIGHT_DIRECTION));
    float dotProduct = GLKVector3DotProduct(light, normal);
    //set lighting layer opacity
    CGFloat shadow = 1 + dotProduct - AMBIENT_LIGHT;
    UIColor *color = [UIColor colorWithWhite:0 alpha:shadow];
    layer.backgroundColor = color.CGColor;
}

#pragma mark - Actions

-(void)buttonClicked:(UIButton*)button
{
    
}

#pragma mark - private methods

- (void)_addface:(NSInteger)index withTransform:(CATransform3D)transform
{
    UIView* face = self.views[index];
    [self.containerView addSubview:face];
    CGSize containerSize = self.containerView.frame.size;
    face.center = CGPointMake(containerSize.width/2, containerSize.height/2);
    face.layer.transform = transform;
    [self applyLightingToFace:face.layer];
}

- (CATransform3D)_transfromOfIndex:(NSInteger)index
{
    CATransform3D transform = CATransform3DIdentity;
    switch (index) {
        case 0:
            transform = CATransform3DTranslate(transform, 0, 0, 100);
            break;
        case 1:
            transform = CATransform3DTranslate(transform, 100, 0, 0);
            transform = CATransform3DRotate(transform, M_PI_2, 0, 1, 0);
            break;
        case 2:
            transform = CATransform3DTranslate(transform, 0, -100, 0);
            transform = CATransform3DRotate(transform, M_PI_2, 1, 0, 0);
            break;
        case 3:
            transform = CATransform3DTranslate(transform, 0, 100, 0);
            transform = CATransform3DRotate(transform, -M_PI_2, 1, 0, 0);
            break;
        case 4:
            transform = CATransform3DTranslate(transform, -100, 0, 0);
            transform = CATransform3DRotate(transform, -M_PI_2, 0, 1, 0);
            break;
        case 5:
            transform = CATransform3DTranslate(transform, 0, 0, -100);
            transform = CATransform3DRotate(transform, M_PI, 0, 1, 0);
            break;
            
        default:
            break;
    }
    return transform;
}

- (void)_addButtons
{
    for (int i = 0; i<self.views.count; i++) {
        [self _addButton:i];
    }
}

- (void)_addButton:(NSInteger)index
{
    UIView* face = self.views[index];
    UIButton *button = [self _createButtonAtIndex:index];
    CGSize faceSize = face.frame.size;
    button.center = CGPointMake(faceSize.width/2, faceSize.height/2);
    [face addSubview:button];
}

- (UIButton *)_createButtonAtIndex:(NSInteger)index
{
    UIButton* button = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 100, 100)];
    [button setBackgroundColor:[UIColor lightGrayColor]];
    [button setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    [button setTitle:[NSString stringWithFormat:@"%@", @(index+1)] forState:UIControlStateNormal];
    [button.layer setCornerRadius:6.f];
    return button;
}

#pragma mark - getter

- (NSArray *)views
{
    if (!_views) {
        _views = @[self.view1, self.view2, self.view3, self.view4, self.view5, self.view6];
    }
    return _views;
}


- (UIView *)view1
{
    if (!_view1) {
        _view1 = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 200, 200)];
        _view1.backgroundColor = [UIColor whiteColor];
    }
    return _view1;
}

- (UIView *)view2
{
    if (!_view2) {
        _view2 = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 200, 200)];
        _view2.backgroundColor = [UIColor whiteColor];
    }
    return _view2;
}

- (UIView *)view3
{
    if (!_view3) {
        _view3 = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 200, 200)];
        _view3.backgroundColor = [UIColor whiteColor];
    }
    return _view3;
}

- (UIView *)view4
{
    if (!_view4) {
        _view4 = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 200, 200)];
        _view4.backgroundColor = [UIColor whiteColor];
    }
    return _view4;
}

- (UIView *)view5
{
    if (!_view5) {
        _view5 = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 200, 200)];
        _view5.backgroundColor = [UIColor whiteColor];
    }
    return _view5;
}

- (UIView *)view6
{
    if (!_view6) {
        _view6 = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 200, 200)];
        _view6.backgroundColor = [UIColor whiteColor];
    }
    return _view6;
}

- (CGPoint)viewCenter
{
    return CGPointMake(self.containerView.bounds.size.width/2, self.containerView.bounds.size.height/2);
}

@end
