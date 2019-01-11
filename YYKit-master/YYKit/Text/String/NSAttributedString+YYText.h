//
//  NSAttributedString+YYText.h
//  YYKit <https://github.com/ibireme/YYKit>
//
//  Created by ibireme on 14/10/7.
//  Copyright (c) 2015 ibireme.
//
//  This source code is licensed under the MIT-style license found in the
//  LICENSE file in the root directory of this source tree.
//

#import <UIKit/UIKit.h>
#import <CoreText/CoreText.h>

#if __has_include(<YYKit/YYKit.h>)
#import <YYKit/YYTextAttribute.h>
#import <YYKit/YYTextRubyAnnotation.h>
#else
#import "YYTextAttribute.h"
#import "YYTextRubyAnnotation.h"
#endif

NS_ASSUME_NONNULL_BEGIN

/**
 Get pre-defined attributes from attributed string.
 All properties defined in UIKit, CoreText and YYText are included.
 
 从属性字符串中获取预定义的属性，包含所有UIText、CoreText和YYText的属性
 */
@interface NSAttributedString (YYText)

/**
 Archive the string to data.
 
 将string归档成data
 
 @return Returns nil if an error occurs.
 */
- (nullable NSData *)archiveToData;

/**
 Unarchive string from data.
 
 从data中解压成attribuString
 
 @param data  The archived attributed string data.
 @return Returns nil if an error occurs.
 */
+ (nullable instancetype)unarchiveFromData:(NSData *)data;



#pragma mark - Retrieving character attribute information
///=============================================================================
/// @name Retrieving character attribute information
///=============================================================================

/**
 Returns the attributes at first charactor.
 返回第一个字符的属性
 */
@property (nullable, nonatomic, copy, readonly) NSDictionary<NSString *, id> *attributes;

/**
 Returns the attributes for the character at a given index.
 
 获取指定索引的属性
 
 @discussion Raises an `NSRangeException` if index lies beyond the end of the 
 receiver's characters.
 
 @param index  The index for which to return attributes. 
 This value must lie within the bounds of the receiver.
 
 @return The attributes for the character at index.
 */
- (nullable NSDictionary<NSString *, id> *)attributesAtIndex:(NSUInteger)index;

/**
 Returns the value for an attribute with a given name of the character at a given index.
 
 获取指定索引和属性名的属性值
 
 @discussion Raises an `NSRangeException` if index lies beyond the end of the
 receiver's characters.
 
 @param attributeName  The name of an attribute.
 @param index          The index for which to return attributes. 
 This value must not exceed the bounds of the receiver.
 
 @return The value for the attribute named `attributeName` of the character at 
 index `index`, or nil if there is no such attribute.
 */
- (nullable id)attribute:(NSString *)attributeName atIndex:(NSUInteger)index;


#pragma mark - Get character attribute as property
///=============================================================================
/// @name Get character attribute as property
///=============================================================================

/**
 The font of the text. (read-only)
 
 获取text的字体，默认是Helvetica（Neue）12，这个Font属性的方法获取的是第一个字符的属性
 
 @discussion Default is Helvetica (Neue) 12.
 @discussion Get this property returns the first character's attribute.
 @since CoreText:3.2  UIKit:6.0  YYKit:6.0
 */
@property (nullable, nonatomic, strong, readonly) UIFont *font;
- (nullable UIFont *)fontAtIndex:(NSUInteger)index;

/**
 A kerning adjustment. (read-only)
 
 字距调整。默认为标准字间距0，字距属性指示后续字符应从当前字符的字体定义的默认便宜量偏移的点数，
 正kern表示更远的偏移，负kern表示更近的便宜
 
 @discussion Default is standard kerning. The kerning attribute indicate how many 
 points the following character should be shifted from its default offset as 
 defined by the current character's font in points; a positive kern indicates a 
 shift farther along and a negative kern indicates a shift closer to the current 
 character. If this attribute is not present, standard kerning will be used. 
 If this attribute is set to 0.0, no kerning will be done at all.
 @discussion Get this property returns the first character's attribute.
 @since CoreText:3.2  UIKit:6.0  YYKit:6.0
 */
@property (nullable, nonatomic, strong, readonly) NSNumber *kern;
- (nullable NSNumber *)kernAtIndex:(NSUInteger)index;

/**
 The foreground color. (read-only)
 
 forground的颜色
 
 @discussion Default is Black.
 @discussion Get this property returns the first character's attribute.
 @since CoreText:3.2  UIKit:6.0  YYKit:6.0
 */
@property (nullable, nonatomic, strong, readonly) UIColor *color;
- (nullable UIColor *)colorAtIndex:(NSUInteger)index;

/**
 The background color. (read-only)
 
 背景颜色
 
 @discussion Default is nil (or no background).
 @discussion Get this property returns the first character's attribute.
 @since UIKit:6.0
 */
@property (nullable, nonatomic, strong, readonly) UIColor *backgroundColor;
- (nullable UIColor *)backgroundColorAtIndex:(NSUInteger)index;

/**
 The stroke width. (read-only)
 
 设置笔画宽度，取值为 NSNumber 对象（整数），负值填充效果，正值中空效果
 
 @discussion Default value is 0.0 (no stroke). This attribute, interpreted as
 a percentage of font point size, controls the text drawing mode: positive 
 values effect drawing with stroke only; negative values are for stroke and fill.
 A typical value for outlined text is 3.0.
 @discussion Get this property returns the first character's attribute.
 @since CoreText:3.2  UIKit:6.0
 */
@property (nullable, nonatomic, strong, readonly) NSNumber *strokeWidth;
- (nullable NSNumber *)strokeWidthAtIndex:(NSUInteger)index;

/**
 The stroke color. (read-only)
 
 填充部分颜色，不是字体颜色。默认为nil，采用foregroundColor
 
 @discussion Default value is nil (same as foreground color).
 @discussion Get this property returns the first character's attribute.
 @since CoreText:3.2  UIKit:6.0
 */
@property (nullable, nonatomic, strong, readonly) UIColor *strokeColor;
- (nullable UIColor *)strokeColorAtIndex:(NSUInteger)index;

/**
 The text shadow. (read-only)
 
 文本阴影，默认为nil（没有阴影）
 
 @discussion Default value is nil (no shadow).
 @discussion Get this property returns the first character's attribute.
 @since UIKit:6.0  YYKit:6.0
 */
@property (nullable, nonatomic, strong, readonly) NSShadow *shadow;
- (nullable NSShadow *)shadowAtIndex:(NSUInteger)index;

/**
 The strikethrough style. (read-only)
 
 删除线类型，默认为nil（没有删除线）
 
 @discussion Default value is NSUnderlineStyleNone (no strikethrough).
 @discussion Get this property returns the first character's attribute.
 @since UIKit:6.0
 */
@property (nonatomic, readonly) NSUnderlineStyle strikethroughStyle;
- (NSUnderlineStyle)strikethroughStyleAtIndex:(NSUInteger)index;

/**
 The strikethrough color. (read-only)
 
 删除线颜色，默认为foreground颜色
 
 @discussion Default value is nil (same as foreground color).
 @discussion Get this property returns the first character's attribute.
 @since UIKit:7.0
 */
@property (nullable, nonatomic, strong, readonly) UIColor *strikethroughColor;
- (nullable UIColor *)strikethroughColorAtIndex:(NSUInteger)index;

/**
 The underline style. (read-only)
 
 下划线的样式，默认为nil（没有下划线）
 
 @discussion Default value is NSUnderlineStyleNone (no underline).
 @discussion Get this property returns the first character's attribute.
 @since CoreText:3.2  UIKit:6.0
 */
