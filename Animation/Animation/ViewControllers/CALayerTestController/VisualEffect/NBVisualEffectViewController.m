//
//  NBVisualEffectViewController.m
//  Animation
//
//  Created by NicoRobine on 2018/3/30.
//  Copyright © 2018年 dreamdreamdream. All rights reserved.
//

#import "NBVisualEffectViewController.h"

@interface NBVisualEffectViewController ()

@property (nonatomic, strong) CALayer* containerLayer;
@property (nonatomic, strong) CALayer* insideLayer;

// 自定义shadowline的Label
@property (nonatomic, strong) CALayer* manualShadowLineLayer;

@end

@implementation NBVisualEffectViewController

#pragma mark - life cycle

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self configUI];
}

#pragma mark - UI

- (void)configUI
{
    [self.containerLayer addSublayer:self.insideLayer];
    [self.view.layer addSublayer:self.containerLayer];
    [self.view.layer addSublayer:self.manualShadowLineLayer];
}

#pragma mark - Action response

- (IBAction)switchMakToBounds:(UISwitch *)sender {
    
    self.containerLayer.masksToBounds = sender.isOn;
}
- (IBAction)switchBorder:(UISwitch *)sender {
    if (sender.on) {
        
        self.containerLayer.borderWidth = 5.f;
        self.containerLayer.borderColor = [UIColor blueColor].CGColor;
    } else {
        self.containerLayer.borderWidth = 0.f;
    }
    
}
- (IBAction)cornerRadiusChanged:(UISlider *)sender {
    
    self.containerLayer.cornerRadius = sender.value;
}
- (IBAction)shardowOffsetChanged:(UISlider *)sender {
    self.containerLayer.shadowOffset = CGSizeMake(sender.value, sender.value);
}
- (IBAction)shardowRadiusChanged:(UISlider *)sender {
    self.containerLayer.shadowRadius = sender.value;
}
- (IBAction)shadowOpacityChanged:(UISlider *)sender {
    self.containerLayer.shadowOpacity = sender.value;
}

#pragma mark - getters

- (CALayer *)containerLayer
{
    if (!_containerLayer) {
        
        _containerLayer = [CALayer layer];
        _containerLayer.bounds = CGRectMake(0, 0, 150, 150);
        _containerLayer.position = CGPointMake(200, 450);
        _containerLayer.backgroundColor = [UIColor purpleColor].CGColor;
        _containerLayer.shadowOpacity = 1.f;
    }
    
    return _containerLayer;
}

- (CALayer *)insideLayer
{
    if (!_insideLayer) {
        
        _insideLayer = [CALayer layer];
        _insideLayer.bounds = CGRectMake(0, 0, 100, 100);
        _insideLayer.position = CGPointMake(0, 0);
        _insideLayer.backgroundColor = [UIColor greenColor].CGColor;
        _insideLayer.shadowOpacity = 0;
    }
    return _insideLayer;
}

- (CALayer *)manualShadowLineLayer
{
    if (!_manualShadowLineLayer) {
        
        _manualShadowLineLayer = [CALayer layer];
        _manualShadowLineLayer.bounds = CGRectMake(0, 0, 100, 100);
        _manualShadowLineLayer.position = CGPointMake(270, 600);
        _manualShadowLineLayer.backgroundColor = [UIColor blueColor].CGColor;
        _manualShadowLineLayer.shadowOpacity = 0.5;
        CGMutablePathRef path = CGPathCreateMutable();
        CGPathMoveToPoint(path, NULL, 0, 0);
        CGPathAddQuadCurveToPoint(path, NULL, 50, -10, 100, 0);
        CGPathAddQuadCurveToPoint(path, NULL, 110, 50, 100, 100);
        CGPathAddQuadCurveToPoint(path, NULL, 50, 110, 0, 100);
        CGPathAddQuadCurveToPoint(path, NULL, -10, 50, 0, 0);
        _manualShadowLineLayer.shadowPath = path;
        CGPathRelease(path);
    }
    
    return _manualShadowLineLayer;
}

@end
