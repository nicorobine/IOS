//
//  NBBezierPathTestViewController.m
//  Animation
//
//  Created by NicoRobine on 2018/3/28.
//  Copyright © 2018年 dreamdreamdream. All rights reserved.
//

#import "NBBezierPathTestViewController.h"
#import "NBBezierView.h"

@interface NBBezierPathTestViewController ()

@property (nonatomic, strong) NBBezierView *bezierView;

@end

@implementation NBBezierPathTestViewController

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
    self.edgesForExtendedLayout = UIRectEdgeNone;
    
    [self addSubViews];
}

- (void)addSubViews
{
    [self.view addSubview:self.bezierView];
}

#pragma mark - getter

- (NBBezierView *)bezierView
{
    if (!_bezierView) {
        
        _bezierView = [[NBBezierView alloc] initWithFrame:[UIScreen mainScreen].bounds];
        _bezierView.backgroundColor = [UIColor whiteColor];
    }
                       
    return _bezierView;
}

@end
