//
//  Case12ViewController.m
//  MasonryTest
//
//  Created by NicoRobine on 2018/3/22.
//  Copyright © 2018年 dreamdreamdream. All rights reserved.
//

#import "Case12ViewController.h"

@interface Case12ViewController ()

@property (nonatomic, strong) UILabel *showLabel;

@property (nonatomic, strong) MASConstraint *centerXConstraint;

@end

@implementation Case12ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    _showLabel = [UILabel new];
    _showLabel.text = @"俺就是像风一样的男子";
    [self.view addSubview:_showLabel];
    
    [_showLabel mas_makeConstraints:^(MASConstraintMaker *make) {
       
//        _centerXConstraint = make.centerX.equalTo(self.view.mas_centerX);
        // centerX是相对于父视图x轴中心的位置（所以这里设置为0就代表了self.view的中心）
        _centerXConstraint = make.centerX.equalTo(@0);
        make.centerY.equalTo(self.view.mas_centerY);
    }];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)startAction:(id)sender {
    
    _centerXConstraint.equalTo(@(-CGRectGetWidth(self.view.frame)));
    [self.view layoutIfNeeded];
    
    _centerXConstraint.equalTo(@0);
    
    [UIView animateWithDuration:0.3 animations:^{
       
        [self.view layoutIfNeeded];
    }];
}

@end
