//
//  Case10ViewController.m
//  MasonryTest
//
//  Created by NicoRobine on 2018/3/20.
//  Copyright © 2018年 dreamdreamdream. All rights reserved.
//

#import "Case10ViewController.h"

@interface Case10ViewController ()
@property (weak, nonatomic) IBOutlet UIView *containerView;
@property (weak, nonatomic) IBOutlet UILabel *logLablel;

@property (strong, nonatomic) MASConstraint *leftConstraint;
@property (strong, nonatomic) MASConstraint *topConstraint;

@property (nonatomic, strong) UILabel *spanLabel;

@end

@implementation Case10ViewController

#pragma mark - life cycle

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self configUI];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    // 禁用返回手势
    if ([self.navigationController respondsToSelector:@selector(interactivePopGestureRecognizer)]) {
        self.navigationController.interactivePopGestureRecognizer.enabled = NO;
    }
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    // 开启返回手势
    if ([self.navigationController respondsToSelector:@selector(interactivePopGestureRecognizer)]) {
        self.navigationController.interactivePopGestureRecognizer.enabled = YES;
    }
}

#pragma mark - UI

- (void)configUI {
    
    _containerView.backgroundColor = [UIColor lightGrayColor];
    _containerView.layer.borderWidth = 1.f;
    _containerView.layer.borderColor = [UIColor blackColor].CGColor;
    
    _spanLabel = [UILabel new];
    _spanLabel.numberOfLines = 0;
    _spanLabel.userInteractionEnabled = YES;
    _spanLabel.text = @"拖我\n拖我";
    _spanLabel.backgroundColor = [UIColor purpleColor];
    UIPanGestureRecognizer *panGes = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(panWithGesture:)];
    [_spanLabel addGestureRecognizer:panGes];
    [_containerView addSubview:_spanLabel];
    
    [_spanLabel mas_makeConstraints:^(MASConstraintMaker *make) {
       
        _leftConstraint = make.left.equalTo(@0).priorityLow();
        _topConstraint = make.top.equalTo(@0).priorityLow();
        
        make.left.and.top.greaterThanOrEqualTo(_containerView);
        make.right.and.bottom.lessThanOrEqualTo(_containerView);
    }];
}

- (void)panWithGesture:(UIPanGestureRecognizer *)gesture
{
    CGPoint location = [gesture locationInView:_containerView];
    
    _logLablel.text = NSStringFromCGPoint(location);
    
    _leftConstraint.equalTo(@(location.x));
    _topConstraint.equalTo(@(location.y));
}

@end
