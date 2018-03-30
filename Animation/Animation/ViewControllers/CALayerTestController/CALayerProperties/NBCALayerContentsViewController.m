//
//  NBCALayerContentsViewController.m
//  Animation
//
//  Created by NicoRobine on 2018/3/29.
//  Copyright © 2018年 dreamdreamdream. All rights reserved.
//

#import "NBCALayerContentsViewController.h"

static NSUInteger modeCount = 12;
static NSUInteger scaleCount = 3;
static NSUInteger contentRectCount = 5;
static NSUInteger contentCenterCount = 3;

@interface NBCALayerContentsViewController ()
{
    NSUInteger modeIndex;
    NSUInteger scaleIndex;
    NSUInteger contentRectIndex;
    NSArray *contentRects;
    NSUInteger contentCenterIndex;
    NSArray* contentCenters;
}
@property (weak, nonatomic) IBOutlet UILabel *contentGravityLabel;
@property (weak, nonatomic) IBOutlet UILabel *scaleLabel;
@property (weak, nonatomic) IBOutlet UILabel *contentRectLabel;
@property (weak, nonatomic) IBOutlet UILabel *contentCenterLabel;

@property (nonatomic, strong) CALayer* imageLayer;

@end

@implementation NBCALayerContentsViewController

#pragma mark - life cycle

- (void)viewDidLoad {
    [super viewDidLoad];
    
    modeIndex = 0;
    scaleIndex = 3;
    contentRectIndex = 0;
    contentRects = @[[NSValue valueWithCGRect:CGRectMake(0, 0, 1, 1)],[NSValue valueWithCGRect:CGRectMake(0, 0, 0.5, 0.5)], [NSValue valueWithCGRect:CGRectMake(0.5, 0, 0.5, 0.5)],[NSValue valueWithCGRect:CGRectMake(0, 0.5, 0.5, 0.5)],[NSValue valueWithCGRect:CGRectMake(0.5, 0.5, 0.5, 0.5)]];
    contentCenterIndex = 0;
    contentCenters = @[[NSValue valueWithCGRect:CGRectMake(0, 0, 1, 1)],[NSValue valueWithCGRect:CGRectMake(0, 0, 0.75, 0.75)], [NSValue valueWithCGRect:CGRectMake(0.25, 0.25, 0.5, 0.5)]];
    
    [self testContentsImage];
    [self testContentRect];
}

#pragma mark - UI

// 可以为leyer.contents设置背景图片
// @note 对于iOS来说contents只接收CGImage桥接之后的对象
- (void)testContentsImage
{
    CALayer *imageLayer = [[CALayer alloc] init];
    imageLayer.backgroundColor = [UIColor grayColor].CGColor;
    imageLayer.bounds = CGRectMake(0, 0, 100, 100);
    imageLayer.position = self.view.center;
    // 默认值
    imageLayer.anchorPoint = CGPointMake(0.5, 0.5);
    
    // 设置背景图片
    imageLayer.contents = (__bridge id)[UIImage imageNamed:@"img1"].CGImage;
    
    // 设置填充模式
    imageLayer.contentsGravity = kCAGravityCenter;
    // 图片的放大倍数（默认按照像素显示，这里设置后可以根据屏幕展示）
    // 默认按照像素显示，默认为1，如果为1会按照图片的实际像素显示（图片会是原始图片的大小）
    // 如果设置成屏幕scale，会根据屏幕的scale显示图片（如果是@2x，实际显示比直接设置缩小1倍）
//    imageLayer.contentsScale = [UIScreen mainScreen].scale;
    imageLayer.contentsScale = 1.f;
    
    [self.view.layer insertSublayer:imageLayer atIndex:0];
    
    self.imageLayer = imageLayer;
}

#pragma mark - Action Response

