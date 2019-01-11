//
//  NBCATextViewController.m
//  Animation
//
//  Created by NicoRobine on 2018/12/28.
//  Copyright © 2018年 dreamdreamdream. All rights reserved.
//

#import "NBCATextViewController.h"
#import <CoreText/CoreText.h>

@interface NBCATextViewController ()

@property (weak, nonatomic) IBOutlet UIView *labelView;
@property (weak, nonatomic) IBOutlet UIView *attributeLabelView;

@end

@implementation NBCATextViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self addNormalLayer];
    [self addAttributeLayer];
}

- (void)addNormalLayer
{
    // 创建一个textlayer
    CATextLayer* textLayer = [CATextLayer layer];
    textLayer.frame = self.labelView.bounds;
    [self.labelView.layer addSublayer:textLayer];
    
    // 设置文本属性
    textLayer.foregroundColor = [UIColor blackColor].CGColor;
    textLayer.alignmentMode = kCAAlignmentLeft;
    textLayer.wrapped = YES;
    textLayer.truncationMode = kCATruncationEnd;
    
    // 设置字体
    UIFont* font = [UIFont systemFontOfSize:16];
    CFStringRef fontName = (__bridge CFStringRef)font.fontName;
    CGFontRef fontRef = CGFontCreateWithFontName(fontName);
    textLayer.font = fontRef;
    textLayer.fontSize = font.pointSize;
    CGFontRelease(fontRef);
    
    // 设置一些文本
    NSString* string = @"索朗多吉发牢骚的肌肤拉动飞机阿里发动机啊来得及发了房间啊老地方见啊浪费啊老地方见啊";
    textLayer.string = string;
    
    // 如果不设置contentScale会模糊，这里设置contentScale
    textLayer.contentsScale = [UIScreen mainScreen].scale;
}

- (void)addAttributeLayer
{
    // 创建textlayer
    CATextLayer* textlayer = [CATextLayer layer];
    textlayer.frame = self.attributeLabelView.bounds;
    [self.attributeLabelView.layer addSublayer:textlayer];
    
    // 设置文本属性
    textlayer.alignmentMode = kCAAlignmentLeft;
    textlayer.wrapped = YES;
    textlayer.truncationMode = kCATruncationEnd;
    
    // 设置字体
    UIFont *font = [UIFont systemFontOfSize:16];
    
    // 设置文本
    NSString* text = @"索朗多吉发牢骚的肌肤拉动飞机阿里发动机啊来得及发了房间啊老地方见啊浪费啊老地方见啊";
    
    // 创建属性字符串
    NSMutableAttributedString* string = nil;
    string = [[NSMutableAttributedString alloc] initWithString:text];
    
    // 将UIFont转换为CTFont
    CFStringRef fontName = (__bridge CFStringRef)font.fontName;
    CGFloat fontSize = font.pointSize;
    CTFontRef fontRef = CTFontCreateWithName(fontName, fontSize, NULL);
    
    // 设置文本属性
    NSDictionary* attribues = @{(__bridge id)kCTForegroundColorAttributeName:[UIColor blackColor], (__bridge id)kCTFontAttributeName:(__bridge id)fontRef};
    [string setAttributes:attribues range:NSMakeRange(0, text.length)];
    
    attribues = @{(__bridge id)kCTForegroundColorAttributeName:[UIColor orangeColor],(__bridge id)kCTUnderlineStyleAttributeName:[NSNumber numberWithInt:kCTUnderlineStyleSingle], (__bridge id)kCTFontAttributeName:(__bridge id)fontRef};
    [string setAttributes:attribues range:NSMakeRange(6, 12)];
    textlayer.string = string;
}


@end
