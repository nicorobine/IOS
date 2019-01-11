//
//  NBCATransfromLayerViewController.m
//  Animation
//
//  Created by NicoRobine on 2019/1/8.
//  Copyright © 2019年 dreamdreamdream. All rights reserved.
//

#import "NBCATransfromLayerViewController.h"

@interface NBCATransfromLayerViewController ()

@end

@implementation NBCATransfromLayerViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    CATransform3D pt = CATransform3DIdentity;
    pt.m34 = -1.0/500.0;
    self.view.layer.sublayerTransform = pt;
    
    CATransform3D c1t = CATransform3DIdentity;
    c1t = CATransform3DTranslate(c1t, 100, 0, 0);
    CALayer* cube1 = [self cubeWithTransfrom:c1t];
    [self.view.layer addSublayer:cube1];
    
    CATransform3D c2t = CATransform3DIdentity;
    c2t = CATransform3DTranslate(c2t, 0, 100, 0);
    c2t = CATransform3DRotate(c2t, -M_PI_4, 1, 0, 0);
    c2t = CATransform3DRotate(c2t, M_PI_4, 0, 1, 0);
    CALayer* cube2 = [self cubeWithTransfrom:c2t];
    [self.view.layer addSublayer:cube2];
}

- (CALayer *)faceWithTransfrom:(CATransform3D)transfrom
{
    CALayer* face = [CALayer layer];
    face.frame = CGRectMake(-50, -50, 100, 100);
    
    CGFloat red = rand()/(double)INT_MAX;
    CGFloat green = rand()/(double)INT_MAX;
    CGFloat blue = rand()/(double)INT_MAX;
    face.backgroundColor = [UIColor colorWithRed:red green:green blue:blue alpha:1].CGColor;
    
    face.transform = transfrom;
    
    return face;
}

- (CALayer *)cubeWithTransfrom:(CATransform3D)transfrom
{
    CATransformLayer* cube = [CATransformLayer layer];
    
    // add face1
    CATransform3D ct = CATransform3DMakeTranslation(0, 0, 50);
    [cube addSublayer:[self faceWithTransfrom:ct]];
    
    // add face2
    ct = CATransform3DMakeTranslation(50, 0, 0);
    ct = CATransform3DRotate(ct, M_PI_2, 0, 1, 0);
    [cube addSublayer:[self faceWithTransfrom:ct]];
    
    // add face3
    ct = CATransform3DMakeTranslation(0, -50, 0);
    ct = CATransform3DRotate(ct, M_PI_2, 1, 0, 0);
    [cube addSublayer:[self faceWithTransfrom:ct]];
    
    // add face4
    ct = CATransform3DMakeTranslation(0, 50, 0);
    ct = CATransform3DRotate(ct, -M_PI_2, 1, 0, 0);
    [cube addSublayer:[self faceWithTransfrom:ct]];
    
    // add face5
    ct = CATransform3DMakeTranslation(-50, 0, 0);
    ct = CATransform3DRotate(ct, -M_PI_2, 0, 1, 0);
    [cube addSublayer:[self faceWithTransfrom:ct]];
    
    // add face6
    ct = CATransform3DMakeTranslation(0, 0, -50);
    ct = CATransform3DRotate(ct, M_PI, 0, 1, 0);
    [cube addSublayer:[self faceWithTransfrom:ct]];
    
    CGSize size = self.view.bounds.size;
    
    cube.position = CGPointMake(size.width/2, size.height/2);
    cube.transform = transfrom;
    
    return cube;
}

@end
