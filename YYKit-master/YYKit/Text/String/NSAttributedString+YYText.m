//
//  NSAttributedString+YYText.m
//  YYKit <https://github.com/ibireme/YYKit>
//
//  Created by ibireme on 14/10/7.
//  Copyright (c) 2015 ibireme.
//
//  This source code is licensed under the MIT-style license found in the
//  LICENSE file in the root directory of this source tree.
//

#import "NSAttributedString+YYText.h"
#import "YYKitMacro.h"
#import "UIDevice+YYAdd.h"
#import "UIFont+YYAdd.h"
#import "NSParagraphStyle+YYText.h"
#import "YYTextArchiver.h"
#import "YYTextRunDelegate.h"
#import "YYAnimatedImageView.h"
#import "YYTextUtilities.h"
#import <CoreFoundation/CoreFoundation.h>

YYSYNTH_DUMMY_CLASS(NSAttributedString_YYText)


@implementation NSAttributedString (YYText)

// 将属性字符串压缩成NSData对象
- (NSData *)archiveToData {
    NSData *data = nil;
    @try {
        data = [YYTextArchiver archivedDataWithRootObject:self];
    }
    @catch (NSException *exception) {
        NSLog(@"%@",exception);
    }
    return data;
}

// 从NSData中解压缩字符串
+ (instancetype)unarchiveFromData:(NSData *)data {
    NSAttributedString *one = nil;
    @try {
        one = [YYTextUnarchiver unarchiveObjectWithData:data];
    }
    @catch (NSException *exception) {
        NSLog(@"%@",exception);
    }
    return one;
}

// 获取指定索引的属性
- (NSDictionary *)attributesAtIndex:(NSUInteger)index {
    if (index > self.length || self.length == 0) return nil;
    if (self.length > 0 && index == self.length) index--;
    return [self attributesAtIndex:index effectiveRange:NULL];
}

// 根据属性名获取指定的属性
- (id)attribute:(NSString *)attributeName atIndex:(NSUInteger)index {
    if (!attributeName) return nil;
    if (index > self.length || self.length == 0) return nil;
    if (self.length > 0 && index == self.length) index--;
    return [self attribute:attributeName atIndex:index effectiveRange:NULL];
}

// 默认获取第一个字符的属性
- (NSDictionary *)attributes {
    return [self attributesAtIndex:0];
}

// 默认获取第一个字符的字体
- (UIFont *)font {
    return [self fontAtIndex:0];
}

// 获取指定索引的字体
- (UIFont *)fontAtIndex:(NSUInteger)index {
    /*
     In iOS7 and later, UIFont is toll-free bridged to CTFontRef,
     although Apple does not mention it in documentation.
     
     In iOS6, UIFont is a wrapper for CTFontRef, so CoreText can alse use UIfont,
     but UILabel/UITextView cannot use CTFontRef.
     
     iOS7之后UIFont和CTFontRef是toll-free的，iOS6中UIFont是CTFoutRef的封装，这里无论CoreText还是UIKit都使用UIFont
     
     We use UIFont for both CoreText and UIKit.
     */
    UIFont *font = [self attribute:NSFontAttributeName atIndex:index];
    // 小于等于iOS6将CTFontRef转换为UIFont
    if (kSystemVersion <= 6) {
        if (font) {
            if (CFGetTypeID((__bridge CFTypeRef)(font)) == CTFontGetTypeID()) {
                font = [UIFont fontWithCTFont:(CTFontRef)font];
            }
        }
    }
    return font;
}

// 默认返回第一个
- (NSNumber *)kern {
    return [self kernAtIndex:0];
}

// 返回指定索引的字间距
- (NSNumber *)kernAtIndex:(NSUInteger)index {
    return [self attribute:NSKernAttributeName atIndex:index];
}

// 默认返回第一个字符的颜色
- (UIColor *)color {
    return [self colorAtIndex:0];
}

// 返回指定索引的颜色
- (UIColor *)colorAtIndex:(NSUInteger)index {
    UIColor *color = [self attribute:NSForegroundColorAttributeName atIndex:index];
    if (!color) {
        CGColorRef ref = (__bridge CGColorRef)([self attribute:(NSString *)kCTForegroundColorAttributeName atIndex:index]);
        color = [UIColor colorWithCGColor:ref];
    }
    // 如果是CGColorRef转换为UIColor
    if (color && ![color isKindOfClass:[UIColor class]]) {
        if (CFGetTypeID((__bridge CFTypeRef)(color)) == CGColorGetTypeID()) {
            color = [UIColor colorWithCGColor:(__bridge CGColorRef)(color)];
        } else {
            color = nil;
        }
    }
    return color;
}

// 获取默认背景色
- (UIColor *)backgroundColor {
    return [self backgroundColorAtIndex:0];
}

// 获取指定索引的背景色
- (UIColor *)backgroundColorAtIndex:(NSUInteger)index {
    return [self attribute:NSBackgroundColorAttributeName atIndex:index];
}

// 获取笔画宽度
- (NSNumber *)strokeWidth {
    return [self strokeWidthAtIndex:0];
}

// 获取指定索引的笔画宽度
- (NSNumber *)strokeWidthAtIndex:(NSUInteger)index {
    return [self attribute:NSStrokeWidthAttributeName atIndex:index];
}

// 获取填充颜色
- (UIColor *)strokeColor {
    return [self strokeColorAtIndex:0];
}

// 获取指定索引的填充颜色
- (UIColor *)strokeColorAtIndex:(NSUInteger)index {
    UIColor *color = [self attribute:NSStrokeColorAttributeName atIndex:index];
    if (!color) {
        CGColorRef ref = (__bridge CGColorRef)([self attribute:(NSString *)kCTStrokeColorAttributeName atIndex:index]);
        color = [UIColor colorWithCGColor:ref];
    }
    return color;
}

// 获取阴影
- (NSShadow *)shadow {
    return [self shadowAtIndex:0];
}

// 获取指定索引的阴影
- (NSShadow *)shadowAtIndex:(NSUInteger)index {
    return [self attribute:NSShadowAttributeName atIndex:index];
}

// 获取默认的删除线
- (NSUnderlineStyle)strikethroughStyle {
    return [self strikethroughStyleAtIndex:0];
}

// 获取指定索引的删除线
- (NSUnderlineStyle)strikethroughStyleAtIndex:(NSUInteger)index {
    NSNumber *style = [self attribute:NSStrikethroughStyleAttributeName atIndex:index];
    return style.integerValue;
}

// 获取删除线颜色
- (UIColor *)strikethroughColor {
    return [self strikethroughColorAtIndex:0];
}

// 获取指定索引的删除线颜色
- (UIColor *)strikethroughColorAtIndex:(NSUInteger)index {
    if (kSystemVersion >= 7) {
        return [self attribute:NSStrikethroughColorAttributeName atIndex:index];
    }
    return nil;
}

// 获取下划线类型
- (NSUnderlineStyle)underlineStyle {
    return [self underlineStyleAtIndex:0];
}

// 获取指定索引的下划线类型
- (NSUnderlineStyle)underlineStyleAtIndex:(NSUInteger)index {
    NSNumber *style = [self attribute:NSUnderlineStyleAttributeName atIndex:index];
    return style.integerValue;
}

