//
//  Case4Model.h
//  MasonryTest
//
//  Created by NicoRobine on 2018/3/15.
//  Copyright © 2018年 dreamdreamdream. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Case4Model : NSObject

@property (nonatomic, strong) NSString *title;
@property (nonatomic, strong) NSString *content;
@property (nonatomic, strong) UIImage *avatar;
// 用来缓存cell的高度，因为复杂界面计算cell高度是耗时操作
@property (nonatomic, assign) CGFloat cellHeight;

@end
