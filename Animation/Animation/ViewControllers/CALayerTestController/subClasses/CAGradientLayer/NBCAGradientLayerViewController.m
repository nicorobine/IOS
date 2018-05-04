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

@property (nonatomic, strong) NSArray<UIColor *>* colors;
@property (nonatomic, strong) NSArray<NSNumber *>* locations;

@end

@implementation NBCAGradientLayerViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self.view addSubview:self.containerView1];
    [self.view addSubview:self.containerView2];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    
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
        
        _colors = @[[UIColor redColor], [UIColor orangeColor], [UIColor yellowColor], [UIColor greenColor], [UIColor blueColor], [UIColor purpleColor]];
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
    }
    return _lineGradientLayer;
}

@end