// 获取下划线颜色
- (UIColor *)underlineColor {
    return [self underlineColorAtIndex:0];
}

// 获取指定索引的下划线颜色
- (UIColor *)underlineColorAtIndex:(NSUInteger)index {
    UIColor *color = nil;
    if (kSystemVersion >= 7) {
        color = [self attribute:NSUnderlineColorAttributeName atIndex:index];
    }
    if (!color) {
        CGColorRef ref = (__bridge CGColorRef)([self attribute:(NSString *)kCTUnderlineColorAttributeName atIndex:index]);
        color = [UIColor colorWithCGColor:ref];
    }
    return color;
}

// 获取连字
- (NSNumber *)ligature {
    return [self ligatureAtIndex:0];
}

// 获取指定索引的连字
- (NSNumber *)ligatureAtIndex:(NSUInteger)index {
    return [self attribute:NSLigatureAttributeName atIndex:index];
}

// 获取文本效果
- (NSString *)textEffect {
    return [self textEffectAtIndex:0];
}

// 获取指定索引的文本效果
- (NSString *)textEffectAtIndex:(NSUInteger)index {
    if (kSystemVersion >= 7) {
        return [self attribute:NSTextEffectAttributeName atIndex:index];
    }
    return nil;
}

// 获取倾斜度
- (NSNumber *)obliqueness {
    return [self obliquenessAtIndex:0];
}

// 获取指定索引的倾斜度
- (NSNumber *)obliquenessAtIndex:(NSUInteger)index {
    if (kSystemVersion >= 7) {
        return [self attribute:NSObliquenessAttributeName atIndex:index];
    }
    return nil;
}

// 获取字符水平扩展宽度
- (NSNumber *)expansion {
    return [self expansionAtIndex:0];
}

// 获取指定索引的水平扩展宽度
- (NSNumber *)expansionAtIndex:(NSUInteger)index {
    if (kSystemVersion >= 7) {
        return [self attribute:NSExpansionAttributeName atIndex:index];
    }
    return nil;
}

// 获取基线偏移量
- (NSNumber *)baselineOffset {
    return [self baselineOffsetAtIndex:0];
}

// 获取指定索引的基线偏移量
- (NSNumber *)baselineOffsetAtIndex:(NSUInteger)index {
    if (kSystemVersion >= 7) {
        return [self attribute:NSBaselineOffsetAttributeName atIndex:index];
    }
    return nil;
}

// 获取是否垂直排版
- (BOOL)verticalGlyphForm {
    return [self verticalGlyphFormAtIndex:0];
}

// 获取指定索引的字符是否是垂直排版
- (BOOL)verticalGlyphFormAtIndex:(NSUInteger)index {
    NSNumber *num = [self attribute:NSVerticalGlyphFormAttributeName atIndex:index];
    return num.boolValue;
}

// 获取语言
- (NSString *)language {
    return [self languageAtIndex:0];
}

// 获取指定索引字符的语言
- (NSString *)languageAtIndex:(NSUInteger)index {
    if (kSystemVersion >= 7) {
        return [self attribute:(id)kCTLanguageAttributeName atIndex:index];
    }
    return nil;
}

// 获取文字书写方向
- (NSArray *)writingDirection {
    return [self writingDirectionAtIndex:0];
}

// 获取指定索引的字符的文字书写方向
- (NSArray *)writingDirectionAtIndex:(NSUInteger)index {
    return [self attribute:(id)kCTWritingDirectionAttributeName atIndex:index];
}

// 获取段落样式
- (NSParagraphStyle *)paragraphStyle {
    return [self paragraphStyleAtIndex:0];
}

// 获取指定索引的段落样式
- (NSParagraphStyle *)paragraphStyleAtIndex:(NSUInteger)index {
    /*
     NSParagraphStyle is NOT toll-free bridged to CTParagraphStyleRef.
     
     CoreText can use both NSParagraphStyle and CTParagraphStyleRef,
     but UILabel/UITextView can only use NSParagraphStyle.
     
     We use NSParagraphStyle in both CoreText and UIKit.
     */
    NSParagraphStyle *style = [self attribute:NSParagraphStyleAttributeName atIndex:index];
    if (style) {
        if (CFGetTypeID((__bridge CFTypeRef)(style)) == CTParagraphStyleGetTypeID()) { \
            style = [NSParagraphStyle styleWithCTStyle:(__bridge CTParagraphStyleRef)(style)];
        }
    }
    return style;
}

#define ParagraphAttribute(_attr_) \
NSParagraphStyle *style = self.paragraphStyle; \
if (!style) style = [NSParagraphStyle defaultParagraphStyle]; \
return style. _attr_;

#define ParagraphAttributeAtIndex(_attr_) \
NSParagraphStyle *style = [self paragraphStyleAtIndex:index]; \
if (!style) style = [NSParagraphStyle defaultParagraphStyle]; \
return style. _attr_;

// 文本对齐方式
- (NSTextAlignment)alignment {
    ParagraphAttribute(alignment);
}

// 换行模式
- (NSLineBreakMode)lineBreakMode {
    ParagraphAttribute(lineBreakMode);
}

// 行距
- (CGFloat)lineSpacing {
    ParagraphAttribute(lineSpacing);
}

// 段落距离
- (CGFloat)paragraphSpacing {
    ParagraphAttribute(paragraphSpacing);
}

// 段落顶部到首行文字开头的距离
- (CGFloat)paragraphSpacingBefore {
    ParagraphAttribute(paragraphSpacingBefore);
}

// 首行缩进
- (CGFloat)firstLineHeadIndent {
    ParagraphAttribute(firstLineHeadIndent);
}

// 段落头部缩进
- (CGFloat)headIndent {
    ParagraphAttribute(headIndent);
}

// 段落尾部缩进
- (CGFloat)tailIndent {
    ParagraphAttribute(tailIndent);
}

// 最小行高
- (CGFloat)minimumLineHeight {
    ParagraphAttribute(minimumLineHeight);
}

// 最大行高
- (CGFloat)maximumLineHeight {
    ParagraphAttribute(maximumLineHeight);
}

// 行高放大倍数
- (CGFloat)lineHeightMultiple {
    ParagraphAttribute(lineHeightMultiple);
}

// 文字方向
- (NSWritingDirection)baseWritingDirection {
    ParagraphAttribute(baseWritingDirection);
}

// 连字
- (float)hyphenationFactor {
    ParagraphAttribute(hyphenationFactor);
}

- (CGFloat)defaultTabInterval {
    if (!kiOS7Later) return 0;
    ParagraphAttribute(defaultTabInterval);
}

// 应该是记录对齐方式以及换行位置
- (NSArray *)tabStops {
    if (!kiOS7Later) return nil;
    ParagraphAttribute(tabStops);
}

// 对齐方式
- (NSTextAlignment)alignmentAtIndex:(NSUInteger)index {
    ParagraphAttributeAtIndex(alignment);
}

// 换行方式
- (NSLineBreakMode)lineBreakModeAtIndex:(NSUInteger)index {
    ParagraphAttributeAtIndex(lineBreakMode);
}

// 行距
- (CGFloat)lineSpacingAtIndex:(NSUInteger)index {
    ParagraphAttributeAtIndex(lineSpacing);
}