- (IBAction)changeContentsGravity:(id)sender {
    
    switch ((++modeIndex)%modeCount) {
        case 0:
            self.imageLayer.contentsGravity = kCAGravityCenter;
            self.contentGravityLabel.text = @"kCAGravityCenter";
            break;
        case 1:
            self.imageLayer.contentsGravity = kCAGravityTop;
            self.contentGravityLabel.text = @"kCAGravityTop";
            break;
        case 2:
            self.imageLayer.contentsGravity = kCAGravityBottom;
            self.contentGravityLabel.text = @"kCAGravityBottom";
            break;
        case 3:
            self.imageLayer.contentsGravity = kCAGravityLeft;
            self.contentGravityLabel.text = @"kCAGravityLeft";
            break;
        case 4:
            self.imageLayer.contentsGravity = kCAGravityRight;
            self.contentGravityLabel.text = @"kCAGravityRight";
            break;
        case 5:
            self.imageLayer.contentsGravity = kCAGravityTopLeft;
            self.contentGravityLabel.text = @"kCAGravityTopLeft";
            break;

        case 6:
            self.imageLayer.contentsGravity = kCAGravityTopRight;
            self.contentGravityLabel.text = @"kCAGravityTopRight";
            break;

        case 7:
            self.imageLayer.contentsGravity = kCAGravityBottomLeft;
            self.contentGravityLabel.text = @"kCAGravityBottomLeft";
            break;
        case 8:
            self.imageLayer.contentsGravity = kCAGravityBottomRight;
            self.contentGravityLabel.text = @"kCAGravityBottomRight";
            break;
        case 9:
            self.imageLayer.contentsGravity = kCAGravityResize;
            self.contentGravityLabel.text = @"kCAGravityResize";
            break;
        case 10:
            self.imageLayer.contentsGravity = kCAGravityResizeAspect;
            self.contentGravityLabel.text = @"kCAGravityResizeAspect";
            break;
        case 11:
            self.imageLayer.contentsGravity = kCAGravityResizeAspectFill;
            self.contentGravityLabel.text = @"kCAGravityResizeAspectFill";
            break;

            
        default:
            break;
    }
}


- (void)testContentRect {
    
    CALayer *layer1 = [CALayer layer];
//    layer1.backgroundColor = [UIColor greenColor].CGColor;
    layer1.contentsRect = ((NSValue *)contentRects[1]).CGRectValue;
    layer1.bounds = CGRectMake(0, 0, 100, 100);
    layer1.position = CGPointMake(200, 500);
    layer1.contents = (__bridge id)[UIImage imageNamed:@"img1"].CGImage;
    
    CALayer *layer2 = [CALayer layer];
    layer2.contentsRect = ((NSValue *)contentRects[2]).CGRectValue;
    layer2.bounds = CGRectMake(0, 0, 100, 100);
    layer2.position = CGPointMake(303, 500);
    layer2.contents = (__bridge id)[UIImage imageNamed:@"img1"].CGImage;
    
    CALayer *layer3 = [CALayer layer];
    layer3.contentsRect = ((NSValue *)contentRects[3]).CGRectValue;
    layer3.bounds = CGRectMake(0, 0, 100, 100);
    layer3.position = CGPointMake(200, 603);
    layer3.contents = (__bridge id)[UIImage imageNamed:@"img1"].CGImage;
    
    CALayer *layer4 = [CALayer layer];
    layer4.contentsRect = ((NSValue *)contentRects[4]).CGRectValue;
    layer4.bounds = CGRectMake(0, 0, 100, 100);
    layer4.position = CGPointMake(303, 603);
    layer4.contents = (__bridge id)[UIImage imageNamed:@"img1"].CGImage;
    
    [self.view.layer addSublayer:layer1];
    [self.view.layer addSublayer:layer2];
    [self.view.layer addSublayer:layer3];
    [self.view.layer addSublayer:layer4];
}


- (IBAction)changeScale:(id)sender {
    
    self.imageLayer.contentsScale = (++scaleIndex)%scaleCount + 1;
    self.scaleLabel.text = [NSString stringWithFormat:@"%lux", ((scaleIndex)%scaleCount + 1)];
}
- (IBAction)changeMaskToBounds:(id)sender {
    if (((UISwitch*)sender).on) {
        [self.imageLayer setMasksToBounds:YES];
    } else [self.imageLayer setMasksToBounds:NO];
    
}
- (IBAction)changeContentRect:(id)sender {
    
    self.imageLayer.contentsRect = ((NSValue*)contentRects[++contentRectIndex%contentRectCount]).CGRectValue;
    self.contentRectLabel.text = NSStringFromCGRect(((NSValue*)contentRects[contentRectIndex%contentRectCount]).CGRectValue);
}

- (IBAction)changeContentCenter:(id)sender {
    
    CGRect center = ((NSValue*)contentCenters[++contentCenterIndex%contentCenterCount]).CGRectValue;
    self.imageLayer.contentsCenter = center;
    self.contentCenterLabel.text = NSStringFromCGRect(center);
}

@end