@property (nonatomic, readonly) NSUnderlineStyle underlineStyle;
- (NSUnderlineStyle)underlineStyleAtIndex:(NSUInteger)index;

/**
 The underline color. (read-only)
 
 下划线颜色，默认为foreground颜色
 
 @discussion Default value is nil (same as foreground color).
 @discussion Get this property returns the first character's attribute.
 @since CoreText:3.2  UIKit:7.0
 */
@property (nullable, nonatomic, strong, readonly) UIColor *underlineColor;
- (nullable UIColor *)underlineColorAtIndex:(NSUInteger)index;

/**
 Ligature formation control. (read-only)
 
 连字格式控制。默认值为int值1. ligature属性确定在显示字符串时应使用哪种类型的连字。
 值0表示仅应使用对于正确呈现文本必不可少的连字，1表示应使用标准连字，2表示应使用所有可用连字。
 哪些连字是标准的取决于脚本和可能的字体。
 
 @discussion Default is int value 1. The ligature attribute determines what kinds 
 of ligatures should be used when displaying the string. A value of 0 indicates 
 that only ligatures essential for proper rendering of text should be used, 
 1 indicates that standard ligatures should be used, and 2 indicates that all 
 available ligatures should be used. Which ligatures are standard depends on the 
 script and possibly the font.
 @discussion Get this property returns the first character's attribute.
 @since CoreText:3.2  UIKit:6.0  YYKit:6.0
 */
@property (nullable, nonatomic, strong, readonly) NSNumber *ligature;
- (nullable NSNumber *)ligatureAtIndex:(NSUInteger)index;

/**
 The text effect. (read-only)
 
 文字效果，默认为nil
 
 @discussion Default is nil (no effect). The only currently supported value
 is NSTextEffectLetterpressStyle.
 @discussion Get this property returns the first character's attribute.
 @since UIKit:7.0
 */
@property (nullable, nonatomic, strong, readonly) NSString *textEffect;
- (nullable NSString *)textEffectAtIndex:(NSUInteger)index;

/**
 The skew to be applied to glyphs. (read-only)
 
 应用于字形的倾斜度（只读）
 
 @discussion Default is 0 (no skew).
 @discussion Get this property returns the first character's attribute.
 @since UIKit:7.0
 */
@property (nullable, nonatomic, strong, readonly) NSNumber *obliqueness;
- (nullable NSNumber *)obliquenessAtIndex:(NSUInteger)index;

/**
 The log of the expansion factor to be applied to glyphs. (read-only)
 
 设置文本横向拉伸属性，取值为 NSNumber （float）,正值横向拉伸文本，负值横向压缩文本
 
 @discussion Default is 0 (no expansion).
 @discussion Get this property returns the first character's attribute.
 @since UIKit:7.0
 */
@property (nullable, nonatomic, strong, readonly) NSNumber *expansion;
- (nullable NSNumber *)expansionAtIndex:(NSUInteger)index;

/**
 The character's offset from the baseline, in points. (read-only)
 
 字符相对于baseline的偏移量（以点为单位）
 
 @discussion Default is 0.
 @discussion Get this property returns the first character's attribute.
 @since UIKit:7.0
 */
@property (nullable, nonatomic, strong, readonly) NSNumber *baselineOffset;
- (nullable NSNumber *)baselineOffsetAtIndex:(NSUInteger)index;

/**
 Glyph orientation control. (read-only)
 
 是否是垂直字形
 
 @discussion Default is NO. A value of NO indicates that horizontal glyph forms 
 are to be used, YES indicates that vertical glyph forms are to be used.
 @discussion Get this property returns the first character's attribute.
 @since CoreText:4.3  YYKit:6.0
 */
@property (nonatomic, readonly) BOOL verticalGlyphForm;
- (BOOL)verticalGlyphFormAtIndex:(NSUInteger)index;

/**
 Specifies text language. (read-only)
 
 指定的文本语言（只读）。
 
 @discussion Value must be a NSString containing a locale identifier. Default is 
 unset. When this attribute is set to a valid identifier, it will be used to select 
 localized glyphs (if supported by the font) and locale-specific line breaking rules.
 @discussion Get this property returns the first character's attribute.
 @since CoreText:7.0  YYKit:7.0
 */
@property (nullable, nonatomic, strong, readonly) NSString *language;
- (nullable NSString *)languageAtIndex:(NSUInteger)index;

/**
 Specifies a bidirectional override or embedding. (read-only)
 
 指定的双向覆盖或者嵌入
 
 @discussion See alse NSWritingDirection and NSWritingDirectionAttributeName.
 @discussion Get this property returns the first character's attribute.
 @since CoreText:6.0  UIKit:7.0  YYKit:6.0
 */
@property (nullable, nonatomic, strong, readonly) NSArray<NSNumber *> *writingDirection;
- (nullable NSArray<NSNumber *> *)writingDirectionAtIndex:(NSUInteger)index;

/**
 An NSParagraphStyle object which is used to specify things like
 line alignment, tab rulers, writing direction, etc. (read-only)
 
 一个NSParagraphStyle对象，用来指定行对齐、制表符、书写方向等内容
 
 @discussion Default is nil ([NSParagraphStyle defaultParagraphStyle]).
 @discussion Get this property returns the first character's attribute.
 @since CoreText:6.0  UIKit:6.0  YYKit:6.0
 */
@property (nullable, nonatomic, strong, readonly) NSParagraphStyle *paragraphStyle;
- (nullable NSParagraphStyle *)paragraphStyleAtIndex:(NSUInteger)index;

#pragma mark - Get paragraph attribute as property
///=============================================================================
/// @name Get paragraph attribute as property
///=============================================================================

/**
 The text alignment (A wrapper for NSParagraphStyle). (read-only)
 
 文字对齐方式
 
 @discussion Natural text alignment is realized as left or right alignment 
 depending on the line sweep direction of the first script contained in the paragraph.
 @discussion Default is NSTextAlignmentNatural.
 @discussion Get this property returns the first character's attribute.
 @since CoreText:6.0  UIKit:6.0  YYKit:6.0
 */
@property (nonatomic, readonly) NSTextAlignment alignment;
- (NSTextAlignment)alignmentAtIndex:(NSUInteger)index;

/**
 The mode that should be used to break lines (A wrapper for NSParagraphStyle). (read-only)
 
 行的切换方式
 
 @discussion This property contains the line break mode to be used laying out the paragraph's text.
 @discussion Default is NSLineBreakByWordWrapping.
 @discussion Get this property returns the first character's attribute.
 @since CoreText:6.0  UIKit:6.0  YYKit:6.0
 */
@property (nonatomic, readonly) NSLineBreakMode lineBreakMode;
- (NSLineBreakMode)lineBreakModeAtIndex:(NSUInteger)index;

/**
 The distance in points between the bottom of one line fragment and the top of the next.
 (A wrapper for NSParagraphStyle) (read-only)
 
 一行片段底部到下一样片段顶部的间距（行距）
 
 @discussion This value is always nonnegative. This value is included in the line 
 fragment heights in the layout manager.
 @discussion Default is 0.
 @discussion Get this property returns the first character's attribute.
 @since CoreText:6.0  UIKit:6.0  YYKit:6.0
 */
@property (nonatomic, readonly) CGFloat lineSpacing;
- (CGFloat)lineSpacingAtIndex:(NSUInteger)index;

/**
 The space after the end of the paragraph (A wrapper for NSParagraphStyle). (read-only)
 
 段落结束后的空间高度，（段落的间距）
 
 @discussion This property contains the space (measured in points) added at the 
 end of the paragraph to separate it from the following paragraph. This value must
 be nonnegative. The space between paragraphs is determined by adding the previous 
 paragraph's paragraphSpacing and the current paragraph's paragraphSpacingBefore.
 @discussion Default is 0.
 @discussion Get this property returns the first character's attribute.
 @since CoreText:6.0  UIKit:6.0  YYKit:6.0
 */