// 段落后的距离
- (CGFloat)paragraphSpacingAtIndex:(NSUInteger)index {
    ParagraphAttributeAtIndex(paragraphSpacing);
}

// 段落顶部到文字头部的距离
- (CGFloat)paragraphSpacingBeforeAtIndex:(NSUInteger)index {
    ParagraphAttributeAtIndex(paragraphSpacingBefore);
}

// 首行缩进
- (CGFloat)firstLineHeadIndentAtIndex:(NSUInteger)index {
    ParagraphAttributeAtIndex(firstLineHeadIndent);
}

// 段落头部缩进
- (CGFloat)headIndentAtIndex:(NSUInteger)index {
    ParagraphAttributeAtIndex(headIndent);
}

// 段落尾部缩进
- (CGFloat)tailIndentAtIndex:(NSUInteger)index {
    ParagraphAttributeAtIndex(tailIndent);
}

// 最小行高
- (CGFloat)minimumLineHeightAtIndex:(NSUInteger)index {
    ParagraphAttributeAtIndex(minimumLineHeight);
}

// 最大行高
- (CGFloat)maximumLineHeightAtIndex:(NSUInteger)index {
    ParagraphAttributeAtIndex(maximumLineHeight);
}

// 行高放大倍数
- (CGFloat)lineHeightMultipleAtIndex:(NSUInteger)index {
    ParagraphAttributeAtIndex(lineHeightMultiple);
}

// 文字书写方向
- (NSWritingDirection)baseWritingDirectionAtIndex:(NSUInteger)index {
    ParagraphAttributeAtIndex(baseWritingDirection);
}

// 连字
- (float)hyphenationFactorAtIndex:(NSUInteger)index {
    ParagraphAttributeAtIndex(hyphenationFactor);
}

// 默认tab长度
- (CGFloat)defaultTabIntervalAtIndex:(NSUInteger)index {
    if (!kiOS7Later) return 0;
    ParagraphAttributeAtIndex(defaultTabInterval);
}

- (NSArray *)tabStopsAtIndex:(NSUInteger)index {
    if (!kiOS7Later) return nil;
    ParagraphAttributeAtIndex(tabStops);
}

#undef ParagraphAttribute
#undef ParagraphAttributeAtIndex

// 阴影对象
- (YYTextShadow *)textShadow {
    return [self textShadowAtIndex:0];
}

- (YYTextShadow *)textShadowAtIndex:(NSUInteger)index {
    return [self attribute:YYTextShadowAttributeName atIndex:index];
}

// 内部阴影对象
- (YYTextShadow *)textInnerShadow {
    return [self textInnerShadowAtIndex:0];
}

- (YYTextShadow *)textInnerShadowAtIndex:(NSUInteger)index {
    return [self attribute:YYTextInnerShadowAttributeName atIndex:index];
}

// 下划线对象
- (YYTextDecoration *)textUnderline {
    return [self textUnderlineAtIndex:0];
}

- (YYTextDecoration *)textUnderlineAtIndex:(NSUInteger)index {
    return [self attribute:YYTextUnderlineAttributeName atIndex:index];
}

// 删除线对象
- (YYTextDecoration *)textStrikethrough {
    return [self textStrikethroughAtIndex:0];
}

- (YYTextDecoration *)textStrikethroughAtIndex:(NSUInteger)index {
    return [self attribute:YYTextStrikethroughAttributeName atIndex:index];
}

// 文本边界对象
- (YYTextBorder *)textBorder {
    return [self textBorderAtIndex:0];
}

- (YYTextBorder *)textBorderAtIndex:(NSUInteger)index {
    return [self attribute:YYTextBorderAttributeName atIndex:index];
}

// 文本背景边界对象
- (YYTextBorder *)textBackgroundBorder {
    return [self textBackgroundBorderAtIndex:0];
}

- (YYTextBorder *)textBackgroundBorderAtIndex:(NSUInteger)index {
    return [self attribute:YYTextBackedStringAttributeName atIndex:index];
}

// 文本字形转换
- (CGAffineTransform)textGlyphTransform {
    return [self textGlyphTransformAtIndex:0];
}

- (CGAffineTransform)textGlyphTransformAtIndex:(NSUInteger)index {
    NSValue *value = [self attribute:YYTextGlyphTransformAttributeName atIndex:index];
    if (!value) return CGAffineTransformIdentity;
    return [value CGAffineTransformValue];
}

// 获取原文本
- (NSString *)plainTextForRange:(NSRange)range {
    if (range.location == NSNotFound ||range.length == NSNotFound) return nil;
    NSMutableString *result = [NSMutableString string];
    if (range.length == 0) return result;
    NSString *string = self.string;
    [self enumerateAttribute:YYTextBackedStringAttributeName inRange:range options:kNilOptions usingBlock:^(id value, NSRange range, BOOL *stop) {
        YYTextBackedString *backed = value;
        if (backed && backed.string) {
            [result appendString:backed.string];
        } else {
            [result appendString:[string substringWithRange:range]];
        }
    }];
    return result;
}

// 获取附件属性字符串（自定义表情）
+ (NSMutableAttributedString *)attachmentStringWithContent:(id)content
                                               contentMode:(UIViewContentMode)contentMode
                                                     width:(CGFloat)width
                                                    ascent:(CGFloat)ascent
                                                   descent:(CGFloat)descent {
    NSMutableAttributedString *atr = [[NSMutableAttributedString alloc] initWithString:YYTextAttachmentToken];
    
    // 初始化附件（可以是emoji）
    YYTextAttachment *attach = [YYTextAttachment new];
    attach.content = content;
    attach.contentMode = contentMode;
    // 存入属性
    [atr setTextAttachment:attach range:NSMakeRange(0, atr.length)];
    
    // 初始化TextRunDelegate（预留出来附件的为孩子）
    YYTextRunDelegate *delegate = [YYTextRunDelegate new];
    delegate.width = width;
    delegate.ascent = ascent;
    delegate.descent = descent;
    CTRunDelegateRef delegateRef = delegate.CTRunDelegate;
    // 设置属性
    [atr setRunDelegate:delegateRef range:NSMakeRange(0, atr.length)];
    if (delegate) CFRelease(delegateRef);
    
    return atr;
}

