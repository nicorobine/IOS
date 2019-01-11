//
//  NBReflectionView.m
//  Animation
//
//  Created by NicoRobine on 2019/1/9.
//  Copyright © 2019年 dreamdreamdream. All rights reserved.
//

#import "NBReflectionView.h"

@implementation NBReflectionView

// 绑定view的layer
+ (Class)layerClass {
    return [CAReplicatorLayer class];
}

- (void)setup {
    // configure replicator
    CAReplicatorLayer* replicator = (CAReplicatorLayer *)self.layer;
    replicator.instanceCount = 2;
    
    // 将倒影layer放到实际layer下面并完成垂直反转
    CATransform3D transform = CATransform3DIdentity;
    CGFloat verticalOffset = self.bounds.size.height + 2;
    transform = CATransform3DTranslate(transform, 0, verticalOffset, 0);
    transform = CATransform3DScale(transform, 1, -1, 0);
    replicator.instanceTransform = transform;
    
    replicator.instanceAlphaOffset = -0.6;
}

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        [self setup];
    }
    return self;
}

- (void)awakeFromNib {
    [super awakeFromNib];
    [self setup];
}

@end
