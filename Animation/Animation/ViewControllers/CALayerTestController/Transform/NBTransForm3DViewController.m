//
//  NBTransForm3DViewController.m
//  Animation
//
//  Created by NicoRobine on 2018/4/2.
//  Copyright © 2018年 dreamdreamdream. All rights reserved.
//

/**
 CATransform3D 是一个奇次三维变换矩阵
 原型:
 struct CATransform3D
 {
 CGFloat m11, m12, m13, m14;
 CGFloat m21, m22, m23, m24;
 CGFloat m31, m32, m33, m34;
 CGFloat m41, m42, m43, m44;
 };
 
 个参数的意思
 m11 : 以XY轴中心为中心，随着m11值由 1-->0 变小，图像向X轴中心压缩；随着m11值由 1-->MAX 变大，图像以X轴中心向外拉伸图像。
 m12 : 以XY轴中心为中心，随着m12值由 0-->MAX 变大，图像顺时针方向在Y轴，做切变。随着m12值由 0-->MIN 变小，图像逆时针方向在Y轴，做切变。
 名词介绍：
 切变：两个距离很近、大小相等、方向相反的平行力作用于同一物体上所引起的形变。
 m13 : 以X轴为中心的垂直线为界限，如果m13>0图像的左边将会被切掉 ; m13<0 图像的右边边将会被切掉。
 m14 :以X轴为中心的垂直线为界限，随着m14值由 0-->MAX 变大，图像左侧向Z轴翻转，并做拉伸。随着m14值由 0-->MIN 变小，图像右边向Z轴翻转，做拉伸。
 
 m21 :以XY轴中心为中心，随着m21值由 0-->MAX 变大，图像顺时针方向在X轴，做切变。随着m21值由 0-->MIN 变小，图像逆时针方向在X轴，做切变。
 m22 : 以XY轴中心为中心，随着m22值由 1-->0 变小，图像向Y轴中心压缩；随着m22值由 1-->MAX 变大，图像以Y轴中心向外拉伸图像。
 m23 : 以Y轴为中心的垂直线为界限，如果m23>0图像的上边将会被切掉 ; m23<0 图像的下边边将会被切掉。
 m24 :以Y轴为中心的垂直线为界限，随着m24值由 0-->MAX 变大，图像上面向Z轴翻转，并做拉伸。随着m24值由 0-->MIN 变小，图像下面边向Z轴翻转，并做拉伸。
 m31:和m13一起决定y轴的旋转
 m32:和m23一起决定x轴的旋转
 m33:z轴方向进行缩放
 m34:透视效果m34= -1/D，D越小，透视效果越明显，必须在有旋转效果的前提下，才会看到透视效果
 m41 : 让图像沿着X轴左右平移。m41>0 ，向右平移；m41<0 ，向左平移。
 m42 : 让图像沿着Y轴上下平移。m42>0 ，向上平移；m41<0 ，向下平移。
 m43 : 让图像沿着Z轴上下平移。m43>0 ，向上平移；m43<0 ，向下平移。
 m44 : 图像的放大和缩小，当m44 由 MAX --> 0 放大；0--> 缩小。
 */

#import "NBTransForm3DViewController.h"

@interface NBTransForm3DViewController ()
@property (weak, nonatomic) IBOutlet UIScrollView *scrollView;
@property (weak, nonatomic) IBOutlet UILabel *valueLabel;
@property (weak, nonatomic) IBOutlet UISlider *m11Slider;
@property (weak, nonatomic) IBOutlet UISlider *m12Slider;
@property (weak, nonatomic) IBOutlet UISlider *m13Slider;
@property (weak, nonatomic) IBOutlet UISlider *m14Slider;

@property (weak, nonatomic) IBOutlet UISlider *m21Slider;
@property (weak, nonatomic) IBOutlet UISlider *m22Slider;
@property (weak, nonatomic) IBOutlet UISlider *m23Slider;
@property (weak, nonatomic) IBOutlet UISlider *m24Slider;

@property (weak, nonatomic) IBOutlet UISlider *m31Slider;
@property (weak, nonatomic) IBOutlet UISlider *m32;
@property (weak, nonatomic) IBOutlet UISlider *m33Slider;
@property (weak, nonatomic) IBOutlet UISlider *m34Slider;

@property (weak, nonatomic) IBOutlet UISlider *m41Slider;
@property (weak, nonatomic) IBOutlet UISlider *m42Slider;
@property (weak, nonatomic) IBOutlet UISlider *m43Slider;
@property (weak, nonatomic) IBOutlet UISlider *m44Slider;
@property (weak, nonatomic) IBOutlet UIImageView *testImageView;

@property (strong, nonatomic) UIView *containerView;
@property (nonatomic, strong) CALayer* imgLayer;
@property (nonatomic, strong) CALayer* imgLayer1;

@property (nonatomic, assign) CATransform3D baseTransform;

@property (nonatomic, assign) CATransform3D autoTransform;
@end

@implementation NBTransForm3DViewController

