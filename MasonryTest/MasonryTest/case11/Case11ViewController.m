//
//  Case11ViewController.m
//  MasonryTest
//
//  Created by NicoRobine on 2018/3/22.
//  Copyright © 2018年 dreamdreamdream. All rights reserved.
//

#import "Case11ViewController.h"

@interface Case11ViewController ()
@property (weak, nonatomic) IBOutlet UIView *containerView;
@property (weak, nonatomic) IBOutlet UILabel *logLabel;

@property (nonatomic, strong) MASConstraint *leftContraint;
@property (nonatomic, strong) MASConstraint *topContraint;

@property (nonatomic, strong) UILabel *spanLabel;
@property (nonatomic, strong) UILabel *attachLabel;

@end

@implementation Case11ViewController

#pragma mark - life cycle

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self configUI];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - UI

- (void)configUI
{
    [_containerView.layer setBorderColor:[UIColor blackColor].CGColor];
    [_containerView.layer setBorderWidth:1.f];
    
    _spanLabel = [UILabel new];
    _spanLabel.text = @"拖我\n拖我";
    _spanLabel.numberOfLines = 0;
    _spanLabel.userInteractionEnabled = YES;
    _spanLabel.backgroundColor = [UIColor purpleColor];
    UIPanGestureRecognizer *panGes = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(panWithGesture:)];
    [_spanLabel addGestureRecognizer:panGes];
    [_containerView addSubview:_spanLabel];
    
    [_spanLabel mas_makeConstraints:^(MASConstraintMaker *make) {
       
        make.top.and.left.greaterThanOrEqualTo(@0);
        make.right.and.bottom.lessThanOrEqualTo(@0);
        
        _leftContraint = make.left.equalTo(@0).with.priorityLow();
        _topContraint = make.top.equalTo(@0).with.priorityLow();
    }];
    
    _attachLabel = [UILabel new];
    _attachLabel.text = @"我就\n跟着你";
    _attachLabel.numberOfLines = 0;
    _attachLabel.backgroundColor = [UIColor greenColor];
    [_containerView addSubview:_attachLabel];
    
    [_attachLabel mas_makeConstraints:^(MASConstraintMaker *make) {
       
        make.left.equalTo(_spanLabel.mas_left).offset(20);
        make.top.equalTo(_spanLabel.mas_bottom).offset(20);
        
        make.top.and.left.greaterThanOrEqualTo(@0);
        make.right.and.bottom.lessThanOrEqualTo(@0);
    }];
}

- (void)panWithGesture:(UIPanGestureRecognizer *)gesture
{
    CGPoint location = [gesture locationInView:_containerView];
    
    _logLabel.text = NSStringFromCGPoint(location);
    
    _leftContraint.equalTo(@(location.x));
    _topContraint.equalTo(@(location.y));
}

@end