// 获取附件属性字符串（自定义表情）
+ (NSMutableAttributedString *)attachmentStringWithContent:(id)content
                                               contentMode:(UIViewContentMode)contentMode
                                            attachmentSize:(CGSize)attachmentSize
                                               alignToFont:(UIFont *)font
                                                 alignment:(YYTextVerticalAlignment)alignment {
    NSMutableAttributedString *atr = [[NSMutableAttributedString alloc] initWithString:YYTextAttachmentToken];
    
    // 初始化附件变量
    YYTextAttachment *attach = [YYTextAttachment new];
    attach.content = content;
    attach.contentMode = contentMode;
    [atr setTextAttachment:attach range:NSMakeRange(0, atr.length)];
    
    // 初始化预留位置变量，并根据对齐方式设置自定义attach的位置
    YYTextRunDelegate *delegate = [YYTextRunDelegate new];
    delegate.width = attachmentSize.width;
    switch (alignment) {
        case YYTextVerticalAlignmentTop: {
            delegate.ascent = font.ascender;
            delegate.descent = attachmentSize.height - font.ascender;
            if (delegate.descent < 0) {
                delegate.descent = 0;
                delegate.ascent = attachmentSize.height;
            }
        } break;
        case YYTextVerticalAlignmentCenter: {
            CGFloat fontHeight = font.ascender - font.descender;
            CGFloat yOffset = font.ascender - fontHeight * 0.5;
            delegate.ascent = attachmentSize.height * 0.5 + yOffset;
            delegate.descent = attachmentSize.height - delegate.ascent;
            if (delegate.descent < 0) {
                delegate.descent = 0;
                delegate.ascent = attachmentSize.height;
            }
        } break;
        case YYTextVerticalAlignmentBottom: {
            delegate.ascent = attachmentSize.height + font.descender;
            delegate.descent = -font.descender;
            if (delegate.ascent < 0) {
                delegate.ascent = 0;
                delegate.descent = attachmentSize.height;
            }
        } break;
        default: {
            delegate.ascent = attachmentSize.height;
            delegate.descent = 0;
        } break;
    }
    // 为字符串设置CTRunDelegateRef属性
    CTRunDelegateRef delegateRef = delegate.CTRunDelegate;
    [atr setRunDelegate:delegateRef range:NSMakeRange(0, atr.length)];
    if (delegate) CFRelease(delegateRef);
    
    return atr;
}

+ (NSMutableAttributedString *)attachmentStringWithEmojiImage:(UIImage *)image
                                                     fontSize:(CGFloat)fontSize {
    if (!image || fontSize <= 0) return nil;
    
    BOOL hasAnim = NO;
    // 判断是否包含动画图片
    if (image.images.count > 1) {
        hasAnim = YES;
    } else if ([image conformsToProtocol:@protocol(YYAnimatedImage)]) {
        id <YYAnimatedImage> ani = (id)image;
        if (ani.animatedImageFrameCount > 1) hasAnim = YES;
    }
    
    // 获取默认的ascent、descent和bounding
    CGFloat ascent = YYEmojiGetAscentWithFontSize(fontSize);
    CGFloat descent = YYEmojiGetDescentWithFontSize(fontSize);
    CGRect bounding = YYEmojiGetGlyphBoundingRectWithFontSize(fontSize);
    
    // 预留附件（emoji）位置
    YYTextRunDelegate *delegate = [YYTextRunDelegate new];
    delegate.ascent = ascent;
    delegate.descent = descent;
    // 宽度，加上两边的边距
    delegate.width = bounding.size.width + 2 * bounding.origin.x;
    
    // 设置附件（emoji）
    YYTextAttachment *attachment = [YYTextAttachment new];
    attachment.contentMode = UIViewContentModeScaleAspectFit;
    attachment.contentInsets = UIEdgeInsetsMake(ascent - (bounding.size.height + bounding.origin.y), bounding.origin.x, descent + bounding.origin.y, bounding.origin.x);
    // 根据是否是动态度，设置content
    if (hasAnim) {
        YYAnimatedImageView *view = [YYAnimatedImageView new];
        view.frame = bounding;
        view.image = image;
        view.contentMode = UIViewContentModeScaleAspectFit;
        attachment.content = view;
    } else {
        attachment.content = image;
    }
    
    // 初始化属性字符串，并设置attachment和TextRunDelegate属性
    NSMutableAttributedString *atr = [[NSMutableAttributedString alloc] initWithString:YYTextAttachmentToken];
    [atr setTextAttachment:attachment range:NSMakeRange(0, atr.length)];
    CTRunDelegateRef ctDelegate = delegate.CTRunDelegate;
    [atr setRunDelegate:ctDelegate range:NSMakeRange(0, atr.length)];
    if (ctDelegate) CFRelease(ctDelegate);
    
    return atr;
}

// 返回属性字符串的长度
- (NSRange)rangeOfAll {
    return NSMakeRange(0, self.length);
}

// 属性字符串的所有属性是否是一样的
- (BOOL)isSharedAttributesInAllRange {
    __block BOOL shared = YES;
    // 记录第一个字符的属性
    __block NSDictionary *firstAttrs = nil;
    [self enumerateAttributesInRange:self.rangeOfAll options:NSAttributedStringEnumerationLongestEffectiveRangeNotRequired usingBlock:^(NSDictionary *attrs, NSRange range, BOOL *stop) {
        if (range.location == 0) {
            firstAttrs = attrs;
        } else {
            // 与第一个字符的属性对比
            if (firstAttrs.count != attrs.count) {
                shared = NO;
                *stop = YES;
            } else if (firstAttrs) {
                if (![firstAttrs isEqualToDictionary:attrs]) {
                    shared = NO;
                    *stop = YES;
                }
            }
        }
    }];
    return shared;
}

// 是否可以使用UIKit绘图
- (BOOL)canDrawWithUIKit {
    static NSMutableSet *failSet;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        failSet = [NSMutableSet new];
        [failSet addObject:(id)kCTGlyphInfoAttributeName];
        [failSet addObject:(id)kCTCharacterShapeAttributeName];
        if (kiOS7Later) {
            [failSet addObject:(id)kCTLanguageAttributeName];
        }
        [failSet addObject:(id)kCTRunDelegateAttributeName];
        [failSet addObject:(id)kCTBaselineClassAttributeName];
        [failSet addObject:(id)kCTBaselineInfoAttributeName];
        [failSet addObject:(id)kCTBaselineReferenceInfoAttributeName];
        if (kiOS8Later) {
            [failSet addObject:(id)kCTRubyAnnotationAttributeName];
        }
        [failSet addObject:YYTextShadowAttributeName];
        [failSet addObject:YYTextInnerShadowAttributeName];
        [failSet addObject:YYTextUnderlineAttributeName];
        [failSet addObject:YYTextStrikethroughAttributeName];
        [failSet addObject:YYTextBorderAttributeName];
        [failSet addObject:YYTextBackgroundBorderAttributeName];
        [failSet addObject:YYTextBlockBorderAttributeName];
        [failSet addObject:YYTextAttachmentAttributeName];
        [failSet addObject:YYTextHighlightAttributeName];
        [failSet addObject:YYTextGlyphTransformAttributeName];
    });
    
#define Fail { result = NO; *stop = YES; return; }
    __block BOOL result = YES;
    [self enumerateAttributesInRange:self.rangeOfAll options:NSAttributedStringEnumerationLongestEffectiveRangeNotRequired usingBlock:^(NSDictionary *attrs, NSRange range, BOOL *stop) {
        if (attrs.count == 0) return;
        for (NSString *str in attrs.allKeys) {
            if ([failSet containsObject:str]) Fail;
        }
        if (!kiOS7Later) {
            UIFont *font = attrs[NSFontAttributeName];
            if (CFGetTypeID((__bridge CFTypeRef)(font)) == CTFontGetTypeID()) Fail;
        }
        if (attrs[(id)kCTForegroundColorAttributeName] && !attrs[NSForegroundColorAttributeName]) Fail;
        if (attrs[(id)kCTStrokeColorAttributeName] && !attrs[NSStrokeColorAttributeName]) Fail;
        if (attrs[(id)kCTUnderlineColorAttributeName]) {
            if (!kiOS7Later) Fail;
            if (!attrs[NSUnderlineColorAttributeName]) Fail;
        }
        NSParagraphStyle *style = attrs[NSParagraphStyleAttributeName];
        if (style && CFGetTypeID((__bridge CFTypeRef)(style)) == CTParagraphStyleGetTypeID()) Fail;
    }];
    return result;
