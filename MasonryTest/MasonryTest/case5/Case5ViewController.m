//
//  Case5ViewController.m
//  MasonryTest
//
//  Created by NicoRobine on 2018/3/16.
//  Copyright © 2018年 dreamdreamdream. All rights reserved.
//

#import "Case5ViewController.h"

@interface Case5ViewController ()

@property (nonatomic, strong) UIView* topView;
@property (nonatomic, strong) UIView* bottomView;

@end

@implementation Case5ViewController

#pragma mark - life cycle

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    [self configUI];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - UI

- (void)configUI {
    
    _topView = [UIView new];
    _topView.backgroundColor = [UIColor greenColor];
    [self.view addSubview:_topView];
    
    [_topView mas_makeConstraints:^(MASConstraintMaker *make) {
       
        make.left.and.width.equalTo(self.view);
        make.height.equalTo(@40);
        make.top.equalTo(self.mas_topLayoutGuide);
    }];
    
    _bottomView = [UIView new];
    _bottomView.backgroundColor = [UIColor purpleColor];
    [self.view addSubview:_bottomView];
    
    [_bottomView mas_makeConstraints:^(MASConstraintMaker *make) {
       
        make.left.and.width.equalTo(self.view);
        make.height.equalTo(@40);
        make.bottom.equalTo(self.mas_bottomLayoutGuide);
    }];
}

#pragma mark - Gesture Action

- (IBAction)showOrHideNavigationBar:(UIButton *)sender {
    
    [self.navigationController setNavigationBarHidden:!self.navigationController.isNavigationBarHidden animated:YES];
}

- (IBAction)showOrHideToolBar:(UIButton *)sender {
    
    [self.navigationController setToolbarHidden:!self.navigationController.isToolbarHidden animated:YES];
}

- (IBAction)back:(UIButton *)sender {
    
    [self.navigationController dismissViewControllerAnimated:YES completion:nil];
}
@end
