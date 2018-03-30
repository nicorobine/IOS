//
//  NBCALayerTestViewController.m
//  Animation
//
//  Created by NicoRobine on 2018/3/28.
//  Copyright © 2018年 dreamdreamdream. All rights reserved.
//

#import "NBCALayerTestViewController.h"

@interface NBCALayerTestViewController ()

@end

@implementation NBCALayerTestViewController

#pragma mark - life cycle

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // 测试锚点和位置的关系
    [self testAnchorPointAndPositionAndBounds];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    
}


#pragma mark - UI

- (void)testAnchorPointAndPositionAndBounds {
    
    // 导航不覆盖view
    self.edgesForExtendedLayout = UIRectEdgeNone;
    
    CALayer *layer1 = [[CALayer alloc] init];
    layer1.backgroundColor = [UIColor greenColor].CGColor;
    layer1.bounds = CGRectMake(0, 0, 100, 100);
    // position的位置锚点相对于父视图的位置
    layer1.position = CGPointMake(100, 100);
    // 默认值
    layer1.anchorPoint = CGPointMake(0.5, 0.5);
    
    [self.view.layer addSublayer:layer1];
    
    CALayer *layer2 = [[CALayer alloc] init];
    layer2.backgroundColor = [UIColor redColor].CGColor;
    layer2.bounds = CGRectMake(0, 0, 100, 100);
    layer2.position = CGPointMake(100, 100);
    // 默认值
    layer2.anchorPoint = CGPointMake(0, 0);
    
    [self.view.layer addSublayer:layer2];
    
    CALayer *layer3 = [[CALayer alloc] init];
    layer3.backgroundColor = [UIColor purpleColor].CGColor;
    layer3.bounds = CGRectMake(0, 0, 100, 100);
    layer3.position = CGPointMake(100, 100);
    // 默认值
    layer3.anchorPoint = CGPointMake(1, 1);
    
    [self.view.layer addSublayer:layer3];
}

@end
