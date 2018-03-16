//
//  Case6ItemView.m
//  MasonryTest
//
//  Created by NicoRobine on 2018/3/16.
//  Copyright © 2018年 dreamdreamdream. All rights reserved.
//

#import "Case6ItemView.h"

@interface Case6ItemView ()

@property (nonatomic, strong) UIImage* image;
@property (nonatomic, strong) NSString* text;
@property (nonatomic, strong) UIView* baseView;

@end

@implementation Case6ItemView

+ (instancetype)newItemWithImage:(UIImage *)image andText:(NSString *)text
{
    Case6ItemView *item = [super new];
    
    if (item) {
        
        item.image = image;
        item.text = text;
        
        [item initView];
    }
    
    return item;
}

- (void)initView {
    
    self.viewForLastBaselineLayout.backgroundColor = [UIColor lightGrayColor];
    
    UIImageView *imgView = [UIImageView new];
    self.baseView = imgView;
    imgView.image = self.image;
    [self addSubview:imgView];
    
    [imgView mas_makeConstraints:^(MASConstraintMaker *make) {
       
        make.top.and.left.equalTo(self).offset(4);
        make.right.equalTo(self.mas_right).offset(4);
    }];
    
    [imgView setContentHuggingPriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisVertical];
    [imgView setContentHuggingPriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisHorizontal];
    
    UILabel *label = [UILabel new];
    label.numberOfLines = 0;
    label.text = self.text;
    [self addSubview:label];
    
    [label mas_makeConstraints:^(MASConstraintMaker *make) {
       
        make.left.equalTo(imgView.mas_left);
        make.top.equalTo(imgView.mas_bottom).offset(4);
        make.right.equalTo(imgView.mas_right);
        make.bottom.equalTo(self.mas_bottom).offset(-4);
    }];
    
    [label setContentHuggingPriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisHorizontal];
}

#pragma mark - over write

- (UIView *)viewForBaselineLayout
{
    return self.baseView;
}

@end
