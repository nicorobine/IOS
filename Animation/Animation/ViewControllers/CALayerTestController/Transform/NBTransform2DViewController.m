//
//  NBTransform2DViewController.m
//  Animation
//
//  Created by NicoRobine on 2018/4/2.
//  Copyright © 2018年 dreamdreamdream. All rights reserved.
//

#import "NBTransform2DViewController.h"

@interface NBTransform2DViewController ()

@property (weak, nonatomic) IBOutlet UISlider *aSlider;
@property (weak, nonatomic) IBOutlet UISlider *bSlider;
@property (weak, nonatomic) IBOutlet UISlider *cSlider;
@property (weak, nonatomic) IBOutlet UISlider *dSlider;
@property (weak, nonatomic) IBOutlet UISlider *txSlider;
@property (weak, nonatomic) IBOutlet UISlider *tySlider;


@property (nonatomic, strong) CALayer* imgLayer;

@end

@implementation NBTransform2DViewController

#pragma mark - life cycle

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self addsubLayers];
}

#pragma mark - configUI

- (void)addsubLayers
{
    [self.view.layer addSublayer:self.imgLayer];
}

#pragma mark  - Action response

- (IBAction)sliderValueChanged:(UISlider *)sender {
    
    self.imgLayer.affineTransform = CGAffineTransformMake(_aSlider.value, _bSlider.value, _cSlider.value, _dSlider.value, _txSlider.value, _tySlider.value);
}

#pragma mark - getter

- (CALayer *)imgLayer
{
    if (!_imgLayer) {
        
        _imgLayer = [CALayer layer];
        _imgLayer.contentsGravity = kCAGravityResizeAspect;
        _imgLayer.bounds = CGRectMake(0, 0, 200, 200);
        _imgLayer.position = CGPointMake(200, 400);
        _imgLayer.contents = (__bridge id)[UIImage imageNamed:@"img1"].CGImage;
    }
    return _imgLayer;
}

@end
