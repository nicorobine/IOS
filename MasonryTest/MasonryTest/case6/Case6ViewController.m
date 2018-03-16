//
//  Case6ViewController.m
//  MasonryTest
//
//  Created by NicoRobine on 2018/3/16.
//  Copyright © 2018年 dreamdreamdream. All rights reserved.
//

#import "Case6ViewController.h"
#import "Case6ItemView.h"

@interface Case6ViewController ()

@property (nonatomic, strong) NSArray *images;
@property (nonatomic, strong) NSArray *texts;

@end

@implementation Case6ViewController

#pragma mark - life cycle

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self generateData];
    [self configUI];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - private method

- (void)generateData {
    
    _images = @[[UIImage imageNamed:@"dog_small"], [UIImage imageNamed:@"dog_middle"], [UIImage imageNamed:@"dog_big"]];
    _texts = @[@"Auto layout is a system", @"Auto Layout is a system that lets you lay out", @"Auto Layout is a system that lets you lay out your app’s user interface"];
}

- (void)configUI
{
    UIView *lastView = nil;
    for (int i = 0; i<3; i++) {
        Case6ItemView *item = [Case6ItemView newItemWithImage:_images[i] andText:_texts[i]];
        [self.view addSubview:item];
        
        __weak typeof(item) weakItem = item;
        [item mas_makeConstraints:^(MASConstraintMaker *make) {
            
            __strong typeof(item) strongItem = weakItem;
            make.left.mas_equalTo(lastView?lastView.mas_right:strongItem.superview).offset(8);
            
            if (lastView) {
                make.baseline.mas_equalTo(lastView.mas_baseline);
            } else make.top.mas_equalTo(self.view.mas_top).with.offset(200);
        }];
        
        lastView = item;
    }
}

@end
