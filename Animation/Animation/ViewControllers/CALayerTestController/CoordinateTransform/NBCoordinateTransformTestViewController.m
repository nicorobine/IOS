//
//  NBCoordinateTransformTestViewController.m
//  Animation
//
//  Created by NicoRobine on 2018/3/30.
//  Copyright © 2018年 dreamdreamdream. All rights reserved.
//



#import "NBCoordinateTransformTestViewController.h"

@interface NBCoordinateTransformTestViewController ()

@property (weak, nonatomic) IBOutlet UIView *view1;
@property (weak, nonatomic) IBOutlet UIView *view2;
@property (weak, nonatomic) IBOutlet UIView *view3;

@property (weak, nonatomic) IBOutlet UILabel *viewLabel;
@property (weak, nonatomic) IBOutlet UILabel *view1Label;
@property (weak, nonatomic) IBOutlet UILabel *view2Label;
@property (weak, nonatomic) IBOutlet UILabel *view3Label;

@end

@implementation NBCoordinateTransformTestViewController

#pragma mark - life cycle

- (void)viewDidLoad {
    [super viewDidLoad];
    
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    UITouch *touch = [touches anyObject];
    
    CGPoint touchPoint = [touch locationInView:self.view];
    
    _viewLabel.text = NSStringFromCGPoint(touchPoint);
    _view1Label.text = NSStringFromCGPoint([self.view convertPoint:touchPoint toView:_view1]);
    _view2Label.text = NSStringFromCGPoint([self.view convertPoint:touchPoint toView:_view2]);
    _view3Label.text = NSStringFromCGPoint([self.view convertPoint:touchPoint toView:_view3]);
}

- (void)touchesMoved:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    UITouch *touch = [touches anyObject];
    
    CGPoint touchPoint = [touch locationInView:self.view];
    
    _viewLabel.text = NSStringFromCGPoint(touchPoint);
    _view1Label.text = NSStringFromCGPoint([self.view convertPoint:touchPoint toView:_view1]);
    _view2Label.text = NSStringFromCGPoint([self.view convertPoint:touchPoint toView:_view2]);
    _view3Label.text = NSStringFromCGPoint([self.view convertPoint:touchPoint toView:_view3]);
}

- (IBAction)geometryFlippedSwitch:(UISwitch *)sender {
    
    self.view3.layer.geometryFlipped = !self.view3.layer.isGeometryFlipped;
}
@end