#pragma mark - life cycle

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.baseTransform = CATransform3DIdentity;
    self.autoTransform = CATransform3DIdentity;
    
    self.scrollView.contentSize = CGSizeMake(self.view.bounds.size.width, self.view.bounds.size.height*2);
    self.scrollView.showsVerticalScrollIndicator = YES;
    
    UIBarButtonItem* rightItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemRefresh target:self action:@selector(reset)];
    
    self.navigationItem.rightBarButtonItem = rightItem;
    
    self.testImageView.layer.transform = self.baseTransform;
    
    [self.scrollView addSubview:self.containerView];
}

#pragma mark - Actions

- (IBAction)m11Changed:(UISlider *)sender {
    CATransform3D transform = self.baseTransform;
    transform.m11 = sender.value;
    self.baseTransform = transform;
    self.testImageView.layer.transform = transform;
    self.title = [NSString stringWithFormat:@"m11:%g",sender.value];
}
- (IBAction)m12Changed:(UISlider *)sender {
    CATransform3D transform = self.baseTransform;
    transform.m12 = sender.value;
    self.baseTransform = transform;
    self.testImageView.layer.transform = transform;
    self.title = [NSString stringWithFormat:@"m12:%g",sender.value];
}
- (IBAction)m13Changed:(UISlider *)sender {
    CATransform3D transform = self.baseTransform;
    transform.m13 = sender.value;
    self.baseTransform = transform;
    self.testImageView.layer.transform = transform;
    self.title = [NSString stringWithFormat:@"m13:%g",sender.value];
}
- (IBAction)m14Changed:(UISlider *)sender {
    CATransform3D transform = self.baseTransform;
    transform.m14 = sender.value;
    self.baseTransform = transform;
    self.testImageView.layer.transform = transform;
    self.title = [NSString stringWithFormat:@"m14:%g",sender.value];
}

- (IBAction)m21Changed:(UISlider *)sender {
    CATransform3D transform = self.baseTransform;
    transform.m21 = sender.value;
    self.baseTransform = transform;
    self.testImageView.layer.transform = transform;
    self.title = [NSString stringWithFormat:@"m21:%g",sender.value];
}
- (IBAction)m22Changed:(UISlider *)sender {
    CATransform3D transform = self.baseTransform;
    transform.m22 = sender.value;
    self.baseTransform = transform;
    self.testImageView.layer.transform = transform;
    self.title = [NSString stringWithFormat:@"m22:%g",sender.value];
}
- (IBAction)m23Changed:(UISlider *)sender {
    CATransform3D transform = self.baseTransform;
    transform.m23 = sender.value;
    self.baseTransform = transform;
    self.testImageView.layer.transform = transform;
    self.title = [NSString stringWithFormat:@"m23:%g",sender.value];
}
- (IBAction)m24Changed:(UISlider *)sender {
    CATransform3D transform = self.baseTransform;
    transform.m24 = sender.value;
    self.baseTransform = transform;
    self.testImageView.layer.transform = transform;
    self.title = [NSString stringWithFormat:@"m24:%g",sender.value];
}

- (IBAction)m31Changed:(UISlider *)sender {
    CATransform3D transform = self.baseTransform;
    transform.m31 = sender.value;
    self.baseTransform = transform;
    self.testImageView.layer.transform = transform;
    self.title = [NSString stringWithFormat:@"m31:%g",sender.value];
}
- (IBAction)m32Changed:(UISlider *)sender {
    CATransform3D transform = self.baseTransform;
    transform.m32 = sender.value;
    self.baseTransform = transform;
    self.testImageView.layer.transform = transform;
    self.title = [NSString stringWithFormat:@"m32:%g",sender.value];
}
- (IBAction)m33Changed:(UISlider *)sender {
    CATransform3D transform = self.baseTransform;
    transform.m33 = sender.value;
    self.baseTransform = transform;
    self.testImageView.layer.transform = transform;
    self.title = [NSString stringWithFormat:@"m33:%g",sender.value];
}
- (IBAction)m34Changed:(UISlider *)sender {
    CATransform3D transform = self.baseTransform;
    transform.m34 = sender.value;
    self.baseTransform = transform;
    self.testImageView.layer.transform = transform;
    self.title = [NSString stringWithFormat:@"m34:%g",sender.value];
}
- (IBAction)m41Changed:(UISlider *)sender {
    CATransform3D transform = self.baseTransform;
    transform.m41 = sender.value;
    self.baseTransform = transform;
    self.testImageView.layer.transform = transform;
    self.title = [NSString stringWithFormat:@"m41:%g",sender.value];
}
- (IBAction)m42Changed:(UISlider *)sender {
    CATransform3D transform = self.baseTransform;
    transform.m42 = sender.value;
    self.baseTransform = transform;
    self.testImageView.layer.transform = transform;
    self.title = [NSString stringWithFormat:@"m42:%g",sender.value];
}
- (IBAction)m43Slider:(UISlider *)sender {
    CATransform3D transform = self.baseTransform;
    transform.m43 = sender.value;
    self.baseTransform = transform;
    self.testImageView.layer.transform = transform;
    self.title = [NSString stringWithFormat:@"m43:%g",sender.value];
}
- (IBAction)m44Changed:(UISlider *)sender {
    CATransform3D transform = self.baseTransform;
    transform.m44 = sender.value;
    self.baseTransform = transform;
    self.testImageView.layer.transform = transform;
    self.title = [NSString stringWithFormat:@"m44:%g",sender.value];
}