@property (nonatomic, readonly) CGFloat paragraphSpacing;
- (CGFloat)paragraphSpacingAtIndex:(NSUInteger)index;

/**
 The distance between the paragraph's top and the beginning of its text content.
 (A wrapper for NSParagraphStyle). (read-only)
 
 段落的顶部与文本内容开头之间的距离
 
 @discussion This property contains the space (measured in points) between the 
 paragraph's top and the beginning of its text content.
 @discussion Default is 0.
 @discussion Get this property returns the first character's attribute.
 @since CoreText:6.0  UIKit:6.0  YYKit:6.0
 */
@property (nonatomic, readonly) CGFloat paragraphSpacingBefore;
- (CGFloat)paragraphSpacingBeforeAtIndex:(NSUInteger)index;

/**
 The indentation of the first line (A wrapper for NSParagraphStyle). (read-only)
 
 第一行的缩进
 
 @discussion This property contains the distance (in points) from the leading margin 
 of a text container to the beginning of the paragraph's first line. This value 
 is always nonnegative.
 @discussion Default is 0.
 @discussion Get this property returns the first character's attribute.
 @since CoreText:6.0  UIKit:6.0  YYKit:6.0
 */
@property (nonatomic, readonly) CGFloat firstLineHeadIndent;
- (CGFloat)firstLineHeadIndentAtIndex:(NSUInteger)index;

/**
 The indentation of the receiver's lines other than the first. (A wrapper for NSParagraphStyle). (read-only)
 
 除了第一行外整体的缩进
 
 @discussion This property contains the distance (in points) from the leading margin 
 of a text container to the beginning of lines other than the first. This value is 
 always nonnegative.
 @discussion Default is 0.
 @discussion Get this property returns the first character's attribute.
 @since CoreText:6.0  UIKit:6.0  YYKit:6.0
 */
@property (nonatomic, readonly) CGFloat headIndent;
- (CGFloat)headIndentAtIndex:(NSUInteger)index;

/**
 The trailing indentation (A wrapper for NSParagraphStyle). (read-only)
 
 段落尾部的缩进
 
 @discussion If positive, this value is the distance from the leading margin 
 (for example, the left margin in left-to-right text). If 0 or negative, it's the 
 distance from the trailing margin.
 @discussion Default is 0.
 @discussion Get this property returns the first character's attribute.
 @since CoreText:6.0  UIKit:6.0  YYKit:6.0
 */
@property (nonatomic, readonly) CGFloat tailIndent;
- (CGFloat)tailIndentAtIndex:(NSUInteger)index;

/**
 The receiver's minimum height (A wrapper for NSParagraphStyle). (read-only)
 
 接收者的最小高度。这个属性包含接收者占据的任何行的最小点高度，忽略字体的大小和附件字形的大小
 
 @discussion This property contains the minimum height in points that any line in 
 the receiver will occupy, regardless of the font size or size of any attached graphic. 
 This value must be nonnegative.
 @discussion Default is 0.
 @discussion Get this property returns the first character's attribute.
 @since CoreText:6.0  UIKit:6.0  YYKit:6.0
 */
@property (nonatomic, readonly) CGFloat minimumLineHeight;
- (CGFloat)minimumLineHeightAtIndex:(NSUInteger)index;

/**
 The receiver's maximum line height (A wrapper for NSParagraphStyle). (read-only)
 
 接收者最大的行高度
 
 @discussion This property contains the maximum height in points that any line in 
 the receiver will occupy, regardless of the font size or size of any attached graphic. 
 This value is always nonnegative. Glyphs and graphics exceeding this height will 
 overlap neighboring lines; however, a maximum height of 0 implies no line height limit. 
 Although this limit applies to the line itself, line spacing adds extra space between adjacent lines.
 @discussion Default is 0 (no limit).
 @discussion Get this property returns the first character's attribute.
 @since CoreText:6.0  UIKit:6.0  YYKit:6.0
 */
@property (nonatomic, readonly) CGFloat maximumLineHeight;
- (CGFloat)maximumLineHeightAtIndex:(NSUInteger)index;

/**
 The line height multiple (A wrapper for NSParagraphStyle). (read-only)
 
 行高度的放大倍数
 
 @discussion This property contains the line break mode to be used laying out the paragraph's text.
 @discussion Default is 0 (no multiple).
 @discussion Get this property returns the first character's attribute.
 @since CoreText:6.0  UIKit:6.0  YYKit:6.0
 */
@property (nonatomic, readonly) CGFloat lineHeightMultiple;
- (CGFloat)lineHeightMultipleAtIndex:(NSUInteger)index;

/**
 The base writing direction (A wrapper for NSParagraphStyle). (read-only)
 
 文字书写方向
 
 @discussion If you specify NSWritingDirectionNaturalDirection, the receiver resolves 
 the writing direction to either NSWritingDirectionLeftToRight or NSWritingDirectionRightToLeft, 
 depending on the direction for the user's `language` preference setting.
 @discussion Default is NSWritingDirectionNatural.
 @discussion Get this property returns the first character's attribute.
 @since CoreText:6.0  UIKit:6.0  YYKit:6.0
 */
@property (nonatomic, readonly) NSWritingDirection baseWritingDirection;
- (NSWritingDirection)baseWritingDirectionAtIndex:(NSUInteger)index;

/**
 The paragraph's threshold for hyphenation. (A wrapper for NSParagraphStyle). (read-only)
 
 段落的连字门槛（🤔️）
 
 @discussion Valid values lie between 0.0 and 1.0 inclusive. Hyphenation is attempted 
 when the ratio of the text width (as broken without hyphenation) to the width of the 
 line fragment is less than the hyphenation factor. When the paragraph's hyphenation 
 factor is 0.0, the layout manager's hyphenation factor is used instead. When both 
 are 0.0, hyphenation is disabled.
 @discussion Default is 0.
 @discussion Get this property returns the first character's attribute.
 @since UIKit:6.0
 */
@property (nonatomic, readonly) float hyphenationFactor;
- (float)hyphenationFactorAtIndex:(NSUInteger)index;

/**
 The document-wide default tab interval (A wrapper for NSParagraphStyle). (read-only)
 
 默认tab的间隔（🤔️，默认为0）
 
 @discussion This property represents the default tab interval in points. Tabs after the 
 last specified in tabStops are placed at integer multiples of this distance (if positive).
 @discussion Default is 0.
 @discussion Get this property returns the first character's attribute.
 @since CoreText:7.0  UIKit:7.0  YYKit:7.0
 */
@property (nonatomic, readonly) CGFloat defaultTabInterval;
- (CGFloat)defaultTabIntervalAtIndex:(NSUInteger)index;

/**
 An array of NSTextTab objects representing the receiver's tab stops.
 (A wrapper for NSParagraphStyle). (read-only)
 
 @discussion The NSTextTab objects, sorted by location, define the tab stops for 
 the paragraph style.
 @discussion Default is 12 TabStops with 28.0 tab interval.
 @discussion Get this property returns the first character's attribute.
 @since CoreText:7.0  UIKit:7.0  YYKit:7.0
 */
@property (nullable, nonatomic, copy, readonly) NSArray<NSTextTab *> *tabStops;
- (nullable NSArray<NSTextTab *> *)tabStopsAtIndex:(NSUInteger)index;

#pragma mark - Get YYText attribute as property
///=============================================================================
/// @name Get YYText attribute as property 获取YYText属性
///=============================================================================

