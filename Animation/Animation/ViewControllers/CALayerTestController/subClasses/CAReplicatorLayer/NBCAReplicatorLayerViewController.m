//
//  NBCAReplicatorLayerViewController.m
//  Animation
//
//  Created by NicoRobine on 2019/1/8.
//  Copyright © 2019年 dreamdreamdream. All rights reserved.
//

#import "NBCAReplicatorLayerViewController.h"
#import "NBReflectionView.h"

@interface NBCAReplicatorLayerViewController ()

@end

@implementation NBCAReplicatorLayerViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    [self addReplicatorLayer];
    [self addReflectionView];
}

- (void)addReplicatorLayer
{
    CAReplicatorLayer* replicator = [CAReplicatorLayer layer];
    replicator.frame = self.view.bounds;
    [self.view.layer addSublayer:replicator];
    
    // 重复生成10个
    replicator.instanceCount = 10;
    
    // 复制图层产生时和上一个复制图层的位移（锚点是replicator的中心点）
    CATransform3D transform = CATransform3DIdentity;
    transform = CATransform3DTranslate(transform, 0, 100, 0);
    transform = CATransform3DRotate(transform, M_PI/5, 0, 0, 1);
    transform = CATransform3DTranslate(transform, 0, -100, 0);
    replicator.instanceTransform = transform;
    
    // 各个图层复制的颜色
    replicator.instanceColor = [UIColor greenColor].CGColor;
    // 设置颜色变换
    replicator.instanceRedOffset = -.1;
    replicator.instanceBlueOffset = -.05;
    replicator.instanceGreenOffset = -.05;
    
    // 设置延迟
    replicator.instanceDelay = 3000;
    
    // 创建一个子layer，放到replicator中
    CGSize size = replicator.bounds.size;
    CALayer* layer = [CALayer layer];
    layer.frame = CGRectMake(0, 0, 100, 100);
    layer.position = CGPointMake(size.width/2, size.height/2);
    layer.backgroundColor = [UIColor whiteColor].CGColor;
    [replicator addSublayer:layer];
}

- (void)addReflectionView {
    NBReflectionView* view = [[NBReflectionView alloc] initWithFrame:CGRectMake(100, 0, 200, 200)];
    CALayer* layer = [CALayer layer];
    layer.frame = view.bounds;
    [view.layer addSublayer:layer];
    layer.contents = (__bridge id)[UIImage imageNamed:@"img1"].CGImage;
//    view.layer.contents = (__bridge id)[UIImage imageNamed:@"img1"].CGImage;
    view.clipsToBounds = NO;
    view.layer.masksToBounds = NO;
    [self.view addSubview:view];
}

@end