- (void)reset{
    self.testImageView.layer.transform = CATransform3DIdentity;
    for (UIView*view in self.scrollView.subviews) {
        if (view.subviews.count > 0) {
            for (UIView*temp in view.subviews) {
                if ([temp isKindOfClass:[UISlider class]]) {
                    ((UISlider *)temp).value = (((UISlider *)temp).maximumValue + ((UISlider *)temp).minimumValue)/2;
                }
            }
        }
    }
}

- (void)start {
    static NSUInteger time = 1;
    dispatch_source_t timer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, dispatch_get_main_queue());
    dispatch_source_set_timer(timer, DISPATCH_TIME_NOW, 2 * NSEC_PER_SEC, 0 * NSEC_PER_SEC);
    dispatch_source_set_event_handler(timer, ^{
        if (time == 3) {
            dispatch_cancel(timer);
            return;
        }
        [self performSelector:NSSelectorFromString([NSString stringWithFormat:@"transform_3D_%lu", time++])];
        
    });
    dispatch_resume(timer);
}

#pragma mark - Test

- (void)transform_3D_1{
    self.autoTransform = CATransform3DRotate(self.autoTransform, M_PI_4, 0, 1, 0);
    self.imgLayer.transform = self.autoTransform;
}

- (void)transform_3D_2{
    
    CATransform3D transform = self.autoTransform;
    // 通常在-1.0/500和-1.0/1000之间
    transform.m34 = -1.0/500;
    self.autoTransform = transform;
    self.imgLayer.transform = transform;
}
- (void)transform_3D_3:(UIButton *)sender {
    
    // containerView的所有子layer应用的转换
    CATransform3D transfrom = CATransform3DIdentity;
    transfrom.m34 = -1.0/500;
    self.containerView.layer.sublayerTransform = transfrom;
    
    CATransform3D transform1 = CATransform3DMakeRotation(M_PI_4, 0, 1, 0);
    self.imgLayer.transform = transform1;
    CATransform3D transfrom2 = CATransform3DMakeRotation(-M_PI_4, 0, 1, 0);
    self.imgLayer1.transform = transfrom2;
}

// 测试layer是否绘制背面
- (void)transform_3D_4:(id)sender {
    
    self.imgLayer.transform = CATransform3DMakeRotation(M_PI, 0, 1, 0);
    self.imgLayer1.transform = CATransform3DMakeRotation(M_PI, 0, 1, 0);
}

#pragma mark - getter

- (UIView *)containerView
{
    if (!_containerView) {
        _containerView = [[UIView alloc] initWithFrame:CGRectMake(8, self.view.bounds.size.height, self.view.bounds.size.width-16, self.view.bounds.size.height/2)];
        _containerView.backgroundColor = [UIColor colorWithWhite:0.9 alpha:1];
        _containerView.layer.cornerRadius = 6.f;
        [_containerView.layer addSublayer:self.imgLayer];
        [_containerView.layer addSublayer:self.imgLayer1];
        UIButton* startBtn = [[UIButton alloc] initWithFrame:CGRectMake(60, _containerView.bounds.size.height- 60, _containerView.bounds.size.width - 120, 44)];
        startBtn.backgroundColor = [UIColor purpleColor];
        startBtn.titleLabel.text = @"Start";
        startBtn.titleLabel.textColor = [UIColor whiteColor];
        [startBtn addTarget:self action:@selector(start) forControlEvents:UIControlEventTouchUpInside];
        [_containerView addSubview:startBtn];
    }
    return _containerView;
}

- (CALayer *)imgLayer
{
    if (!_imgLayer) {
        _imgLayer = [CALayer layer];
        _imgLayer.contentsGravity = kCAGravityResizeAspect;
        _imgLayer.bounds = CGRectMake(0, 0, 100, 100);
        _imgLayer.position = CGPointMake(120, 80);
        _imgLayer.contents = (__bridge id)[UIImage imageNamed:@"img1"].CGImage;
        _imgLayer.doubleSided = YES;
    }
    return _imgLayer;
}

- (CALayer *)imgLayer1
{
    if (!_imgLayer1) {
        _imgLayer1 = [CALayer layer];
        _imgLayer1.contentsGravity = kCAGravityResizeAspect;
        _imgLayer1.bounds = CGRectMake(0, 0, 100, 100);
        _imgLayer1.position = CGPointMake(220, 80);
        _imgLayer1.contents = (__bridge id)[UIImage imageNamed:@"img1"].CGImage;
        _imgLayer1.doubleSided = NO;
    }
    return _imgLayer1;
}

@end