/**
 The text shadow. (read-only)
 
 获取文本阴影
 
 @discussion Default value is nil (no shadow).
 @discussion Get this property returns the first character's attribute.
 @since YYKit:6.0
 */
@property (nullable, nonatomic, strong, readonly) YYTextShadow *textShadow;
- (nullable YYTextShadow *)textShadowAtIndex:(NSUInteger)index;

/**
 The text inner shadow. (read-only)
 
 文本内部阴影
 
 @discussion Default value is nil (no shadow).
 @discussion Get this property returns the first character's attribute.
 @since YYKit:6.0
 */
@property (nullable, nonatomic, strong, readonly) YYTextShadow *textInnerShadow;
- (nullable YYTextShadow *)textInnerShadowAtIndex:(NSUInteger)index;

/**
 The text underline. (read-only)
 
 文本下划线
 
 @discussion Default value is nil (no underline).
 @discussion Get this property returns the first character's attribute.
 @since YYKit:6.0
 */
@property (nullable, nonatomic, strong, readonly) YYTextDecoration *textUnderline;
- (nullable YYTextDecoration *)textUnderlineAtIndex:(NSUInteger)index;

/**
 The text strikethrough. (read-only)
 
 文本删除线
 
 @discussion Default value is nil (no strikethrough).
 @discussion Get this property returns the first character's attribute.
 @since YYKit:6.0
 */
@property (nullable, nonatomic, strong, readonly) YYTextDecoration *textStrikethrough;
- (nullable YYTextDecoration *)textStrikethroughAtIndex:(NSUInteger)index;

/**
 The text border. (read-only)
 
 文本边界线
 
 @discussion Default value is nil (no border).
 @discussion Get this property returns the first character's attribute.
 @since YYKit:6.0
 */
@property (nullable, nonatomic, strong, readonly) YYTextBorder *textBorder;
- (nullable YYTextBorder *)textBorderAtIndex:(NSUInteger)index;

/**
 The text background border. (read-only)
 
 文本背景边界线
 
 @discussion Default value is nil (no background border).
 @discussion Get this property returns the first character's attribute.
 @since YYKit:6.0
 */
@property (nullable, nonatomic, strong, readonly) YYTextBorder *textBackgroundBorder;
- (nullable YYTextBorder *)textBackgroundBorderAtIndex:(NSUInteger)index;

/**
 The glyph transform. (read-only)
 
 字形转换
 
 @discussion Default value is CGAffineTransformIdentity (no transform).
 @discussion Get this property returns the first character's attribute.
 @since YYKit:6.0
 */
@property (nonatomic, readonly) CGAffineTransform textGlyphTransform;
- (CGAffineTransform)textGlyphTransformAtIndex:(NSUInteger)index;


#pragma mark - Query for YYText
///=============================================================================
/// @name Query for YYText
///=============================================================================

/**
 Returns the plain text from a range.
 If there's `YYTextBackedStringAttributeName` attribute, the backed string will
 replace the attributed string range.
 
 获取自定范围内的原始文本
 
 @param range A range in receiver.
 @return The plain text.
 */
- (nullable NSString *)plainTextForRange:(NSRange)range;


#pragma mark - Create attachment string for YYText
///=============================================================================
/// @name Create attachment string for YYText
///=============================================================================

/**
 Creates and returns an attachment.
 
 创建attachment的属性字符串
 
 @param content      The attachment (UIImage/UIView/CALayer).
 @param contentMode  The attachment's content mode.
 @param width        The attachment's container width in layout.
 @param ascent       The attachment's container ascent in layout.
 @param descent      The attachment's container descent in layout.
 
 @return An attributed string, or nil if an error occurs.
 @since YYKit:6.0
 */
+ (NSMutableAttributedString *)attachmentStringWithContent:(nullable id)content
                                               contentMode:(UIViewContentMode)contentMode
                                                     width:(CGFloat)width
                                                    ascent:(CGFloat)ascent
                                                   descent:(CGFloat)descent;

/**
 Creates and returns an attachment.
 
 创建attachment的属性字符串
 
 Example: ContentMode:bottom Alignment:Top.
 
      The text      The attachment holder
         ↓                ↓
     ─────────┌──────────────────────┐───────
        / \   │                      │ / ___|
       / _ \  │                      │| |
      / ___ \ │                      │| |___     ←── The text line
     /_/   \_\│    ██████████████    │ \____|
     ─────────│    ██████████████    │───────
              │    ██████████████    │
              │    ██████████████ ←───────────────── The attachment content
              │    ██████████████    │
              └──────────────────────┘

 @param content        The attachment (UIImage/UIView/CALayer).
 @param contentMode    The attachment's content mode in attachment holder
 @param attachmentSize The attachment holder's size in text layout.
 @param font           The attachment will align to this font.
 @param alignment      The attachment holder's alignment to text line.
 
 @return An attributed string, or nil if an error occurs.
 @since YYKit:6.0
 */
+ (NSMutableAttributedString *)attachmentStringWithContent:(nullable id)content
                                               contentMode:(UIViewContentMode)contentMode
                                            attachmentSize:(CGSize)attachmentSize
                                               alignToFont:(UIFont *)font
                                                 alignment:(YYTextVerticalAlignment)alignment;

/**
 Creates and returns an attahment from a fourquare image as if it was an emoji.
 
 根据图片创建emoji表情字符串
 
 @param image     A fourquare image.
 @param fontSize  The font size.
 
 @return An attributed string, or nil if an error occurs.
 @since YYKit:6.0
 */
+ (nullable NSMutableAttributedString *)attachmentStringWithEmojiImage:(UIImage *)image
                                                              fontSize:(CGFloat)fontSize;

#pragma mark - Utility
///=============================================================================
/// @name Utility
///=============================================================================

/**
 Returns NSMakeRange(0, self.length).
 返回字符串的真个range
 */
- (NSRange)rangeOfAll;

/**
 If YES, it share the same attribute in entire text range.
 整个字符串是否是相同的属性
 */
- (BOOL)isSharedAttributesInAllRange;

/**
 If YES, it can be drawn with the [drawWithRect:options:context:] method or displayed with UIKit.
 If NO, it should be drawn with CoreText or YYText.
 
 如果YES使用[drawWithRect:options:context:]绘制或者使用UIKit绘制，如果为NO，使用CoreText或者YYText
 如果返回NO，也就是意味着最少有一个属性不支持使用UIKit，如果仍然使用UIKit展示，可能会丢失一些属性或者crash
 
 @discussion If the method returns NO, it means that there's at least one attribute 
 which is not supported by UIKit (such as CTParagraphStyleRef). If display this string
 in UIKit, it may lose some attribute, or even crash the app.
 */
- (BOOL)canDrawWithUIKit;

@end




/**
 Set pre-defined attributes to attributed string.
 All properties defined in UIKit, CoreText and YYText are included.
 为属性字符串设置与定义的属性
 */
@interface NSMutableAttributedString (YYText)

#pragma mark - Set character attribute
///=============================================================================
/// @name Set character attribute
///=============================================================================

/**
 Sets the attributes to the entire text string.
 
 为整个text设置属性
 
 @discussion The old attributes will be removed.
 
 @param attributes  A dictionary containing the attributes to set, or nil to remove all attributes.
 */
- (void)setAttributes:(nullable NSDictionary<NSString *, id> *)attributes;

/**
 Sets an attribute with the given name and value to the entire text string.
 
 根据属性名字设置属性，作用与整个字符串
 
 @param name   A string specifying the attribute name.
 @param value  The attribute value associated with name. Pass `nil` or `NSNull` to
 remove the attribute.
 */
