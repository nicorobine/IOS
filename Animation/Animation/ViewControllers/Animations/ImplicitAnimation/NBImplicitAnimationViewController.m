//
//  NBImplicitAnimationViewController.m
//  Animation
//
//  Created by NicoRobine on 2019/1/9.
//  Copyright © 2019年 dreamdreamdream. All rights reserved.
//

#import "NBImplicitAnimationViewController.h"

@interface NBImplicitAnimationViewController ()
@property (weak, nonatomic) IBOutlet UIView *colorView1;
@property (weak, nonatomic) IBOutlet UIView *colorView2;
@property (weak, nonatomic) IBOutlet UIView *colorView3;

@property (strong, nonatomic) CALayer *colorLayer1;
@property (strong, nonatomic) CALayer *colorLayer2;
@property (strong, nonatomic) CALayer *colorLayer3;
@property (strong, nonatomic) CALayer *colorLayer4;

@end

@implementation NBImplicitAnimationViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self addLayer1];
    [self addLayer2];
    [self addLayer3];
    [self addLayer4];
}

- (void)addLayer1 {
    CALayer* layer = [CALayer layer];
    layer.frame = self.colorView1.bounds;
    layer.backgroundColor = [UIColor blueColor].CGColor;
    [self.colorView1.layer addSublayer:layer];
    self.colorLayer1 = layer;
}

- (void)addLayer2 {
    CALayer* layer = [CALayer layer];
    layer.frame = self.colorView2.bounds;
    layer.backgroundColor = [UIColor blueColor].CGColor;
    [self.colorView2.layer addSublayer:layer];
    self.colorLayer2 = layer;
}

- (void)addLayer3 {
    CALayer* layer = [CALayer layer];
    layer.frame = self.colorView3.bounds;
    layer.backgroundColor = [UIColor blueColor].CGColor;
    [self.colorView3.layer addSublayer:layer];
    self.colorLayer3 = layer;
    
    CATransition *transition = [CATransition animation];
    transition.type = kCATransitionPush;
    transition.subtype = kCATransitionFromLeft;
    self.colorLayer3.actions = @{@"backgroundColor":transition};
}

- (void)addLayer4 {
    CALayer *layer = [CALayer layer];
    self.colorLayer4 = layer;
    CGRect frame = self.colorView3.frame;
    layer.frame = CGRectMake(CGRectGetMaxX(frame) + 20, CGRectGetMinY(frame), frame.size.width, frame.size.height);
    layer.backgroundColor = [UIColor redColor].CGColor;
    [self.view.layer addSublayer:layer];
}

- (void)_changeColorWithLayer:(CALayer *)layer {
    CGFloat red = arc4random()/(CGFloat)INT_MAX;
    CGFloat green = arc4random()/(CGFloat)INT_MAX;
    CGFloat blue = arc4random()/(CGFloat)INT_MAX;
    layer.backgroundColor = [UIColor colorWithRed:red green:green blue:blue alpha:1].CGColor;
}

- (IBAction)changeColor1 {
    [self _changeColorWithLayer:self.colorLayer1];
}
- (IBAction)changeColor2 {
    [CATransaction begin];
    [CATransaction setAnimationDuration:2];
    [CATransaction setCompletionBlock:^{
        CATransform3D transform = self.colorLayer2.transform;
        transform = CATransform3DRotate(transform, M_PI_4, 0, 0, 1);
        self.colorLayer2.transform = transform;
    }];
    [self _changeColorWithLayer:self.colorLayer2];
    [CATransaction commit];
}
- (IBAction)changeColor3 {
    
    [self _changeColorWithLayer:self.colorLayer3];
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    CGPoint point = [[touches anyObject] locationInView:self.view];
    
    // colorLayer4的frame会在设置point的一瞬间，改为point的位置，在动画执行过程中一直都是这个frame不会改变
    // 当时colorLayer4有一个中间的呈现图层（presentationLayer）显示的是动画阶段的实际frame
    // 所以如果使用colorLayer4的hitTest:点击移动后，在移动过程中点击最后要移动的位置会改变颜色，而且点击最后移动位置的区域不会再触发移动
    // 而使用colorLayer4.presentationLayer的hitTest:可以检测到实时的位置，在移动过程中点击layer会改变颜色
//    if ([self.colorLayer4 hitTest:point]) {
    if ([self.colorLayer4.presentationLayer hitTest:point]) {
        [self _changeColorWithLayer:self.colorLayer4];
    } else {
        [CATransaction begin];
        [CATransaction setAnimationDuration:3];
        self.colorLayer4.position = point;
        [CATransaction commit];
    }
}

@end
