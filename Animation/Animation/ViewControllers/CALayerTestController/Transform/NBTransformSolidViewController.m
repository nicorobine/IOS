//
//  NBTransformSolidViewController.m
//  Animation
//
//  Created by NicoRobine on 2018/4/16.
//  Copyright © 2018年 dreamdreamdream. All rights reserved.
//

#import "NBTransformSolidViewController.h"

@interface NBTransformSolidViewController ()

@property (nonatomic, strong) UIView* view1;
@property (nonatomic, strong) UIView* view2;
@property (nonatomic, strong) UIView* view3;
@property (nonatomic, strong) UIView* view4;
@property (nonatomic, strong) UIView* view5;
@property (nonatomic, strong) UIView* view6;

@property (nonatomic, strong) NSArray* views;

@property (weak, nonatomic) IBOutlet UIView *containerView;

@property (assign, nonatomic) CGPoint viewCenter;

@end

@implementation NBTransformSolidViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self addTransformOfViews];
}

#pragma mark - private methods

- (void)addTransformOfViews {
    
    CATransform3D transfrom = CATransform3DIdentity;
    transfrom.m34 = -1.0/500;
    transfrom = CATransform3DRotate(transfrom, -M_PI_4, 1, 0, 0);
    transfrom = CATransform3DRotate(transfrom, -M_PI_4, 0, 1, 0);
    self.containerView.layer.sublayerTransform = transfrom;
    
    [self.containerView addSubview:self.view1];
    [self.containerView addSubview:self.view2];
    [self.containerView addSubview:self.view3];
    [self.containerView addSubview:self.view4];
    [self.containerView addSubview:self.view5];
    [self.containerView addSubview:self.view6];
}

#pragma mark - Actions

-(void)buttonClicked:(UIButton*)button
{
    
}

#pragma mark - getter

- (NSArray *)views
{
    if (!_views) {
        
        _views = @[self.view1, self.view2, self.view3, self.view4, self.view5, self.view6];
    }
    return _views;
}


- (UIView *)view1
{
    if (!_view1) {
        
        UIButton*btn = [[UIButton alloc] initWithFrame:CGRectMake(20, 20, 60, 60)];
        [btn setTitle:@"1" forState:UIControlStateNormal];
        [btn addTarget:self action:@selector(buttonClicked:) forControlEvents:UIControlEventTouchUpInside];
        [btn setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
        btn.tag = 0;
        
        _view1 = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 100, 100)];
        _view1.backgroundColor = [UIColor whiteColor];
        _view1.center = self.viewCenter;
        _view1.layer.transform = CATransform3DMakeTranslation(0, 0, 100);
        _view1.layer.doubleSided = NO;
        [_view1 addSubview:btn];
    }
    return _view1;
}

- (UIView *)view2
{
    if (!_view2) {
        
        UIButton*btn = [[UIButton alloc] initWithFrame:CGRectMake(20, 20, 60, 60)];
        [btn setTitle:@"2" forState:UIControlStateNormal];
        [btn addTarget:self action:@selector(buttonClicked:) forControlEvents:UIControlEventTouchUpInside];
        [btn setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
        btn.tag = 1;
        
        _view2 = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 100, 100)];
        _view2.backgroundColor = [UIColor whiteColor];
        _view2.center = self.viewCenter;
        CATransform3D transform = CATransform3DMakeTranslation(50, 0, 0);
        transform = CATransform3DRotate(transform, M_PI_2, 0, 1, 0);
        transform = CATransform3DTranslate(transform, -50, 0, 0);
        _view2.layer.transform = transform;
        _view2.layer.doubleSided = NO;
        [_view2 addSubview:btn];
    }
    return _view2;
}

- (UIView *)view3
{
    if (!_view3) {
        
        UIButton*btn = [[UIButton alloc] initWithFrame:CGRectMake(20, 20, 60, 60)];
        [btn setTitle:@"3" forState:UIControlStateNormal];
        [btn addTarget:self action:@selector(buttonClicked:) forControlEvents:UIControlEventTouchUpInside];
        [btn setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
        btn.tag = 2;
        
        _view3 = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 100, 100)];
        _view3.center = self.viewCenter;
        _view3.backgroundColor = [UIColor whiteColor];
        CATransform3D transform = CATransform3DMakeTranslation(0, -50, 0);
        transform = CATransform3DRotate(transform, M_PI_2, 1, 0, 0);
        transform = CATransform3DTranslate(transform, 0, 50, 0);
        _view3.layer.transform = transform;
        _view3.layer.doubleSided = NO;
        [_view3 addSubview:btn];
    }
    return _view3;
}

- (UIView *)view4
{
    if (!_view4) {
        
        UIButton*btn = [[UIButton alloc] initWithFrame:CGRectMake(20, 20, 60, 60)];
        [btn setTitle:@"4" forState:UIControlStateNormal];
        [btn addTarget:self action:@selector(buttonClicked:) forControlEvents:UIControlEventTouchUpInside];
        [btn setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
        btn.tag = 3;
        
        _view4 = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 100, 100)];
        _view4.center = self.viewCenter;
        _view4.backgroundColor = [UIColor whiteColor];
        CATransform3D transform = CATransform3DMakeTranslation(0, 100, 0);
        transform = CATransform3DRotate(transform, -M_PI_2, 1, 0, 0);
        _view4.layer.transform = transform;
        _view4.layer.doubleSided = NO;
        [_view4 addSubview:btn];
    }
    return _view4;
}

- (UIView *)view5
{
    if (!_view5) {
        
        UIButton*btn = [[UIButton alloc] initWithFrame:CGRectMake(20, 20, 60, 60)];
        [btn setTitle:@"5" forState:UIControlStateNormal];
        [btn setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
        [btn addTarget:self action:@selector(buttonClicked:) forControlEvents:UIControlEventTouchUpInside];
        btn.tag = 4;
        
        _view5 = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 100, 100)];
        _view5.center = self.viewCenter;
        _view5.backgroundColor = [UIColor whiteColor];
        CATransform3D transform = CATransform3DMakeTranslation(-100, 0, 0);
        transform = CATransform3DRotate(transform, -M_PI_2, 0, 1, 0);
        _view5.layer.transform = transform;
        _view5.layer.doubleSided = NO;
        [_view5 addSubview:btn];
    }
    return _view5;
}

- (UIView *)view6
{
    if (!_view6) {
        
        UIButton*btn = [[UIButton alloc] initWithFrame:CGRectMake(20, 20, 60, 60)];
        [btn setTitle:@"6" forState:UIControlStateNormal];
        [btn setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
        [btn addTarget:self action:@selector(buttonClicked:) forControlEvents:UIControlEventTouchUpInside];
        btn.tag = 5;
        
        _view6 = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 100, 100)];
        _view6.center = self.viewCenter;
        _view6.backgroundColor = [UIColor whiteColor];
        CATransform3D transform = CATransform3DMakeTranslation(0, 0, -100);
        transform = CATransform3DRotate(transform, M_PI, 0, 1, 0);
        _view6.layer.transform = transform;
        _view6.layer.doubleSided = NO;
        [_view6 addSubview:btn];
    }
    return _view6;
}

- (CGPoint)viewCenter
{
    return CGPointMake(self.containerView.bounds.size.width/2, self.containerView.bounds.size.height/2);
}

@end
