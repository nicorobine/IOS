//
//  NBCAShapeLayerViewController.m
//  Animation
//
//  Created by NicoRobine on 2018/4/27.
//  Copyright © 2018年 dreamdreamdream. All rights reserved.
//

#import "NBCAShapeLayerViewController.h"
#import "UIView+NBTransform.h"

@interface NBCAShapeLayerViewController ()

@property (nonatomic, strong) UIScrollView *scrollView;

@property (nonatomic, strong) CAShapeLayer* matchstickManLayer;

@property(nonatomic, strong) CAShapeLayer* circleLayer;

@property(nonatomic, strong) CAShapeLayer* dashLineShapeLayer;

@property(nonatomic, strong) dispatch_source_t timer;

@end

@implementation NBCAShapeLayerViewController

#pragma mark - life cycle

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self.view addSubview:self.scrollView];
    
    [self.scrollView.layer addSublayer:self.matchstickManLayer];
    [self.scrollView.layer addSublayer:self.circleLayer];
    [self.scrollView.layer addSublayer:self.dashLineShapeLayer];
    
    [self startScrollDashLineShapeLayer];
}

#pragma mark - test CAShapeLayer

- (void)startScrollDashLineShapeLayer
{
    // 延迟时间
    NSTimeInterval delayTime = 0.3;
    // 动画间隔
    NSTimeInterval timeInterval = 0.1;
    // 获取队列
    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    // 创建计时器
    _timer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, queue);
    // 延迟时间
    dispatch_time_t startDelyTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)delayTime*NSEC_PER_SEC);
    // 设置计时器
    dispatch_source_set_timer(_timer, startDelyTime, timeInterval*NSEC_PER_SEC, 0.1*NSEC_PER_SEC);
    // 设置句柄
    dispatch_source_set_event_handler(_timer, ^{
       
        // 执行事件
        dispatch_after(DISPATCH_TIME_NOW, dispatch_get_main_queue(), ^{
           
            CGFloat _add = 3;
            _dashLineShapeLayer.lineDashPhase -= _add;
        });
    });
    
    dispatch_resume(_timer);
}

#pragma mark -  actions

- (void)tap:(UITapGestureRecognizer *)gesture
{
    CGPoint point = [gesture locationInView:self.view];
    [self.scrollView nbTransform_circleColor_toColor:[UIColor greenColor] duration:0.5f startPoint:point];
}

#pragma mark - getter

- (UIScrollView *)scrollView
{
    if (!_scrollView) {
        
        _scrollView = [[UIScrollView alloc] initWithFrame:self.view.bounds];
        _scrollView.contentSize = CGSizeMake(self.view.bounds.size.width, self.view.bounds.size.height*3);
        _scrollView.delaysContentTouches = NO;
        UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tap:)];
        [_scrollView addGestureRecognizer:tap];
        
    }
    return _scrollView;
}

- (CAShapeLayer *)matchstickManLayer
{
    if (!_matchstickManLayer) {
        
        _matchstickManLayer = [CAShapeLayer layer];
        _matchstickManLayer.bounds = CGRectMake(0, 0, 300, 300);
        _matchstickManLayer.position = CGPointMake(150, 150);
        
        UIBezierPath* path = [[UIBezierPath alloc] init];
        [path moveToPoint:CGPointMake(175, 100)];
        
        // 画脑袋
        [path addArcWithCenter:CGPointMake(150, 100) radius:25 startAngle:0 endAngle:M_PI*2 clockwise:YES];
        // 画脖子
        [path moveToPoint:CGPointMake(150, 125)];
        [path addLineToPoint:CGPointMake(150, 175)];
        // 画腿
        [path addLineToPoint:CGPointMake(125, 225)];
        [path moveToPoint:CGPointMake(150, 175)];
        [path addLineToPoint:CGPointMake(175, 225)];
        // 画胳膊
        [path moveToPoint:CGPointMake(100, 150)];
        [path addLineToPoint:CGPointMake(200, 150)];
        
        _matchstickManLayer.path = path.CGPath;
        _matchstickManLayer.strokeColor = [UIColor redColor].CGColor;
        _matchstickManLayer.fillColor = [UIColor clearColor].CGColor;
        _matchstickManLayer.lineWidth = 5.f;
        _matchstickManLayer.lineJoin = kCALineJoinRound;
        _matchstickManLayer.lineCap = kCALineCapRound;
        _matchstickManLayer.backgroundColor = [UIColor lightGrayColor].CGColor;
    }
    
    return _matchstickManLayer;
}

- (CAShapeLayer *)circleLayer
{
    if (!_circleLayer) {
        
        _circleLayer = [[CAShapeLayer alloc] init];
        _circleLayer.bounds = CGRectMake(0, 0, 300, 300);
        _circleLayer.position = CGPointMake(150, 450);
        _circleLayer.backgroundColor = [UIColor colorWithWhite:0.95 alpha:1].CGColor;
        
        UIBezierPath* path = [UIBezierPath bezierPath];
        [path addArcWithCenter:CGPointMake(150, 150) radius:80 startAngle:0 endAngle:M_PI*2 clockwise:YES];
        [path moveToPoint:CGPointMake(210, 150)];
        [path addArcWithCenter:CGPointMake(150, 150) radius:60 startAngle:0 endAngle:M_PI*2 clockwise:YES];
        [path moveToPoint:CGPointMake(190, 150)];
        [path addArcWithCenter:CGPointMake(150, 150) radius:40 startAngle:0 endAngle:M_PI*2 clockwise:YES];
        
        _circleLayer.path = path.CGPath;
        _circleLayer.strokeColor = [UIColor blackColor].CGColor;
        _circleLayer.fillColor = [UIColor orangeColor].CGColor;
//        _circleLayer.fillRule = kCAFillRuleNonZero;
        _circleLayer.fillRule = kCAFillRuleEvenOdd;
        _circleLayer.lineWidth = 3.f;
        // path的回执范围（0，1），path开始绘制的位置（初始位置）和结束的位置
        _circleLayer.strokeStart = 0;
        _circleLayer.strokeEnd = 1;
    }
    return _circleLayer;
}

- (CAShapeLayer *)dashLineShapeLayer
{
    if (!_dashLineShapeLayer) {
        
       
        UIBezierPath* dashLinePath = [UIBezierPath bezierPathWithRoundedRect:CGRectMake(self.view.bounds.size.width/2 - 60, 60, 120, 60) cornerRadius:5.f];
        
        _dashLineShapeLayer = [CAShapeLayer new];
        _dashLineShapeLayer.path = dashLinePath.CGPath;
        _dashLineShapeLayer.bounds = CGRectMake(0, 0, self.view.bounds.size.width, self.view.bounds.size.height);
        _dashLineShapeLayer.position = CGPointMake(self.view.bounds.size.width/2, 600 + self.view.bounds.size.height/2);
        _dashLineShapeLayer.strokeColor = [UIColor whiteColor].CGColor;
        _dashLineShapeLayer.fillColor = [UIColor clearColor].CGColor;
        _dashLineShapeLayer.lineWidth = 3.f;
        _dashLineShapeLayer.lineDashPattern = @[@(6), @(6)];
        _dashLineShapeLayer.zPosition = 999;
        _dashLineShapeLayer.backgroundColor = [UIColor colorWithRed:242.f/255.f green:146.f/255.f blue:146.f/255.f alpha:1].CGColor;
    }
    return _dashLineShapeLayer;
}

@end
