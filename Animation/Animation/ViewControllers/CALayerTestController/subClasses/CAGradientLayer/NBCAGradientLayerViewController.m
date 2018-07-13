//
//  NBCAGradientLayerViewController.m
//  Animation
//
//  Created by NicoRobine on 2018/5/4.
//  Copyright © 2018年 dreamdreamdream. All rights reserved.
//

#import "NBCAGradientLayerViewController.h"

@interface NBCAGradientLayerViewController ()

@property (nonatomic, strong) UIView *containerView1;
@property (nonatomic, strong) UIView *containerView2;

@property (nonatomic, strong) CAGradientLayer* lineGradientLayer;
@property (nonatomic, strong) CAGradientLayer* circleGrandientLayer;
@property (nonatomic, strong) CAShapeLayer* circleMask;

@property (nonatomic, strong) NSArray<UIColor *>* colors;
@property (nonatomic, strong) NSArray<NSNumber *>* locations;

@property (nonatomic, strong) dispatch_source_t timer;

@end

@implementation NBCAGradientLayerViewController

#pragma mark - life cycle

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.edgesForExtendedLayout = UIRectEdgeNone;
    
    [self.view addSubview:self.containerView1];
    [self.view addSubview:self.containerView2];
    
    [self.containerView1.layer addSublayer:self.lineGradientLayer];
    [self.containerView2.layer addSublayer:self.circleGrandientLayer];
    
    [self startTimer];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    
}

#pragma mark - private method

- (void)startTimer
{
    
    NSTimeInterval delayTime = 1.f;
    NSTimeInterval timeInterval = 1;
    dispatch_time_t startDelayTime = dispatch_time(DISPATCH_TIME_NOW, delayTime*NSEC_PER_SEC);
    dispatch_source_set_timer(self.timer, startDelayTime, (int64_t)timeInterval*NSEC_PER_SEC, 0.1*NSEC_PER_SEC);
    dispatch_source_set_event_handler(self.timer, ^{
       
        dispatch_async(dispatch_get_main_queue(), ^{
           
            if (self.circleMask.strokeEnd < 0.2) {
                self.circleMask.strokeEnd+=0.05;
            }
            else if (self.circleMask.strokeEnd < 0.5) {
                self.circleMask.strokeEnd+=0.2;
            }
            else if (self.circleMask.strokeEnd < 0.8) {
                self.circleMask.strokeEnd+=0.1;
            }
            else if (self.circleMask.strokeEnd < 1) {
                self.circleMask.strokeEnd = self.circleMask.strokeEnd+0.05>1?1:self.circleMask.strokeEnd+0.05;
            }
            else {
                dispatch_source_cancel(self.timer);
            }
        });
    });
    dispatch_resume(self.timer);
}

#pragma mark - getter

- (UIView *)containerView1
{
    if (!_containerView1) {
        
        _containerView1 = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width, 300)];
    }
    return _containerView1;
}

- (UIView *)containerView2
{
    if (!_containerView2) {
        
        _containerView2 = [[UIView alloc] initWithFrame:CGRectMake(0, 310, self.view.bounds.size.width, 300)];
    }
    return _containerView2;
}

- (NSArray<UIColor *> *)colors
{
    if (!_colors) {
        
        _colors = @[(__bridge id)[UIColor redColor].CGColor, (__bridge id)[UIColor orangeColor].CGColor, (__bridge id)[UIColor yellowColor].CGColor, (__bridge id)[UIColor greenColor].CGColor, (__bridge id)[UIColor blueColor].CGColor, (__bridge id)[UIColor purpleColor].CGColor];
    }
    return _colors;
}

- (NSArray *)locations
{
    if (!_locations) {
        
        CGFloat avg = 1.f/6;
        _locations = @[@(avg), @(avg*2), @(avg*3), @(avg*4), @(avg*5), @(avg*6)];
    }
    return _locations;
}

- (CAGradientLayer *)lineGradientLayer
{
    if (!_lineGradientLayer) {
        _lineGradientLayer = [CAGradientLayer layer];
        _lineGradientLayer.colors = self.colors;
        _lineGradientLayer.locations = self.locations;
        _lineGradientLayer.bounds = CGRectMake(0, 0, 300, 300);
        _lineGradientLayer.position = CGPointMake(150, 150);
        _lineGradientLayer.startPoint = CGPointMake(0, 0);
        _lineGradientLayer.endPoint = CGPointMake(0, 1);
    }
    return _lineGradientLayer;
}

- (CAGradientLayer *)circleGrandientLayer
{
    if (!_circleGrandientLayer) {
        
        // 创建渐变色layer
        _circleGrandientLayer = [CAGradientLayer new];
        _circleGrandientLayer.bounds = CGRectMake(0, 0, 200, 200);
        _circleGrandientLayer.position = CGPointMake(150, 150);
        _circleGrandientLayer.colors = self.colors;
        _circleGrandientLayer.locations = self.locations;
        _circleGrandientLayer.startPoint = CGPointMake(0, 0);
        _circleGrandientLayer.endPoint = CGPointMake(1, 1);
        _circleGrandientLayer.mask = self.circleMask;
    }
    return _circleGrandientLayer;
}

- (CAShapeLayer *)circleMask
{
    if (!_circleMask) {
        
        UIBezierPath* circlePath = [UIBezierPath bezierPathWithOvalInRect:CGRectMake(20, 20, 160, 160)];
        
        _circleMask = [CAShapeLayer new];
        _circleMask.path = circlePath.CGPath;
        _circleMask.fillColor = [UIColor clearColor].CGColor;
        _circleMask.strokeColor = [UIColor blueColor].CGColor;
        _circleMask.strokeStart = 0;
        _circleMask.strokeEnd = 0.1;
        _circleMask.lineWidth = 6;
        _circleMask.lineCap = kCALineCapRound;
    }
    return _circleMask;
}

- (dispatch_source_t)timer
{
    if (!_timer) {
        dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
        _timer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, queue);
    }
    return _timer;
}

@end
