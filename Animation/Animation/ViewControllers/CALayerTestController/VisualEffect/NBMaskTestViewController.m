//
//  NBMaskTestViewController.m
//  Animation
//
//  Created by NicoRobine on 2018/3/30.
//  Copyright © 2018年 dreamdreamdream. All rights reserved.
//

#import "NBMaskTestViewController.h"

static const NSUInteger count = 3;

@interface NBMaskTestViewController ()
{
    NSUInteger index;
}

@property (nonatomic, strong) CALayer *imgLayer;
@property (nonatomic, strong) CALayer *maskLayer;

@property (nonatomic, strong) CALayer* textLayer;

@property (weak, nonatomic) IBOutlet UILabel *magnificationFilterLabel;
@end

@implementation NBMaskTestViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    index = 0;
    
    [self.view.layer addSublayer:self.imgLayer];
    [self.view.layer addSublayer:self.textLayer];
}
- (IBAction)showOrHiddenMask:(UIButton *)sender {
    
    if (sender.selected) self.imgLayer.mask = nil;
    else self.imgLayer.mask = self.maskLayer;
    
    sender.selected = !sender.isSelected;
}

- (IBAction)magnificationFilterChanged:(UIButton *)sender {
    
    index++;
    
    switch (index%count) {
        case 0:
            // 过滤器双线性滤波算法（对多个像素取样来生成最终值），优点是平滑，缺点放大数倍后不清晰
            self.textLayer.magnificationFilter = kCAFilterLinear;
            self.imgLayer.minificationFilter = kCAFilterLinear;
            self.magnificationFilterLabel.text = @"kCAFilterLinear";
            break;
        case 1:
            // 取样最近的单点像素，而不管其他的颜色。优点是速度快不模糊，缺点是压缩图片后效果不好，放大后马赛克严重
            // 但是对于横平竖直的元素表现拉伸表现良好（如果电子表数字）
            self.textLayer.magnificationFilter = kCAFilterNearest;
            self.imgLayer.minificationFilter = kCAFilterNearest;
            self.magnificationFilterLabel.text = @"kCAFilterNearest";
            break;
        case 2:
            // 和kCAFilterLinear相似，采用三线形滤波算法
            self.textLayer.magnificationFilter = kCAFilterTrilinear;
            self.imgLayer.minificationFilter = kCAFilterTrilinear;
            self.magnificationFilterLabel.text = @"kCAFilterTrilinear";
            break;
        default:
            break;
    }
}
#pragma mark - setters

- (CALayer *)imgLayer
{
    if (!_imgLayer) {
        
        _imgLayer = [CALayer layer];
        _imgLayer.frame = CGRectMake(100, 200, 200, 200);
        _imgLayer.contents = (__bridge id)[UIImage imageNamed:@"img1"].CGImage;
        _imgLayer.mask = self.maskLayer;
        _imgLayer.contentsGravity = kCAGravityResizeAspect;
    }
    return _imgLayer;
}

- (CALayer *)maskLayer
{
    if (!_maskLayer) {
        
        _maskLayer = [CALayer layer];
        _maskLayer.frame = CGRectMake(25, 25, 150, 150);
        _maskLayer.contents = (__bridge id)[UIImage imageNamed:@"mask"].CGImage;
    }
    return _maskLayer;
}

- (CALayer *)textLayer
{
    if (!_textLayer) {
        
        _textLayer = [CALayer layer];
        _textLayer.frame = CGRectMake(100, 500, 205, 56);
        _textLayer.contents = (__bridge id)[UIImage imageNamed:@"text_s"].CGImage;
    }
    
    return _textLayer;
}

@end
