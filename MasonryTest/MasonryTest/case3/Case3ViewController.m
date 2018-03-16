//
//  Case3ViewController.m
//  MasonryTest
//
//  Created by NicoRobine on 2018/3/15.
//  Copyright © 2018年 dreamdreamdream. All rights reserved.
//

#import "Case3ViewController.h"

static const CGFloat MaxWidth = 300;

@interface Case3ViewController ()
@property (weak, nonatomic) IBOutlet UILabel *titleView;
@property (weak, nonatomic) IBOutlet UISlider *sliderView;

@property (strong, nonatomic) UIView *containerView;
@property (strong, nonatomic) UIView *containerSubView;

@property (strong, nonatomic) MASConstraint *containerWithConstraint;

@end

@implementation Case3ViewController

#pragma mark - life cycle

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self configUI];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - configUI

- (void)configUI {
    
    _containerView = [UIView new];
    _containerView.backgroundColor = [UIColor greenColor];
    [self.view addSubview:_containerView];
    
    [_containerView mas_makeConstraints:^(MASConstraintMaker *make) {
       
        make.top.equalTo(_titleView.mas_top).with.offset(160);
        _containerWithConstraint = make.width.equalTo(@(MaxWidth));
        make.height.equalTo(@40);
        make.left.equalTo(_sliderView.mas_left);
    }];
    
    _sliderView.maximumValue = MaxWidth;
    _sliderView.value = MaxWidth;
    
    _containerSubView = [UIView new];
    _containerSubView.backgroundColor = [UIColor purpleColor];
    [_containerView addSubview:_containerSubView];
    
    [_containerSubView mas_makeConstraints:^(MASConstraintMaker *make) {
       
        make.left.equalTo(_containerView.mas_left);
        make.top.equalTo(_containerView.mas_top);
        make.bottom.equalTo(_containerView.mas_bottom);
        make.width.equalTo(_containerView.mas_width).multipliedBy(0.5);
    }];
}

- (IBAction)sliderValueChanged:(UISlider *)sender {
    
    _containerWithConstraint.equalTo(@(sender.value));
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