#undef Fail
}

@end

@implementation NSMutableAttributedString (YYText)

// 设置字符串的属性，如果传入nil，等于清除属性
- (void)setAttributes:(NSDictionary *)attributes {
    // 先清空，然后再设置
    if (attributes == (id)[NSNull null]) attributes = nil;
    [self setAttributes:@{} range:NSMakeRange(0, self.length)];
    [attributes enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        [self setAttribute:key value:obj];
    }];
}

// 根据属性明设置属性
- (void)setAttribute:(NSString *)name value:(id)value {
    [self setAttribute:name value:value range:NSMakeRange(0, self.length)];
}

// 设置指定范围内的属性
- (void)setAttribute:(NSString *)name value:(id)value range:(NSRange)range {
    if (!name || [NSNull isEqual:name]) return;
    if (value && ![NSNull isEqual:value]) [self addAttribute:name value:value range:range];
    else [self removeAttribute:name range:range];
}

// 清除所有属性
- (void)removeAttributesInRange:(NSRange)range {
    [self setAttributes:nil range:range];
}

#pragma mark - Property Setter

// 设置字体
- (void)setFont:(UIFont *)font {
    /*
     In iOS7 and later, UIFont is toll-free bridged to CTFontRef,
     although Apple does not mention it in documentation.
     
     In iOS6, UIFont is a wrapper for CTFontRef, so CoreText can alse use UIfont,
     but UILabel/UITextView cannot use CTFontRef.
     
     We use UIFont for both CoreText and UIKit.
     */
    [self setFont:font range:NSMakeRange(0, self.length)];
}

// 设置字距
- (void)setKern:(NSNumber *)kern {
    [self setKern:kern range:NSMakeRange(0, self.length)];
}

// 设置颜色
- (void)setColor:(UIColor *)color {
    [self setColor:color range:NSMakeRange(0, self.length)];
}

// 设置背景色
- (void)setBackgroundColor:(UIColor *)backgroundColor {
    [self setBackgroundColor:backgroundColor range:NSMakeRange(0, self.length)];
}

// 设置填宽度
- (void)setStrokeWidth:(NSNumber *)strokeWidth {
    [self setStrokeWidth:strokeWidth range:NSMakeRange(0, self.length)];
}

// 设置填充色
- (void)setStrokeColor:(UIColor *)strokeColor {
    [self setStrokeColor:strokeColor range:NSMakeRange(0, self.length)];
}

// 设置阴影
- (void)setShadow:(NSShadow *)shadow {
    [self setShadow:shadow range:NSMakeRange(0, self.length)];
}

// 设置删除线
- (void)setStrikethroughStyle:(NSUnderlineStyle)strikethroughStyle {
    [self setStrikethroughStyle:strikethroughStyle range:NSMakeRange(0, self.length)];
}

// 设置删除线颜色
- (void)setStrikethroughColor:(UIColor *)strikethroughColor {
    [self setStrikethroughColor:strikethroughColor range:NSMakeRange(0, self.length)];
}

// 设置下划线类型
- (void)setUnderlineStyle:(NSUnderlineStyle)underlineStyle {
    [self setUnderlineStyle:underlineStyle range:NSMakeRange(0, self.length)];
}

// 设置下划线颜色
- (void)setUnderlineColor:(UIColor *)underlineColor {
    [self setUnderlineColor:underlineColor range:NSMakeRange(0, self.length)];
}

// 设置连字
- (void)setLigature:(NSNumber *)ligature {
    [self setLigature:ligature range:NSMakeRange(0, self.length)];
}

// 设置文字效果，目前只支持一种
- (void)setTextEffect:(NSString *)textEffect {
    [self setTextEffect:textEffect range:NSMakeRange(0, self.length)];
}

// 设置倾斜度
- (void)setObliqueness:(NSNumber *)obliqueness {
    [self setObliqueness:obliqueness range:NSMakeRange(0, self.length)];
}

// 设置宽度倍数
- (void)setExpansion:(NSNumber *)expansion {
    [self setExpansion:expansion range:NSMakeRange(0, self.length)];
}

// 设置基线偏移
- (void)setBaselineOffset:(NSNumber *)baselineOffset {
    [self setBaselineOffset:baselineOffset range:NSMakeRange(0, self.length)];
}

// 设置垂直排版还是水平排版
- (void)setVerticalGlyphForm:(BOOL)verticalGlyphForm {
    [self setVerticalGlyphForm:verticalGlyphForm range:NSMakeRange(0, self.length)];
}

// 设置语言
- (void)setLanguage:(NSString *)language {
    [self setLanguage:language range:NSMakeRange(0, self.length)];
}

// 设置书写方向
- (void)setWritingDirection:(NSArray *)writingDirection {
    [self setWritingDirection:writingDirection range:NSMakeRange(0, self.length)];
}

// 设置段落格式
- (void)setParagraphStyle:(NSParagraphStyle *)paragraphStyle {
    /*
     NSParagraphStyle is NOT toll-free bridged to CTParagraphStyleRef.
     
     CoreText can use both NSParagraphStyle and CTParagraphStyleRef,
     but UILabel/UITextView can only use NSParagraphStyle.
     
     We use NSParagraphStyle in both CoreText and UIKit.
     */
    [self setParagraphStyle:paragraphStyle range:NSMakeRange(0, self.length)];
}

// 设置对齐方式
- (void)setAlignment:(NSTextAlignment)alignment {
    [self setAlignment:alignment range:NSMakeRange(0, self.length)];
}

// 设置书写方向
- (void)setBaseWritingDirection:(NSWritingDirection)baseWritingDirection {
    [self setBaseWritingDirection:baseWritingDirection range:NSMakeRange(0, self.length)];
}

// 设置行距
- (void)setLineSpacing:(CGFloat)lineSpacing {
    [self setLineSpacing:lineSpacing range:NSMakeRange(0, self.length)];
}

// 设置段落距离
- (void)setParagraphSpacing:(CGFloat)paragraphSpacing {
    [self setParagraphSpacing:paragraphSpacing range:NSMakeRange(0, self.length)];
}

// 设置段落顶部到开头文本的距离
- (void)setParagraphSpacingBefore:(CGFloat)paragraphSpacingBefore {
    [self setParagraphSpacing:paragraphSpacingBefore range:NSMakeRange(0, self.length)];
}

// 设置首行缩进
- (void)setFirstLineHeadIndent:(CGFloat)firstLineHeadIndent {
    [self setFirstLineHeadIndent:firstLineHeadIndent range:NSMakeRange(0, self.length)];
}

// 设置段落前端缩进
- (void)setHeadIndent:(CGFloat)headIndent {
    [self setHeadIndent:headIndent range:NSMakeRange(0, self.length)];
}

// 设置段落后端缩进
- (void)setTailIndent:(CGFloat)tailIndent {
    [self setTailIndent:tailIndent range:NSMakeRange(0, self.length)];
}