- (void)setAttribute:(NSString *)name value:(nullable id)value;

/**
 Sets an attribute with the given name and value to the characters in the specified range.
 
 根据属性名字设置指定范围内的字符属性
 
 @param name   A string specifying the attribute name.
 @param value  The attribute value associated with name. Pass `nil` or `NSNull` to
 remove the attribute.
 @param range  The range of characters to which the specified attribute/value pair applies.
 */
- (void)setAttribute:(NSString *)name value:(nullable id)value range:(NSRange)range;

/**
 Removes all attributes in the specified range.
 
 移除指定范围内的所有属性
 
 @param range  The range of characters.
 */
- (void)removeAttributesInRange:(NSRange)range;


#pragma mark - Set character attribute as property
///=============================================================================
/// @name Set character attribute as property
///=============================================================================

/**
 The font of the text.
 
 设置字体
 
 @discussion Default is Helvetica (Neue) 12.
 @discussion Set this property applies to the entire text string.
             Get this property returns the first character's attribute.
 @since CoreText:3.2  UIKit:6.0  YYKit:6.0
 */
@property (nullable, nonatomic, strong, readwrite) UIFont *font;
- (void)setFont:(nullable UIFont *)font range:(NSRange)range;

/**
 A kerning adjustment.
 
 字距调节
 
 @discussion Default is standard kerning. The kerning attribute indicate how many 
 points the following character should be shifted from its default offset as 
 defined by the current character's font in points; a positive kern indicates a 
 shift farther along and a negative kern indicates a shift closer to the current 
 character. If this attribute is not present, standard kerning will be used. 
 If this attribute is set to 0.0, no kerning will be done at all.
 @discussion Set this property applies to the entire text string.
             Get this property returns the first character's attribute.
 @since CoreText:3.2  UIKit:6.0  YYKit:6.0
 */
@property (nullable, nonatomic, strong, readwrite) NSNumber *kern;
- (void)setKern:(nullable NSNumber *)kern range:(NSRange)range;

/**
 The foreground color.
 
 设置foreground颜色
 
 @discussion Default is Black.
 @discussion Set this property applies to the entire text string.
             Get this property returns the first character's attribute.
 @since CoreText:3.2  UIKit:6.0  YYKit:6.0
 */
@property (nullable, nonatomic, strong, readwrite) UIColor *color;
- (void)setColor:(nullable UIColor *)color range:(NSRange)range;

/**
 The background color.
 
 设置背景颜色
 
 @discussion Default is nil (or no background).
 @discussion Set this property applies to the entire text string.
             Get this property returns the first character's attribute.
 @since UIKit:6.0
 */
@property (nullable, nonatomic, strong, readwrite) UIColor *backgroundColor;
- (void)setBackgroundColor:(nullable UIColor *)backgroundColor range:(NSRange)range;

/**
 The stroke width.
 
 设置笔画宽度，负值填充效果，正值中空效果
 
 @discussion Default value is 0.0 (no stroke). This attribute, interpreted as
 a percentage of font point size, controls the text drawing mode: positive 
 values effect drawing with stroke only; negative values are for stroke and fill.
 A typical value for outlined text is 3.0.
 @discussion Set this property applies to the entire text string.
             Get this property returns the first character's attribute.
 @since CoreText:3.2  UIKit:6.0  YYKit:6.0
 */
@property (nullable, nonatomic, strong, readwrite) NSNumber *strokeWidth;
- (void)setStrokeWidth:(nullable NSNumber *)strokeWidth range:(NSRange)range;

/**
 The stroke color.
 
 填充部分颜色，不是字体颜色
 
 @discussion Default value is nil (same as foreground color).
 @discussion Set this property applies to the entire text string.
             Get this property returns the first character's attribute.
 @since CoreText:3.2  UIKit:6.0  YYKit:6.0
 */
@property (nullable, nonatomic, strong, readwrite) UIColor *strokeColor;
- (void)setStrokeColor:(nullable UIColor *)strokeColor range:(NSRange)range;

/**
 The text shadow.
 
 设置文本阴影
 
 @discussion Default value is nil (no shadow).
 @discussion Set this property applies to the entire text string.
             Get this property returns the first character's attribute.
 @since UIKit:6.0  YYKit:6.0
 */
@property (nullable, nonatomic, strong, readwrite) NSShadow *shadow;
- (void)setShadow:(nullable NSShadow *)shadow range:(NSRange)range;

/**
 The strikethrough style.
 
 设置删除线样式
 
 @discussion Default value is NSUnderlineStyleNone (no strikethrough).
 @discussion Set this property applies to the entire text string.
             Get this property returns the first character's attribute.
 @since UIKit:6.0
 */
@property (nonatomic, readwrite) NSUnderlineStyle strikethroughStyle;
- (void)setStrikethroughStyle:(NSUnderlineStyle)strikethroughStyle range:(NSRange)range;

/**
 The strikethrough color.
 
 设置删除线颜色
 
 @discussion Default value is nil (same as foreground color).
 @discussion Set this property applies to the entire text string.
             Get this property returns the first character's attribute.
 @since UIKit:7.0
 */
@property (nullable, nonatomic, strong, readwrite) UIColor *strikethroughColor;
- (void)setStrikethroughColor:(nullable UIColor *)strikethroughColor range:(NSRange)range NS_AVAILABLE_IOS(7_0);

/**
 The underline style.
 
 设置下划线样式
 
 @discussion Default value is NSUnderlineStyleNone (no underline).
 @discussion Set this property applies to the entire text string.
             Get this property returns the first character's attribute.
 @since CoreText:3.2  UIKit:6.0
 */
@property (nonatomic, readwrite) NSUnderlineStyle underlineStyle;
- (void)setUnderlineStyle:(NSUnderlineStyle)underlineStyle range:(NSRange)range;

/**
 The underline color.
 
 设置下划线颜色
 
 @discussion Default value is nil (same as foreground color).
 @discussion Set this property applies to the entire text string.
             Get this property returns the first character's attribute.
 @since CoreText:3.2  UIKit:7.0
 */
@property (nullable, nonatomic, strong, readwrite) UIColor *underlineColor;
- (void)setUnderlineColor:(nullable UIColor *)underlineColor range:(NSRange)range;

/**
 Ligature formation control.
 
 连字形成控制
 
 @discussion Default is int value 1. The ligature attribute determines what kinds 
 of ligatures should be used when displaying the string. A value of 0 indicates 
 that only ligatures essential for proper rendering of text should be used, 
 1 indicates that standard ligatures should be used, and 2 indicates that all 
 available ligatures should be used. Which ligatures are standard depends on the 
 script and possibly the font.
 @discussion Set this property applies to the entire text string.
             Get this property returns the first character's attribute.
 @since CoreText:3.2  UIKit:6.0  YYKit:6.0
 */
@property (nullable, nonatomic, strong, readwrite) NSNumber *ligature;
- (void)setLigature:(nullable NSNumber *)ligature range:(NSRange)range;

/**
 The text effect.
 
 设置文字效果
 
 @discussion Default is nil (no effect). The only currently supported value
 is NSTextEffectLetterpressStyle.
 @discussion Set this property applies to the entire text string.
             Get this property returns the first character's attribute.
 @since UIKit:7.0
 */
@property (nullable, nonatomic, strong, readwrite) NSString *textEffect;
- (void)setTextEffect:(nullable NSString *)textEffect range:(NSRange)range NS_AVAILABLE_IOS(7_0);

/**
 The skew to be applied to glyphs.
 
 设置字形的倾斜度
 
 @discussion Default is 0 (no skew).
 @discussion Set this property applies to the entire text string.
             Get this property returns the first character's attribute.
 @since UIKit:7.0
 */
