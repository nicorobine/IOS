//
//  NBExplicitAnimationViewController.m
//  Animation
//
//  Created by NicoRobine on 2019/1/10.
//  Copyright © 2019年 dreamdreamdream. All rights reserved.
//

#import "NBExplicitAnimationViewController.h"

@interface NBExplicitAnimationViewController () <CAAnimationDelegate>
@property (weak, nonatomic) IBOutlet UIView *colorView_1;

@property (nonatomic, strong) CALayer* layer_1;

@end

@implementation NBExplicitAnimationViewController

- (instancetype)init {
    if (self = [super init]) {
        self.edgesForExtendedLayout = UIRectEdgeNone;
    }
    return self;
}

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    if (self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil]) {
        self.edgesForExtendedLayout = UIRectEdgeNone;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self addLayer_1];
}

- (void)addLayer_1 {
    CALayer* layer = [CALayer layer];
    layer.frame = self.colorView_1.bounds;
    layer.backgroundColor = [UIColor redColor].CGColor;
    [self.colorView_1.layer addSublayer:layer];
    self.layer_1 = layer;
}

- (void)changeColor:(CALayer *)layer {
    
    layer.backgroundColor = [self getRandomColor].CGColor;
}

- (UIColor *)getRandomColor {
    CGFloat red = arc4random()/(CGFloat)INT_MAX;
    CGFloat green = arc4random()/(CGFloat)INT_MAX;
    CGFloat blue = arc4random()/(CGFloat)INT_MAX;
    return [UIColor colorWithRed:red green:green blue:blue alpha:1];
}

- (CABasicAnimation *)getLayer_1Animation {
    CABasicAnimation *animation = [CABasicAnimation animation];
    animation.keyPath = @"backgroundColor";
    animation.toValue = (__bridge id)[self getRandomColor].CGColor;
    animation.delegate = self;
    return animation;
}

#pragma mark - Actions

- (IBAction)changeColor {
    
    [self.layer_1 addAnimation:[self getLayer_1Animation] forKey:nil];
}


#pragma mark - Delegate

- (void)animationDidStart:(CAAnimation *)anim {
    
}

- (void)animationDidStop:(CABasicAnimation *)anim finished:(BOOL)flag {
    // 如果不在代理里面设置最终颜色，动画过后还会还原到原来的颜色
    [CATransaction begin];
    [CATransaction setDisableActions:YES];
    self.layer_1.backgroundColor = (__bridge CGColorRef)anim.toValue;
    [CATransaction commit];
}

@end
