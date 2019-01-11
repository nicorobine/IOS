//
//  YYTextRunDelegate.h
//  YYKit <https://github.com/ibireme/YYKit>
//
//  Created by ibireme on 14/10/14.
//  Copyright (c) 2015 ibireme.
//
//  This source code is licensed under the MIT-style license found in the
//  LICENSE file in the root directory of this source tree.
//

#import <UIKit/UIKit.h>
#import <CoreText/CoreText.h>

NS_ASSUME_NONNULL_BEGIN

/**
 Wrapper for CTRunDelegateRef.
 
 CTRunDelegateRef 可以实现预留图片显示的位置
 
 Example:
 
     YYTextRunDelegate *delegate = [YYTextRunDelegate new];
     delegate.ascent = 20;
     delegate.descent = 4;
     delegate.width = 20;
     CTRunDelegateRef ctRunDelegate = delegate.CTRunDelegate;
     if (ctRunDelegate) {
         /// add to attributed string
         CFRelease(ctRunDelegate);
     }
 
 */
@interface YYTextRunDelegate : NSObject <NSCopying, NSCoding>

/**
 Creates and returns the CTRunDelegate.
 
 创建并返回一个CTRunDelegate对象
 需要注意的是，需要自己调用CFRelease()释放。
 CTRunDelegateRef对YYTextRunDelegate是强引用
 
 @discussion You need call CFRelease() after used.
 The CTRunDelegateRef has a strong reference to this YYTextRunDelegate object.
 In CoreText, use CTRunDelegateGetRefCon() to get this YYTextRunDelegate object.
 
 @return The CTRunDelegate object.
 */
- (nullable CTRunDelegateRef)CTRunDelegate CF_RETURNS_RETAINED;

/**
 Additional information about the the run delegate.
 run delegate的附加信息
 */
@property (nullable, nonatomic, strong) NSDictionary *userInfo;

/**
 The typographic ascent of glyphs in the run.
 在run中字形的印刷上行
 */
@property (nonatomic) CGFloat ascent;

/**
 The typographic descent of glyphs in the run.
 在run中字形的印刷下行
 */
@property (nonatomic) CGFloat descent;

/**
 The typographic width of glyphs in the run.
 在run中字形的印刷宽度
 */
@property (nonatomic) CGFloat width;

@end

NS_ASSUME_NONNULL_END