@property (nullable, nonatomic, strong, readwrite) NSNumber *obliqueness;
- (void)setObliqueness:(nullable NSNumber *)obliqueness range:(NSRange)range NS_AVAILABLE_IOS(7_0);

/**
 The log of the expansion factor to be applied to glyphs.
 
 设置文本横向拉伸属性
 
 @discussion Default is 0 (no expansion).
 @discussion Set this property applies to the entire text string.
             Get this property returns the first character's attribute.
 @since UIKit:7.0
 */
@property (nullable, nonatomic, strong, readwrite) NSNumber *expansion;
- (void)setExpansion:(nullable NSNumber *)expansion range:(NSRange)range NS_AVAILABLE_IOS(7_0);

/**
 The character's offset from the baseline, in points.
 
 设置基线偏移值,正值上偏，负值下偏
 
 @discussion Default is 0.
 @discussion Set this property applies to the entire text string.
             Get this property returns the first character's attribute.
 @since UIKit:7.0
 */
@property (nullable, nonatomic, strong, readwrite) NSNumber *baselineOffset;
- (void)setBaselineOffset:(nullable NSNumber *)baselineOffset range:(NSRange)range NS_AVAILABLE_IOS(7_0);

/**
 Glyph orientation control.
 
 文字排版方向是否是垂直的
 
 @discussion Default is NO. A value of NO indicates that horizontal glyph forms 
 are to be used, YES indicates that vertical glyph forms are to be used.
 @discussion Set this property applies to the entire text string.
             Get this property returns the first character's attribute.
 @since CoreText:4.3  YYKit:6.0
 */
@property (nonatomic, readwrite) BOOL verticalGlyphForm;
- (void)setVerticalGlyphForm:(BOOL)verticalGlyphForm range:(NSRange)range;

/**
 Specifies text language.
 
 设置指定范围的文本语言
 
 @discussion Value must be a NSString containing a locale identifier. Default is 
 unset. When this attribute is set to a valid identifier, it will be used to select 
 localized glyphs (if supported by the font) and locale-specific line breaking rules.
 @discussion Set this property applies to the entire text string.
             Get this property returns the first character's attribute.
 @since CoreText:7.0  YYKit:7.0
 */
@property (nullable, nonatomic, strong, readwrite) NSString *language;
- (void)setLanguage:(nullable NSString *)language range:(NSRange)range NS_AVAILABLE_IOS(7_0);

/**
 Specifies a bidirectional override or embedding.
 
 设置文字书写方向
 
 @discussion See alse NSWritingDirection and NSWritingDirectionAttributeName.
 @discussion Set this property applies to the entire text string.
             Get this property returns the first character's attribute.
 @since CoreText:6.0  UIKit:7.0  YYKit:6.0
 */
@property (nullable, nonatomic, strong, readwrite) NSArray<NSNumber *> *writingDirection;
- (void)setWritingDirection:(nullable NSArray<NSNumber *> *)writingDirection range:(NSRange)range;

/**
 An NSParagraphStyle object which is used to specify things like
 line alignment, tab rulers, writing direction, etc.
 
 设置段落样式
 
 @discussion Default is nil ([NSParagraphStyle defaultParagraphStyle]).
 @discussion Set this property applies to the entire text string.
             Get this property returns the first character's attribute.
 @since CoreText:6.0  UIKit:6.0  YYKit:6.0
 */
@property (nullable, nonatomic, strong, readwrite) NSParagraphStyle *paragraphStyle;
- (void)setParagraphStyle:(nullable NSParagraphStyle *)paragraphStyle range:(NSRange)range;


#pragma mark - Set paragraph attribute as property
///=============================================================================
/// @name Set paragraph attribute as property
///=============================================================================

/**
 The text alignment (A wrapper for NSParagraphStyle).
 
 设置文本对齐方式
 
 @discussion Natural text alignment is realized as left or right alignment
 depending on the line sweep direction of the first script contained in the paragraph.
 @discussion Default is NSTextAlignmentNatural.
 @discussion Set this property applies to the entire text string.
             Get this property returns the first character's attribute.
 @since CoreText:6.0  UIKit:6.0  YYKit:6.0
 */
@property (nonatomic, readwrite) NSTextAlignment alignment;
- (void)setAlignment:(NSTextAlignment)alignment range:(NSRange)range;

/**
 The mode that should be used to break lines (A wrapper for NSParagraphStyle).
 
 换行模式
 
 @discussion This property contains the line break mode to be used laying out the paragraph's text.
 @discussion Default is NSLineBreakByWordWrapping.
 @discussion Set this property applies to the entire text string.
             Get this property returns the first character's attribute.
 @since CoreText:6.0  UIKit:6.0  YYKit:6.0
 */
@property (nonatomic, readwrite) NSLineBreakMode lineBreakMode;
- (void)setLineBreakMode:(NSLineBreakMode)lineBreakMode range:(NSRange)range;

/**
 The distance in points between the bottom of one line fragment and the top of the next.
 (A wrapper for NSParagraphStyle)
 
 行距
 
 @discussion This value is always nonnegative. This value is included in the line
 fragment heights in the layout manager.
 @discussion Default is 0.
 @discussion Set this property applies to the entire text string.
             Get this property returns the first character's attribute.
 @since CoreText:6.0  UIKit:6.0  YYKit:6.0
 */
@property (nonatomic, readwrite) CGFloat lineSpacing;
- (void)setLineSpacing:(CGFloat)lineSpacing range:(NSRange)range;

/**
 The space after the end of the paragraph (A wrapper for NSParagraphStyle).
 
 段落之后距离
 
 @discussion This property contains the space (measured in points) added at the
 end of the paragraph to separate it from the following paragraph. This value must
 be nonnegative. The space between paragraphs is determined by adding the previous
 paragraph's paragraphSpacing and the current paragraph's paragraphSpacingBefore.
 @discussion Default is 0.
 @discussion Set this property applies to the entire text string.
             Get this property returns the first character's attribute.
 @since CoreText:6.0  UIKit:6.0  YYKit:6.0
 */
@property (nonatomic, readwrite) CGFloat paragraphSpacing;
- (void)setParagraphSpacing:(CGFloat)paragraphSpacing range:(NSRange)range;

/**
 The distance between the paragraph's top and the beginning of its text content.
 (A wrapper for NSParagraphStyle).
 
 段落的顶部距离开始文本的距离
 
 @discussion This property contains the space (measured in points) between the
 paragraph's top and the beginning of its text content.
 @discussion Default is 0.
 @discussion Set this property applies to the entire text string.
             Get this property returns the first character's attribute.
 @since CoreText:6.0  UIKit:6.0  YYKit:6.0
 */
@property (nonatomic, readwrite) CGFloat paragraphSpacingBefore;
- (void)setParagraphSpacingBefore:(CGFloat)paragraphSpacingBefore range:(NSRange)range;

/**
 The indentation of the first line (A wrapper for NSParagraphStyle).
 
 首行缩进
 
 @discussion This property contains the distance (in points) from the leading margin
 of a text container to the beginning of the paragraph's first line. This value
 is always nonnegative.
 @discussion Default is 0.
 @discussion Set this property applies to the entire text string.
             Get this property returns the first character's attribute.
 @since CoreText:6.0  UIKit:6.0  YYKit:6.0
 */
@property (nonatomic, readwrite) CGFloat firstLineHeadIndent;
- (void)setFirstLineHeadIndent:(CGFloat)firstLineHeadIndent range:(NSRange)range;