// 设置换行模式
- (void)setLineBreakMode:(NSLineBreakMode)lineBreakMode {
    [self setLineBreakMode:lineBreakMode range:NSMakeRange(0, self.length)];
}

// 设置最小行高度
- (void)setMinimumLineHeight:(CGFloat)minimumLineHeight {
    [self setMinimumLineHeight:minimumLineHeight range:NSMakeRange(0, self.length)];
}

// 设置最大行高度
- (void)setMaximumLineHeight:(CGFloat)maximumLineHeight {
    [self setMaximumLineHeight:maximumLineHeight range:NSMakeRange(0, self.length)];
}

// 设置行高度倍数
- (void)setLineHeightMultiple:(CGFloat)lineHeightMultiple {
    [self setLineHeightMultiple:lineHeightMultiple range:NSMakeRange(0, self.length)];
}

// 设置连字因子
- (void)setHyphenationFactor:(float)hyphenationFactor {
    [self setHyphenationFactor:hyphenationFactor range:NSMakeRange(0, self.length)];
}

// 设置默认tab间距
- (void)setDefaultTabInterval:(CGFloat)defaultTabInterval {
    [self setDefaultTabInterval:defaultTabInterval range:NSMakeRange(0, self.length)];
}

// 设置换行位置
- (void)setTabStops:(NSArray *)tabStops {
    [self setTabStops:tabStops range:NSMakeRange(0, self.length)];
}

// 设置阴影对象
- (void)setTextShadow:(YYTextShadow *)textShadow {
    [self setTextShadow:textShadow range:NSMakeRange(0, self.length)];
}

// 设置内部阴影
- (void)setTextInnerShadow:(YYTextShadow *)textInnerShadow {
    [self setTextInnerShadow:textInnerShadow range:NSMakeRange(0, self.length)];
}

// 设置装饰线（下划线）
- (void)setTextUnderline:(YYTextDecoration *)textUnderline {
    [self setTextUnderline:textUnderline range:NSMakeRange(0, self.length)];
}

// 设置装饰线（删除线）
- (void)setTextStrikethrough:(YYTextDecoration *)textStrikethrough {
    [self setTextStrikethrough:textStrikethrough range:NSMakeRange(0, self.length)];
}

// 设置文本边界
- (void)setTextBorder:(YYTextBorder *)textBorder {
    [self setTextBorder:textBorder range:NSMakeRange(0, self.length)];
}

// 设置文本背景边界
- (void)setTextBackgroundBorder:(YYTextBorder *)textBackgroundBorder {
    [self setTextBackgroundBorder:textBackgroundBorder range:NSMakeRange(0, self.length)];
}

// 设置字形转换
- (void)setTextGlyphTransform:(CGAffineTransform)textGlyphTransform {
    [self setTextGlyphTransform:textGlyphTransform range:NSMakeRange(0, self.length)];
}

#pragma mark - Range Setter

// 设置字体
- (void)setFont:(UIFont *)font range:(NSRange)range {
    /*
     In iOS7 and later, UIFont is toll-free bridged to CTFontRef,
     although Apple does not mention it in documentation.
     
     In iOS6, UIFont is a wrapper for CTFontRef, so CoreText can alse use UIfont,
     but UILabel/UITextView cannot use CTFontRef.
     
     We use UIFont for both CoreText and UIKit.
     */
    [self setAttribute:NSFontAttributeName value:font range:range];
}

- (void)setKern:(NSNumber *)kern range:(NSRange)range {
    [self setAttribute:NSKernAttributeName value:kern range:range];
}

- (void)setColor:(UIColor *)color range:(NSRange)range {
    [self setAttribute:(id)kCTForegroundColorAttributeName value:(id)color.CGColor range:range];
    [self setAttribute:NSForegroundColorAttributeName value:color range:range];
}

- (void)setBackgroundColor:(UIColor *)backgroundColor range:(NSRange)range {
    [self setAttribute:NSBackgroundColorAttributeName value:backgroundColor range:range];
}

- (void)setStrokeWidth:(NSNumber *)strokeWidth range:(NSRange)range {
    [self setAttribute:NSStrokeWidthAttributeName value:strokeWidth range:range];
}

- (void)setStrokeColor:(UIColor *)strokeColor range:(NSRange)range {
    [self setAttribute:(id)kCTStrokeColorAttributeName value:(id)strokeColor.CGColor range:range];
    [self setAttribute:NSStrokeColorAttributeName value:strokeColor range:range];
}

- (void)setShadow:(NSShadow *)shadow range:(NSRange)range {
    [self setAttribute:NSShadowAttributeName value:shadow range:range];
}

- (void)setStrikethroughStyle:(NSUnderlineStyle)strikethroughStyle range:(NSRange)range {
    NSNumber *style = strikethroughStyle == 0 ? nil : @(strikethroughStyle);
    [self setAttribute:NSStrikethroughStyleAttributeName value:style range:range];
}

- (void)setStrikethroughColor:(UIColor *)strikethroughColor range:(NSRange)range {
    if (kSystemVersion >= 7) {
        [self setAttribute:NSStrikethroughColorAttributeName value:strikethroughColor range:range];
    }
}

- (void)setUnderlineStyle:(NSUnderlineStyle)underlineStyle range:(NSRange)range {
    NSNumber *style = underlineStyle == 0 ? nil : @(underlineStyle);
    [self setAttribute:NSUnderlineStyleAttributeName value:style range:range];
}

- (void)setUnderlineColor:(UIColor *)underlineColor range:(NSRange)range {
    [self setAttribute:(id)kCTUnderlineColorAttributeName value:(id)underlineColor.CGColor range:range];
    if (kSystemVersion >= 7) {
        [self setAttribute:NSUnderlineColorAttributeName value:underlineColor range:range];
    }
}

- (void)setLigature:(NSNumber *)ligature range:(NSRange)range {
    [self setAttribute:NSLigatureAttributeName value:ligature range:range];
}

- (void)setTextEffect:(NSString *)textEffect range:(NSRange)range {
    if (kSystemVersion >= 7) {
        [self setAttribute:NSTextEffectAttributeName value:textEffect range:range];
    }
}

- (void)setObliqueness:(NSNumber *)obliqueness range:(NSRange)range {
    if (kSystemVersion >= 7) {
        [self setAttribute:NSObliquenessAttributeName value:obliqueness range:range];
    }
}

- (void)setExpansion:(NSNumber *)expansion range:(NSRange)range {
    if (kSystemVersion >= 7) {
        [self setAttribute:NSExpansionAttributeName value:expansion range:range];
    }
}

- (void)setBaselineOffset:(NSNumber *)baselineOffset range:(NSRange)range {
    if (kSystemVersion >= 7) {
        [self setAttribute:NSBaselineOffsetAttributeName value:baselineOffset range:range];
    }
}

- (void)setVerticalGlyphForm:(BOOL)verticalGlyphForm range:(NSRange)range {
    NSNumber *v = verticalGlyphForm ? @(YES) : nil;
    [self setAttribute:NSVerticalGlyphFormAttributeName value:v range:range];
}

- (void)setLanguage:(NSString *)language range:(NSRange)range {
    if (kSystemVersion >= 7) {
        [self setAttribute:(id)kCTLanguageAttributeName value:language range:range];
    }
}

