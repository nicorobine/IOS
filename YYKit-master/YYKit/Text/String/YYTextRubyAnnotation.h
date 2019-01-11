//
//  YYTextRubyAnnotation.h
//  YYKit <https://github.com/ibireme/YYKit>
//
//  Created by ibireme on 15/4/24.
//  Copyright (c) 2015 ibireme.
//
//  This source code is licensed under the MIT-style license found in the
//  LICENSE file in the root directory of this source tree.
//

#import <UIKit/UIKit.h>
#import <CoreText/CoreText.h>

NS_ASSUME_NONNULL_BEGIN

/**
 Wrapper for CTRubyAnnotationRef.
 
 为亚洲文字添加注音符号
 
 Example:
 
     YYTextRubyAnnotation *ruby = [YYTextRubyAnnotation new];
     ruby.textBefore = @"zhù yīn";
     CTRubyAnnotationRef ctRuby = ruby.CTRubyAnnotation;
     if (ctRuby) {
        /// add to attributed string
        CFRelease(ctRuby);
     }
 
 */
@interface YYTextRubyAnnotation : NSObject <NSCopying, NSCoding>

/// Specifies how the ruby text and the base text should be aligned relative to each other.
// 指定ruby文本和基本文本应该如何相互对齐
@property (nonatomic) CTRubyAlignment alignment;

/// Specifies how the ruby text can overhang adjacent characters.
// 指定ruby文本如何悬浮于对象的字符
@property (nonatomic) CTRubyOverhang overhang;

/// Specifies the size of the annotation text as a percent of the size of the base text.
// 将注释文本的大小执行为基本文本的百分比
@property (nonatomic) CGFloat sizeFactor;


/// The ruby text is positioned before the base text;
// ruby文本位于基本文本之前，如位于水平文本上方和垂直文本右方
/// i.e. above horizontal text and to the right of vertical text.
@property (nullable, nonatomic, copy) NSString *textBefore;

/// The ruby text is positioned after the base text;
/// ruby文本位于基本文本之后，如位于水平文本之下和垂直文本左侧
/// i.e. below horizontal text and to the left of vertical text.
@property (nullable, nonatomic, copy) NSString *textAfter;

/// The ruby text is positioned to the right of the base text whether it is horizontal or vertical.
/// 无论水平还是垂直，ruby文本都位于基本文本右侧
/// This is the way that Bopomofo annotations are attached to Chinese text in Taiwan.
@property (nullable, nonatomic, copy) NSString *textInterCharacter;

/// The ruby text follows the base text with no special styling.
/// ruby文本遵循基本文本
@property (nullable, nonatomic, copy) NSString *textInline;


/**
 Create a ruby object from CTRuby object.
 
 根据CTRubyAnnotationRef初始化
 
 @param ctRuby  A CTRuby object.
 
 @return A ruby object, or nil when an error occurs.
 */
+ (instancetype)rubyWithCTRubyRef:(CTRubyAnnotationRef)ctRuby NS_AVAILABLE_IOS(8_0);

/**
 Create a CTRuby object from the instance.
 
 创建一个CTRuby对象
 
 @return A new CTRuby object, or NULL when an error occurs.
 The returned value should be release after used.
 */
- (nullable CTRubyAnnotationRef)CTRubyAnnotation CF_RETURNS_RETAINED NS_AVAILABLE_IOS(8_0);

@end

NS_ASSUME_NONNULL_END