/**
 The indentation of the receiver's lines other than the first. (A wrapper for NSParagraphStyle).
 
 一般行的缩进
 
 @discussion This property contains the distance (in points) from the leading margin
 of a text container to the beginning of lines other than the first. This value is
 always nonnegative.
 @discussion Default is 0.
 @discussion Set this property applies to the entire text string.
             Get this property returns the first character's attribute.
 @since CoreText:6.0  UIKit:6.0  YYKit:6.0
 */
@property (nonatomic, readwrite) CGFloat headIndent;
- (void)setHeadIndent:(CGFloat)headIndent range:(NSRange)range;

/**
 The trailing indentation (A wrapper for NSParagraphStyle).
 
 段落尾部缩进
 
 @discussion If positive, this value is the distance from the leading margin
 (for example, the left margin in left-to-right text). If 0 or negative, it's the
 distance from the trailing margin.
 @discussion Default is 0.
 @discussion Set this property applies to the entire text string.
             Get this property returns the first character's attribute.
 @since CoreText:6.0  UIKit:6.0  YYKit:6.0
 */
@property (nonatomic, readwrite) CGFloat tailIndent;
- (void)setTailIndent:(CGFloat)tailIndent range:(NSRange)range;

/**
 The receiver's minimum height (A wrapper for NSParagraphStyle).
 
 最小行高度
 
 @discussion This property contains the minimum height in points that any line in
 the receiver will occupy, regardless of the font size or size of any attached graphic.
 This value must be nonnegative.
 @discussion Default is 0.
 @discussion Set this property applies to the entire text string.
             Get this property returns the first character's attribute.
 @since CoreText:6.0  UIKit:6.0  YYKit:6.0
 */
@property (nonatomic, readwrite) CGFloat minimumLineHeight;
- (void)setMinimumLineHeight:(CGFloat)minimumLineHeight range:(NSRange)range;

/**
 The receiver's maximum line height (A wrapper for NSParagraphStyle).
 
 最大行高度
 
 @discussion This property contains the maximum height in points that any line in
 the receiver will occupy, regardless of the font size or size of any attached graphic.
 This value is always nonnegative. Glyphs and graphics exceeding this height will
 overlap neighboring lines; however, a maximum height of 0 implies no line height limit.
 Although this limit applies to the line itself, line spacing adds extra space between adjacent lines.
 @discussion Default is 0 (no limit).
 @discussion Set this property applies to the entire text string.
             Get this property returns the first character's attribute.
 @since CoreText:6.0  UIKit:6.0  YYKit:6.0
 */
@property (nonatomic, readwrite) CGFloat maximumLineHeight;
- (void)setMaximumLineHeight:(CGFloat)maximumLineHeight range:(NSRange)range;

/**
 The line height multiple (A wrapper for NSParagraphStyle).
 
 行高度倍数
 
 @discussion This property contains the line break mode to be used laying out the paragraph's text.
 @discussion Default is 0 (no multiple).
 @discussion Set this property applies to the entire text string.
             Get this property returns the first character's attribute.
 @since CoreText:6.0  UIKit:6.0  YYKit:6.0
 */
@property (nonatomic, readwrite) CGFloat lineHeightMultiple;
- (void)setLineHeightMultiple:(CGFloat)lineHeightMultiple range:(NSRange)range;

/**
 The base writing direction (A wrapper for NSParagraphStyle).
 
 文字书写方向
 
 @discussion If you specify NSWritingDirectionNaturalDirection, the receiver resolves
 the writing direction to either NSWritingDirectionLeftToRight or NSWritingDirectionRightToLeft,
 depending on the direction for the user's `language` preference setting.
 @discussion Default is NSWritingDirectionNatural.
 @discussion Set this property applies to the entire text string.
             Get this property returns the first character's attribute.
 @since CoreText:6.0  UIKit:6.0  YYKit:6.0
 */
@property (nonatomic, readwrite) NSWritingDirection baseWritingDirection;
- (void)setBaseWritingDirection:(NSWritingDirection)baseWritingDirection range:(NSRange)range;

/**
 The paragraph's threshold for hyphenation. (A wrapper for NSParagraphStyle).
 
 @discussion Valid values lie between 0.0 and 1.0 inclusive. Hyphenation is attempted
 when the ratio of the text width (as broken without hyphenation) to the width of the
 line fragment is less than the hyphenation factor. When the paragraph's hyphenation
 factor is 0.0, the layout manager's hyphenation factor is used instead. When both
 are 0.0, hyphenation is disabled.
 @discussion Default is 0.
 @discussion Set this property applies to the entire text string.
             Get this property returns the first character's attribute.
 @since UIKit:6.0
 */
@property (nonatomic, readwrite) float hyphenationFactor;
- (void)setHyphenationFactor:(float)hyphenationFactor range:(NSRange)range;

/**
 The document-wide default tab interval (A wrapper for NSParagraphStyle).
 
 @discussion This property represents the default tab interval in points. Tabs after the
 last specified in tabStops are placed at integer multiples of this distance (if positive).
 @discussion Default is 0.
 @discussion Set this property applies to the entire text string.
             Get this property returns the first character's attribute.
 @since CoreText:7.0  UIKit:7.0  YYKit:7.0
 */
@property (nonatomic, readwrite) CGFloat defaultTabInterval;
- (void)setDefaultTabInterval:(CGFloat)defaultTabInterval range:(NSRange)range NS_AVAILABLE_IOS(7_0);

/**
 An array of NSTextTab objects representing the receiver's tab stops.
 (A wrapper for NSParagraphStyle).
 
 @discussion The NSTextTab objects, sorted by location, define the tab stops for
 the paragraph style.
 @discussion Default is 12 TabStops with 28.0 tab interval.
 @discussion Set this property applies to the entire text string.
             Get this property returns the first character's attribute.
 @since CoreText:7.0  UIKit:7.0  YYKit:7.0
 */
@property (nullable, nonatomic, copy, readwrite) NSArray<NSTextTab *> *tabStops;
- (void)setTabStops:(nullable NSArray<NSTextTab *> *)tabStops range:(NSRange)range NS_AVAILABLE_IOS(7_0);

#pragma mark - Set YYText attribute as property
///=============================================================================
/// @name Set YYText attribute as property
///=============================================================================

/**
 The text shadow.
 
 文字阴影
 
 @discussion Default value is nil (no shadow).
 @discussion Set this property applies to the entire text string.
             Get this property returns the first character's attribute.
 @since YYKit:6.0
 */
@property (nullable, nonatomic, strong, readwrite) YYTextShadow *textShadow;
- (void)setTextShadow:(nullable YYTextShadow *)textShadow range:(NSRange)range;

/**
 The text inner shadow.
 
 内部阴影
 
 @discussion Default value is nil (no shadow).
 @discussion Set this property applies to the entire text string.
             Get this property returns the first character's attribute.
 @since YYKit:6.0
 */
@property (nullable, nonatomic, strong, readwrite) YYTextShadow *textInnerShadow;
- (void)setTextInnerShadow:(nullable YYTextShadow *)textInnerShadow range:(NSRange)range;

/**
 The text underline.
 
 下划线
 
 @discussion Default value is nil (no underline).
 @discussion Set this property applies to the entire text string.
             Get this property returns the first character's attribute.
 @since YYKit:6.0
 */
@property (nullable, nonatomic, strong, readwrite) YYTextDecoration *textUnderline;
- (void)setTextUnderline:(nullable YYTextDecoration *)textUnderline range:(NSRange)range;

/**
 The text strikethrough.
 
 删除线
 
 @discussion Default value is nil (no strikethrough).
 @discussion Set this property applies to the entire text string.
             Get this property returns the first character's attribute.
 @since YYKit:6.0
 */