- (void)setWritingDirection:(NSArray *)writingDirection range:(NSRange)range {
    [self setAttribute:(id)kCTWritingDirectionAttributeName value:writingDirection range:range];
}

- (void)setParagraphStyle:(NSParagraphStyle *)paragraphStyle range:(NSRange)range {
    /*
     NSParagraphStyle is NOT toll-free bridged to CTParagraphStyleRef.
     
     CoreText can use both NSParagraphStyle and CTParagraphStyleRef,
     but UILabel/UITextView can only use NSParagraphStyle.
     
     We use NSParagraphStyle in both CoreText and UIKit.
     */
    [self setAttribute:NSParagraphStyleAttributeName value:paragraphStyle range:range];
}

#define ParagraphStyleSet(_attr_) \
[self enumerateAttribute:NSParagraphStyleAttributeName \
                 inRange:range \
                 options:kNilOptions \
              usingBlock: ^(NSParagraphStyle *value, NSRange subRange, BOOL *stop) { \
                  NSMutableParagraphStyle *style = nil; \
                  if (value) { \
                      if (CFGetTypeID((__bridge CFTypeRef)(value)) == CTParagraphStyleGetTypeID()) { \
                          value = [NSParagraphStyle styleWithCTStyle:(__bridge CTParagraphStyleRef)(value)]; \
                      } \
                      if (value. _attr_ == _attr_) return; \
                      if ([value isKindOfClass:[NSMutableParagraphStyle class]]) { \
                          style = (id)value; \
                      } else { \
                          style = value.mutableCopy; \
                      } \
                  } else { \
                      if ([NSParagraphStyle defaultParagraphStyle]. _attr_ == _attr_) return; \
                      style = [NSParagraphStyle defaultParagraphStyle].mutableCopy; \
                  } \
                  style. _attr_ = _attr_; \
                  [self setParagraphStyle:style range:subRange]; \
              }];

- (void)setAlignment:(NSTextAlignment)alignment range:(NSRange)range {
    ParagraphStyleSet(alignment);
}

- (void)setBaseWritingDirection:(NSWritingDirection)baseWritingDirection range:(NSRange)range {
    ParagraphStyleSet(baseWritingDirection);
}

- (void)setLineSpacing:(CGFloat)lineSpacing range:(NSRange)range {
    ParagraphStyleSet(lineSpacing);
}

- (void)setParagraphSpacing:(CGFloat)paragraphSpacing range:(NSRange)range {
    ParagraphStyleSet(paragraphSpacing);
}

- (void)setParagraphSpacingBefore:(CGFloat)paragraphSpacingBefore range:(NSRange)range {
    ParagraphStyleSet(paragraphSpacingBefore);
}

- (void)setFirstLineHeadIndent:(CGFloat)firstLineHeadIndent range:(NSRange)range {
    ParagraphStyleSet(firstLineHeadIndent);
}

- (void)setHeadIndent:(CGFloat)headIndent range:(NSRange)range {
    ParagraphStyleSet(headIndent);
}

- (void)setTailIndent:(CGFloat)tailIndent range:(NSRange)range {
    ParagraphStyleSet(tailIndent);
}

- (void)setLineBreakMode:(NSLineBreakMode)lineBreakMode range:(NSRange)range {
    ParagraphStyleSet(lineBreakMode);
}

- (void)setMinimumLineHeight:(CGFloat)minimumLineHeight range:(NSRange)range {
    ParagraphStyleSet(minimumLineHeight);
}

- (void)setMaximumLineHeight:(CGFloat)maximumLineHeight range:(NSRange)range {
    ParagraphStyleSet(maximumLineHeight);
}

- (void)setLineHeightMultiple:(CGFloat)lineHeightMultiple range:(NSRange)range {
    ParagraphStyleSet(lineHeightMultiple);
}

- (void)setHyphenationFactor:(float)hyphenationFactor range:(NSRange)range {
    ParagraphStyleSet(hyphenationFactor);
}

- (void)setDefaultTabInterval:(CGFloat)defaultTabInterval range:(NSRange)range {
    if (!kiOS7Later) return;
    ParagraphStyleSet(defaultTabInterval);
}

- (void)setTabStops:(NSArray *)tabStops range:(NSRange)range {
    if (!kiOS7Later) return;
    ParagraphStyleSet(tabStops);
}

#undef ParagraphStyleSet

- (void)setSuperscript:(NSNumber *)superscript range:(NSRange)range {
    if ([superscript isEqualToNumber:@(0)]) {
        superscript = nil;
    }
    [self setAttribute:(id)kCTSuperscriptAttributeName value:superscript range:range];
}

- (void)setGlyphInfo:(CTGlyphInfoRef)glyphInfo range:(NSRange)range {
    [self setAttribute:(id)kCTGlyphInfoAttributeName value:(__bridge id)glyphInfo range:range];
}

- (void)setCharacterShape:(NSNumber *)characterShape range:(NSRange)range {
    [self setAttribute:(id)kCTCharacterShapeAttributeName value:characterShape range:range];
}

- (void)setRunDelegate:(CTRunDelegateRef)runDelegate range:(NSRange)range {
    [self setAttribute:(id)kCTRunDelegateAttributeName value:(__bridge id)runDelegate range:range];
}

- (void)setBaselineClass:(CFStringRef)baselineClass range:(NSRange)range {
    [self setAttribute:(id)kCTBaselineClassAttributeName value:(__bridge id)baselineClass range:range];
}

- (void)setBaselineInfo:(CFDictionaryRef)baselineInfo range:(NSRange)range {
    [self setAttribute:(id)kCTBaselineInfoAttributeName value:(__bridge id)baselineInfo range:range];
}

- (void)setBaselineReferenceInfo:(CFDictionaryRef)referenceInfo range:(NSRange)range {
    [self setAttribute:(id)kCTBaselineReferenceInfoAttributeName value:(__bridge id)referenceInfo range:range];
}

- (void)setRubyAnnotation:(CTRubyAnnotationRef)ruby range:(NSRange)range {
    if (kSystemVersion >= 8) {
        [self setAttribute:(id)kCTRubyAnnotationAttributeName value:(__bridge id)ruby range:range];
    }
}

- (void)setAttachment:(NSTextAttachment *)attachment range:(NSRange)range {
    if (kSystemVersion >= 7) {
        [self setAttribute:NSAttachmentAttributeName value:attachment range:range];
    }
}

- (void)setLink:(id)link range:(NSRange)range {
    if (kSystemVersion >= 7) {
        [self setAttribute:NSLinkAttributeName value:link range:range];
    }
}

- (void)setTextBackedString:(YYTextBackedString *)textBackedString range:(NSRange)range {
    [self setAttribute:YYTextBackedStringAttributeName value:textBackedString range:range];
}

- (void)setTextBinding:(YYTextBinding *)textBinding range:(NSRange)range {
    [self setAttribute:YYTextBindingAttributeName value:textBinding range:range];
}

- (void)setTextShadow:(YYTextShadow *)textShadow range:(NSRange)range {
    [self setAttribute:YYTextShadowAttributeName value:textShadow range:range];
}

- (void)setTextInnerShadow:(YYTextShadow *)textInnerShadow range:(NSRange)range {
    [self setAttribute:YYTextInnerShadowAttributeName value:textInnerShadow range:range];
}

