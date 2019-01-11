//
//  NRCombineTransform2DViewController.m
//  Animation
//
//  Created by NicoRobine on 2018/12/11.
//  Copyright © 2018年 dreamdreamdream. All rights reserved.
//

#import "NRCombineTransform2DViewController.h"

@interface NRCombineTransform2DViewController ()

@property (weak, nonatomic) IBOutlet UIImageView *imageView;
@property (weak, nonatomic) IBOutlet UIImageView *imageView1;
@property (weak, nonatomic) IBOutlet UIImageView *imageView2;
@property (weak, nonatomic) IBOutlet UIImageView *imageView3;

@end

@implementation NRCombineTransform2DViewController

#pragma mark - Life Cycle

- (void)viewDidLoad {
    [super viewDidLoad];
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Private


#pragma mark - Actions

- (IBAction)start:(UIButton *)sender {
    
    [self.view bringSubviewToFront:self.imageView];
    
    CGAffineTransform transform = CGAffineTransformIdentity;
    // 先缩小0.5
    transform = CGAffineTransformScale(transform, .5, .5);
    // 再旋转30度
    transform = CGAffineTransformRotate(transform, M_PI/180 * 30);
    // 在沿着旋转30度后的轴线（计算是轴线也会跟着旋转）方向便宜240（实际眼y轴的便宜为240*sin30，120个点）
    transform = CGAffineTransformTranslate(transform, 240, 0);
    // 应用仿射转换
    self.imageView.layer.affineTransform = transform;
}


- (IBAction)start1:(UIButton *)sender {
    
    [self.view bringSubviewToFront:self.imageView1];
    CGAffineTransform transform = CGAffineTransformIdentity;
    // 再旋转30度
    transform = CGAffineTransformRotate(transform, M_PI/180 * 30);
    
    // 先缩小0.5
    transform = CGAffineTransformScale(transform, .5, .5);
    
    // 在沿着旋转30度后的轴线（计算是轴线也会跟着旋转）方向便宜240（实际眼y轴的便宜为240*sin30，120个点）
    transform = CGAffineTransformTranslate(transform, 240, 0);
    
    // 返回30度
    transform = CGAffineTransformRotate(transform, -M_PI/180 * 30);
    
    // 这时候旋转回来了，会向右平移120
    transform = CGAffineTransformTranslate(transform, 120, 0);
    
    // 应用仿射转换
    self.imageView1.layer.affineTransform = transform;
}

- (IBAction)start2:(UIButton *)sender {
    [self.view bringSubviewToFront:self.imageView2];
    
    CGAffineTransform transform = CGAffineTransformIdentity;
    
    // 在沿着旋转30度后的轴线（计算是轴线也会跟着旋转）方向便宜240（实际眼y轴的便宜为240*sin30，120个点）
    transform = CGAffineTransformTranslate(transform, 240, 0);
    // 先缩小0.5
    transform = CGAffineTransformScale(transform, .5, .5);
    // 再旋转30度
    transform = CGAffineTransformRotate(transform, M_PI/180 * 30);
    
    // 应用仿射转换
    self.imageView2.layer.affineTransform = transform;
}
- (IBAction)start3:(UIButton *)sender {
    CGAffineTransform transform = CGAffineTransformIdentity;
    // 先向右平移120（坐标原点也会平移）
    transform = CGAffineTransformTranslate(transform, 120, 0);
    // 再旋转90度（坐标系也会旋转90度，x轴向下，y轴向右）
    transform = CGAffineTransformRotate(transform, M_PI_2);
    // 再沿x轴平移120（向下）
    transform = CGAffineTransformTranslate(transform, 120, 0);
    self.imageView3.layer.affineTransform = transform;
}

- (IBAction)reset:(UIButton *)sender {
    CGAffineTransform transform = CGAffineTransformIdentity;
    self.imageView.layer.affineTransform = transform;
}
@end