@property (nullable, nonatomic, strong, readwrite) YYTextDecoration *textStrikethrough;
- (void)setTextStrikethrough:(nullable YYTextDecoration *)textStrikethrough range:(NSRange)range;

/**
 The text border.
 
 文本边界线
 
 @discussion Default value is nil (no border).
 @discussion Set this property applies to the entire text string.
             Get this property returns the first character's attribute.
 @since YYKit:6.0
 */
@property (nullable, nonatomic, strong, readwrite) YYTextBorder *textBorder;
- (void)setTextBorder:(nullable YYTextBorder *)textBorder range:(NSRange)range;

/**
 The text background border.
 
 文本背景边界线
 
 @discussion Default value is nil (no background border).
 @discussion Set this property applies to the entire text string.
             Get this property returns the first character's attribute.
 @since YYKit:6.0
 */
@property (nullable, nonatomic, strong, readwrite) YYTextBorder *textBackgroundBorder;
- (void)setTextBackgroundBorder:(nullable YYTextBorder *)textBackgroundBorder range:(NSRange)range;

/**
 The glyph transform.
 
 字形转换
 
 @discussion Default value is CGAffineTransformIdentity (no transform).
 @discussion Set this property applies to the entire text string.
             Get this property returns the first character's attribute.
 @since YYKit:6.0
 */
@property (nonatomic, readwrite) CGAffineTransform textGlyphTransform;
- (void)setTextGlyphTransform:(CGAffineTransform)textGlyphTransform range:(NSRange)range;


#pragma mark - Set discontinuous attribute for range
///=============================================================================
/// @name Set discontinuous attribute for range
///=============================================================================

- (void)setSuperscript:(nullable NSNumber *)superscript range:(NSRange)range;
- (void)setGlyphInfo:(nullable CTGlyphInfoRef)glyphInfo range:(NSRange)range;
- (void)setCharacterShape:(nullable NSNumber *)characterShape range:(NSRange)range;
- (void)setRunDelegate:(nullable CTRunDelegateRef)runDelegate range:(NSRange)range;
- (void)setBaselineClass:(nullable CFStringRef)baselineClass range:(NSRange)range;
- (void)setBaselineInfo:(nullable CFDictionaryRef)baselineInfo range:(NSRange)range;
- (void)setBaselineReferenceInfo:(nullable CFDictionaryRef)referenceInfo range:(NSRange)range;
- (void)setRubyAnnotation:(nullable CTRubyAnnotationRef)ruby range:(NSRange)range NS_AVAILABLE_IOS(8_0);
- (void)setAttachment:(nullable NSTextAttachment *)attachment range:(NSRange)range NS_AVAILABLE_IOS(7_0);
- (void)setLink:(nullable id)link range:(NSRange)range NS_AVAILABLE_IOS(7_0);
- (void)setTextBackedString:(nullable YYTextBackedString *)textBackedString range:(NSRange)range;
- (void)setTextBinding:(nullable YYTextBinding *)textBinding range:(NSRange)range;
- (void)setTextAttachment:(nullable YYTextAttachment *)textAttachment range:(NSRange)range;
- (void)setTextHighlight:(nullable YYTextHighlight *)textHighlight range:(NSRange)range;
- (void)setTextBlockBorder:(nullable YYTextBorder *)textBlockBorder range:(NSRange)range;
- (void)setTextRubyAnnotation:(nullable YYTextRubyAnnotation *)ruby range:(NSRange)range NS_AVAILABLE_IOS(8_0);


#pragma mark - Convenience methods for text highlight
///=============================================================================
/// @name Convenience methods for text highlight
///=============================================================================

/**
 Convenience method to set text highlight
 
 设置文本的高亮（可以交互）状态
 
 @param range           text range
 @param color           text color (pass nil to ignore)
 @param backgroundColor text background color when highlight
 @param userInfo        user information dictionary (pass nil to ignore)
 @param tapAction       tap action when user tap the highlight (pass nil to ignore)
 @param longPressAction long press action when user long press the highlight (pass nil to ignore)
 */
- (void)setTextHighlightRange:(NSRange)range
                        color:(nullable UIColor *)color
              backgroundColor:(nullable UIColor *)backgroundColor
                     userInfo:(nullable NSDictionary *)userInfo
                    tapAction:(nullable YYTextAction)tapAction
              longPressAction:(nullable YYTextAction)longPressAction;

/**
 Convenience method to set text highlight
 
 @param range           text range
 @param color           text color (pass nil to ignore)
 @param backgroundColor text background color when highlight
 @param tapAction       tap action when user tap the highlight (pass nil to ignore)
 */
- (void)setTextHighlightRange:(NSRange)range
                        color:(nullable UIColor *)color
              backgroundColor:(nullable UIColor *)backgroundColor
                    tapAction:(nullable YYTextAction)tapAction;

/**
 Convenience method to set text highlight
 
 @param range           text range
 @param color           text color (pass nil to ignore)
 @param backgroundColor text background color when highlight
 @param userInfo        tap action when user tap the highlight (pass nil to ignore)
 */
- (void)setTextHighlightRange:(NSRange)range
                        color:(nullable UIColor *)color
              backgroundColor:(nullable UIColor *)backgroundColor
                     userInfo:(nullable NSDictionary *)userInfo;

#pragma mark - Utilities
///=============================================================================
/// @name Utilities
///=============================================================================

/**
 Inserts into the receiver the characters of a given string at a given location.
 The new string inherit the attributes of the first replaced character from location.
 
 消息接收者在指定位置插入给定的字符串。新的字符串继承插入位置被替换的字符的属性
 
 @param string  The string to insert into the receiver, must not be nil.
 @param location The location at which string is inserted. The location must not 
    exceed the bounds of the receiver.
 @throw Raises an NSRangeException if the location out of bounds.
 */
- (void)insertString:(NSString *)string atIndex:(NSUInteger)location;

/**
 Adds to the end of the receiver the characters of a given string.
 The new string inherit the attributes of the receiver's tail.
 
 将给定字符串插入消息接收者的后边。新的字符串继承消息接收者末尾字符的属性
 
 @param string  The string to append to the receiver, must not be nil.
 */
- (void)appendString:(NSString *)string;

/**
 Set foreground color with [UIColor clearColor] in joined-emoji range.
 Emoji drawing will not be affected by the foreground color.
 
 在emoji的方位内前景色设置成clearColor，emoji绘制不受前景色的影响
 
 @discussion In iOS 8.3, Apple releases some new diversified emojis. 
 There's some single emoji which can be assembled to a new 'joined-emoji'.
 The joiner is unicode character 'ZERO WIDTH JOINER' (U+200D).
 For example: 👨👩👧👧 -> 👨‍👩‍👧‍👧.
 
 When there are more than 5 'joined-emoji' in a same CTLine, CoreText may render some
 extra glyphs above the emoji. It's a bug in CoreText, try this method to avoid.
 This bug is fixed in iOS 9.
 */
- (void)setClearColorToJoinedEmoji;

/**
 Removes all discontinuous attributes in a specified range.
 See `allDiscontinuousAttributeKeys`.
 
 移除指定范围内所有不连续的属性
 
 @param range A text range.
 */
- (void)removeDiscontinuousAttributesInRange:(NSRange)range;

/**
 Returns all discontinuous attribute keys, such as RunDelegate/Attachment/Ruby.
 
 返回所有不连续属性的key，例如RunDelegate/Attachment/Ruby
 
 @discussion These attributes can only set to a specified range of text, and
 should not extend to other range when editing text.
 */
+ (NSArray<NSString *> *)allDiscontinuousAttributeKeys;

@end

NS_ASSUME_NONNULL_END