- (void)setTextUnderline:(YYTextDecoration *)textUnderline range:(NSRange)range {
    [self setAttribute:YYTextUnderlineAttributeName value:textUnderline range:range];
}

- (void)setTextStrikethrough:(YYTextDecoration *)textStrikethrough range:(NSRange)range {
    [self setAttribute:YYTextStrikethroughAttributeName value:textStrikethrough range:range];
}

- (void)setTextBorder:(YYTextBorder *)textBorder range:(NSRange)range {
    [self setAttribute:YYTextBorderAttributeName value:textBorder range:range];
}

- (void)setTextBackgroundBorder:(YYTextBorder *)textBackgroundBorder range:(NSRange)range {
    [self setAttribute:YYTextBackgroundBorderAttributeName value:textBackgroundBorder range:range];
}

- (void)setTextAttachment:(YYTextAttachment *)textAttachment range:(NSRange)range {
    [self setAttribute:YYTextAttachmentAttributeName value:textAttachment range:range];
}

- (void)setTextHighlight:(YYTextHighlight *)textHighlight range:(NSRange)range {
    [self setAttribute:YYTextHighlightAttributeName value:textHighlight range:range];
}

- (void)setTextBlockBorder:(YYTextBorder *)textBlockBorder range:(NSRange)range {
    [self setAttribute:YYTextBlockBorderAttributeName value:textBlockBorder range:range];
}

- (void)setTextRubyAnnotation:(YYTextRubyAnnotation *)ruby range:(NSRange)range {
    if (kiOS8Later) {
        CTRubyAnnotationRef rubyRef = [ruby CTRubyAnnotation];
        [self setRubyAnnotation:rubyRef range:range];
        if (rubyRef) CFRelease(rubyRef);
    }
}

- (void)setTextGlyphTransform:(CGAffineTransform)textGlyphTransform range:(NSRange)range {
    NSValue *value = CGAffineTransformIsIdentity(textGlyphTransform) ? nil : [NSValue valueWithCGAffineTransform:textGlyphTransform];
    [self setAttribute:YYTextGlyphTransformAttributeName value:value range:range];
}

// 设置高亮的范围、颜色、背景色和回调
- (void)setTextHighlightRange:(NSRange)range
                        color:(UIColor *)color
              backgroundColor:(UIColor *)backgroundColor
                     userInfo:(NSDictionary *)userInfo
                    tapAction:(YYTextAction)tapAction
              longPressAction:(YYTextAction)longPressAction {
    YYTextHighlight *highlight = [YYTextHighlight highlightWithBackgroundColor:backgroundColor];
    highlight.userInfo = userInfo;
    highlight.tapAction = tapAction;
    highlight.longPressAction = longPressAction;
    if (color) [self setColor:color range:range];
    [self setTextHighlight:highlight range:range];
}

// 设置高亮的范围、颜色、背景色和回调
- (void)setTextHighlightRange:(NSRange)range
                        color:(UIColor *)color
              backgroundColor:(UIColor *)backgroundColor
                    tapAction:(YYTextAction)tapAction {
    [self setTextHighlightRange:range
                          color:color
                backgroundColor:backgroundColor
                       userInfo:nil
                      tapAction:tapAction
                longPressAction:nil];
}

// 设置高亮的范围、颜色、背景色
- (void)setTextHighlightRange:(NSRange)range
                        color:(UIColor *)color
              backgroundColor:(UIColor *)backgroundColor
                     userInfo:(NSDictionary *)userInfo {
    [self setTextHighlightRange:range
                          color:color
                backgroundColor:backgroundColor
                       userInfo:userInfo
                      tapAction:nil
                longPressAction:nil];
}

// 将字符串插入指定的位置
- (void)insertString:(NSString *)string atIndex:(NSUInteger)location {
    [self replaceCharactersInRange:NSMakeRange(location, 0) withString:string];
    // 🤔️这里不知道什么是不连续的属性
    [self removeDiscontinuousAttributesInRange:NSMakeRange(location, string.length)];
}

// 拼接字符串
- (void)appendString:(NSString *)string {
    NSUInteger length = self.length;
    [self replaceCharactersInRange:NSMakeRange(length, 0) withString:string];
    [self removeDiscontinuousAttributesInRange:NSMakeRange(length, string.length)];
}

// 🤔️ 应该是联合emoji的东西
- (void)setClearColorToJoinedEmoji {
    NSString *str = self.string;
    if (str.length < 8) return;
    
    // Most string do not contains the joined-emoji, test the joiner first.
    BOOL containsJoiner = NO;
    {
        CFStringRef cfStr = (__bridge CFStringRef)str;
        BOOL needFree = NO;
        UniChar *chars = NULL;
        chars = (void *)CFStringGetCharactersPtr(cfStr);
        if (!chars) {
            chars = malloc(str.length * sizeof(UniChar));
            if (chars) {
                needFree = YES;
                CFStringGetCharacters(cfStr, CFRangeMake(0, str.length), chars);
            }
        }
        if (!chars) { // fail to get unichar..
            containsJoiner = YES;
        } else {
            for (int i = 0, max = (int)str.length; i < max; i++) {
                if (chars[i] == 0x200D) { // 'ZERO WIDTH JOINER' (U+200D)
                    containsJoiner = YES;
                    break;
                }
            }
            if (needFree) free(chars);
        }
    }
    if (!containsJoiner) return;
    
    // NSRegularExpression is designed to be immutable and thread safe.
    static NSRegularExpression *regex;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        regex = [NSRegularExpression regularExpressionWithPattern:@"((👨‍👩‍👧‍👦|👨‍👩‍👦‍👦|👨‍👩‍👧‍👧|👩‍👩‍👧‍👦|👩‍👩‍👦‍👦|👩‍👩‍👧‍👧|👨‍👨‍👧‍👦|👨‍👨‍👦‍👦|👨‍👨‍👧‍👧)+|(👨‍👩‍👧|👩‍👩‍👦|👩‍👩‍👧|👨‍👨‍👦|👨‍👨‍👧))" options:kNilOptions error:nil];
    });
    
    UIColor *clear = [UIColor clearColor];
    [regex enumerateMatchesInString:str options:kNilOptions range:NSMakeRange(0, str.length) usingBlock:^(NSTextCheckingResult *result, NSMatchingFlags flags, BOOL *stop) {
        [self setColor:clear range:result.range];
    }];
}

- (void)removeDiscontinuousAttributesInRange:(NSRange)range {
    NSArray *keys = [NSMutableAttributedString allDiscontinuousAttributeKeys];
    for (NSString *key in keys) {
        [self removeAttribute:key range:range];
    }
}

+ (NSArray *)allDiscontinuousAttributeKeys {
    static NSMutableArray *keys;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        keys = @[(id)kCTSuperscriptAttributeName,
                 (id)kCTRunDelegateAttributeName,
                 YYTextBackedStringAttributeName,
                 YYTextBindingAttributeName,
                 YYTextAttachmentAttributeName].mutableCopy;
        if (kiOS8Later) {
            [keys addObject:(id)kCTRubyAnnotationAttributeName];
        }
        if (kiOS7Later) {
            [keys addObject:NSAttachmentAttributeName];
        }
    });
    return keys;
}

@end
