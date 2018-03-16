//
//  Case2ViewController.m
//  MasonryTest
//
//  Created by NicoRobine on 2018/3/15.
//  Copyright © 2018年 dreamdreamdream. All rights reserved.
//

#import "Case2ViewController.h"

static const CGFloat IMAGE_WIDTH = 32;

@interface Case2ViewController ()

@property (nonatomic, strong) UIView *containerView;
@property (nonatomic, strong) NSMutableArray <UIImageView *> *imageViews;
@property (nonatomic, strong) NSArray <NSString *> *imageNames;
@property (nonatomic, strong) NSMutableArray *widthConstraints;

@end

@implementation Case2ViewController

#pragma mark - life cycle

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    [self initData];
    [self configUI];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - init

- (void)initData {
    _imageNames = @[@"bluefaces_1", @"bluefaces_2", @"bluefaces_3", @"bluefaces_4"];
    _imageViews = [NSMutableArray new];
    _widthConstraints = [NSMutableArray new];
}

#pragma mark - UI

- (void)configUI {
    
    _containerView = [UIView new];
    _containerView.backgroundColor = [UIColor lightGrayColor];
    [self.view addSubview:_containerView];
    
    [_containerView mas_makeConstraints:^(MASConstraintMaker *make) {
       
        // 这里不设置宽度，让子view决定宽度
//        make.width.equalTo(@(4*IMAGE_WIDTH));
        make.top.equalTo(self.view.mas_top).with.offset(200);
        make.height.equalTo(@(IMAGE_WIDTH));
        make.centerX.equalTo(self.view.mas_centerX);
    }];
    
    [self congfigImageViews];
}

- (void)congfigImageViews
{
    for (NSString *imageName in _imageNames) {
        
        UIImageView *imgView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:imageName]];
        [_imageViews addObject:imgView];
        [_containerView addSubview:imgView];
    }
    
    __block UIView *lastView = nil;
    __block MASConstraint *widthConstraint = nil;
    NSUInteger count = _imageViews.count;
    [_imageViews enumerateObjectsUsingBlock:^(UIImageView * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
       
        [obj mas_makeConstraints:^(MASConstraintMaker *make) {
           
            make.height.equalTo(@(IMAGE_WIDTH));
            widthConstraint = make.width.equalTo(@(IMAGE_WIDTH));
            make.left.equalTo(lastView ? lastView.mas_right : obj.superview.mas_left);
            make.centerY.equalTo(obj.superview.mas_centerY);
            
            if (idx ==  count-1) {
                make.right.equalTo(obj.superview.mas_right);
            }
            
            [_widthConstraints addObject:widthConstraint];
            lastView = obj;
        }];
    }];
}
- (IBAction)showOrHiddenFace:(UISwitch *)sender {
    
    MASConstraint *widthConstraint = [_widthConstraints objectAtIndex:sender.tag];
    
    if (sender.on) {
        widthConstraint.equalTo(@(IMAGE_WIDTH));
    } else widthConstraint.equalTo(@0);
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
