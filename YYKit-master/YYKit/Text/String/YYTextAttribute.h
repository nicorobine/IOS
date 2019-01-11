//
//  YYTextAttribute.h
//  YYKit <https://github.com/ibireme/YYKit>
//
//  Created by ibireme on 14/10/26.
//  Copyright (c) 2015 ibireme.
//
//  This source code is licensed under the MIT-style license found in the
//  LICENSE file in the root directory of this source tree.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

#pragma mark - Enum Define

/// The attribute type
// 属性类型
typedef NS_OPTIONS(NSInteger, YYTextAttributeType) {
    YYTextAttributeTypeNone     = 0,
    // UIKit属性
    YYTextAttributeTypeUIKit    = 1 << 0, ///< UIKit attributes, such as UILabel/UITextField/drawInRect.
    // CoreText属性
    YYTextAttributeTypeCoreText = 1 << 1, ///< CoreText attributes, used by CoreText.
    // YYText属性
    YYTextAttributeTypeYYText   = 1 << 2, ///< YYText attributes, used by YYText.
};

/// Get the attribute type from an attribute name.
// 根据属性名字获取属性类型
extern YYTextAttributeType YYTextAttributeGetType(NSString *attributeName);

/**
 Line style in YYText (similar to NSUnderlineStyle).
 */
typedef NS_OPTIONS (NSInteger, YYTextLineStyle) {
    // basic style (bitmask:0xFF)
    YYTextLineStyleNone       = 0x00, ///< (        ) Do not draw a line (Default). 不要画线
    YYTextLineStyleSingle     = 0x01, ///< (──────) Draw a single line. 画一条线
    YYTextLineStyleThick      = 0x02, ///< (━━━━━━━) Draw a thick line. 画一条粗线
    YYTextLineStyleDouble     = 0x09, ///< (══════) Draw a double line. 画一条双线
    
    // style pattern (bitmask:0xF00)
    YYTextLineStylePatternSolid      = 0x000, ///< (────────) Draw a solid line (Default). 画一条实线
    YYTextLineStylePatternDot        = 0x100, ///< (‑ ‑ ‑ ‑ ‑ ‑) Draw a line of dots. 画一条点线
    YYTextLineStylePatternDash       = 0x200, ///< (— — — —) Draw a line of dashes. 画一条破折号线
    YYTextLineStylePatternDashDot    = 0x300, ///< (— ‑ — ‑ — ‑) Draw a line of alternating dashes and dots. 破折号和点交替的线
    YYTextLineStylePatternDashDotDot = 0x400, ///< (— ‑ ‑ — ‑ ‑) Draw a line of alternating dashes and two dots. 破折号和两个点交替的线
    YYTextLineStylePatternCircleDot  = 0x900, ///< (••••••••••••) Draw a line of small circle dots. 小圆点组成的线
};

/**
 Text vertical alignment.
 文字垂直对齐
 */
typedef NS_ENUM(NSInteger, YYTextVerticalAlignment) {
    YYTextVerticalAlignmentTop =    0, ///< Top alignment. 顶部对齐
    YYTextVerticalAlignmentCenter = 1, ///< Center alignment. 中心对齐
    YYTextVerticalAlignmentBottom = 2, ///< Bottom alignment. 底部对齐
};

/**
 The direction define in YYText.
 YYText中定义的文本方向
 */
typedef NS_OPTIONS(NSUInteger, YYTextDirection) {
    YYTextDirectionNone   = 0,
    YYTextDirectionTop    = 1 << 0,
    YYTextDirectionRight  = 1 << 1,
    YYTextDirectionBottom = 1 << 2,
    YYTextDirectionLeft   = 1 << 3,
};

/**
 The trunction type, tells the truncation engine which type of truncation is being requested.
 截断类型，告诉截断引擎正在请求哪种类型的截断
 */
typedef NS_ENUM (NSUInteger, YYTextTruncationType) {
    /// No truncate.
    YYTextTruncationTypeNone   = 0,
    
    /// Truncate at the beginning of the line, leaving the end portion visible.
    // 在行的开头截断，使末尾部分可见
    YYTextTruncationTypeStart  = 1,
    
    /// Truncate at the end of the line, leaving the start portion visible.
    // 在行的末尾截断，使头部可见
    YYTextTruncationTypeEnd    = 2,
    
    /// Truncate in the middle of the line, leaving both the start and the end portions visible.
    // 在行的中间截断，头部和尾部可见
    YYTextTruncationTypeMiddle = 3,
};



#pragma mark - Attribute Name Defined in YYText

/// The value of this attribute is a `YYTextBackedString` object.
/// Use this attribute to store the original plain text if it is replaced by something else (such as attachment).
/// 如果原始纯文本被其他内容替换（如attachment），用此属性储存原始纯文本，这个key储存的对象是YYTextBackedString类型的对象
UIKIT_EXTERN NSString *const YYTextBackedStringAttributeName;

/// The value of this attribute is a `YYTextBinding` object.
/// Use this attribute to bind a range of text together, as if it was a single charactor.
/// 使用此属性将一定范围的文本绑定在一起，就是一个字符一样使用，这个key储存的是YYTextBinding类型的对象
UIKIT_EXTERN NSString *const YYTextBindingAttributeName;

/// The value of this attribute is a `YYTextShadow` object.
/// Use this attribute to add shadow to a range of text.
/// Shadow will be drawn below text glyphs. Use YYTextShadow.subShadow to add multi-shadow.
/// 使用这个属性可以为指定范围内的文本设置阴影，阴影会被绘制在文本字形下面，使用YYTextShadow.addShadow添加多个阴影，
/// 这个key储存的是是YYTextShadow类型的对象
UIKIT_EXTERN NSString *const YYTextShadowAttributeName;

/// The value of this attribute is a `YYTextShadow` object.
/// Use this attribute to add inner shadow to a range of text.
/// Inner shadow will be drawn above text glyphs. Use YYTextShadow.subShadow to add multi-shadow.
/// 使用这个属性可以为指定范围内的文本添加内部阴影，内部阴影会绘制到文本字形的上面，使用YYTextShadow.subShadow添加多个阴影，
/// 这个key储存的是YYTextShadow类型的对象
UIKIT_EXTERN NSString *const YYTextInnerShadowAttributeName;

/// The value of this attribute is a `YYTextDecoration` object.
/// Use this attribute to add underline to a range of text.
/// The underline will be drawn below text glyphs.
/// 这个属性可以为指定范围内的文本添加下划线，下划线绘制在文本字形的下面
UIKIT_EXTERN NSString *const YYTextUnderlineAttributeName;

/// The value of this attribute is a `YYTextDecoration` object.
/// Use this attribute to add strikethrough (delete line) to a range of text.
/// The strikethrough will be drawn above text glyphs.
/// 这个属性可以为指定范围内的文本添加删除线，删除线绘制在文本字形的上面
/// 这个key储存的是YYTextDecoration类型的对象
UIKIT_EXTERN NSString *const YYTextStrikethroughAttributeName;

/// The value of this attribute is a `YYTextBorder` object.
/// Use this attribute to add cover border or cover color to a range of text.
/// The border will be drawn above the text glyphs.
/// 使用此属性可以为指定范围内的文本添加封面边框或者封面颜色，边框会绘制在文本字形的上面
/// 这个key储存的是YYTextBorder类型的对象
UIKIT_EXTERN NSString *const YYTextBorderAttributeName;

/// The value of this attribute is a `YYTextBorder` object.
/// Use this attribute to add background border or background color to a range of text.
/// The border will be drawn below the text glyphs.
/// 使用此属性可以为指定范围内的文本添加背景边框或者背景颜色，边框会绘制到文本字形的下面
/// 这个key储存YYTextBorder类型的对象
UIKIT_EXTERN NSString *const YYTextBackgroundBorderAttributeName;

/// The value of this attribute is a `YYTextBorder` object.
/// Use this attribute to add a code block border to one or more line of text.
/// The border will be drawn below the text glyphs.
/// 使用此属性可以将代码边框应用到一行或者多行文本，边框绘制到文本字形的下面
/// 这个key储存YYTextBorder类型的对象
UIKIT_EXTERN NSString *const YYTextBlockBorderAttributeName;

/// The value of this attribute is a `YYTextAttachment` object.
/// Use this attribute to add attachment to text.
/// It should be used in conjunction with a CTRunDelegate.
/// 使用此属性可以为文本添加附件，它应该于CTRunDelegate一起使用
/// 这个key储存YYTextAttachment类型的对象
UIKIT_EXTERN NSString *const YYTextAttachmentAttributeName;

/// The value of this attribute is a `YYTextHighlight` object.
/// Use this attribute to add a touchable highlight state to a range of text.
/// 使用此属性可以为指定范围内的文本添加可以触摸的显示突出状态
UIKIT_EXTERN NSString *const YYTextHighlightAttributeName;

/// The value of this attribute is a `NSValue` object stores CGAffineTransform.
/// Use this attribute to add transform to each glyph in a range of text.
/// 使用这个属性可以将转换添加到文本的每一个字形
UIKIT_EXTERN NSString *const YYTextGlyphTransformAttributeName;



#pragma mark - String Token Define

UIKIT_EXTERN NSString *const YYTextAttachmentToken; ///< Object replacement character (U+FFFC), used for text attachment.
UIKIT_EXTERN NSString *const YYTextTruncationToken; ///< Horizontal ellipsis (U+2026), used for text truncation  "…".



#pragma mark - Attribute Value Define

/**
 The tap/long press action callback defined in YYText.
 
 在YYText定义的点击或者长按操作的回调
 
 @param containerView The text container view (such as YYLabel/YYTextView). 容器view
 @param text          The whole text. 整个文本
 @param range         The text range in `text` (if no range, the range.location is NSNotFound). 文本相对于整个文本的范围
 @param rect          The text frame in `containerView` (if no data, the rect is CGRectNull). 文本相对于整个容器的位置
 */
typedef void(^YYTextAction)(UIView *containerView, NSAttributedString *text, NSRange range, CGRect rect);


/**
 YYTextBackedString objects are used by the NSAttributedString class cluster
 as the values for text backed string attributes (stored in the attributed 
 string under the key named YYTextBackedStringAttributeName).
 
 文本被替换之前的原始文本，可以用作复制粘贴
 
 It may used for copy/paste plain text from attributed string.
 Example: If :) is replace by a custom emoji (such as😊), the backed string can be set to @":)".
 */
@interface YYTextBackedString : NSObject <NSCoding, NSCopying>
+ (instancetype)stringWithString:(nullable NSString *)string;
@property (nullable, nonatomic, copy) NSString *string; ///< backed string
@end


/**
 YYTextBinding objects are used by the NSAttributedString class cluster
 as the values for shadow attributes (stored in the attributed string under
 the key named YYTextBindingAttributeName).
 
 在文本选择或编辑期间，YYTextView会将绑定的文本当作单个字符
 
 Add this to a range of text will make the specified characters 'binding together'.
 YYTextView will treat the range of text as a single character during text 
 selection and edit.
 */
@interface YYTextBinding : NSObject <NSCoding, NSCopying>
+ (instancetype)bindingWithDeleteConfirm:(BOOL)deleteConfirm;
@property (nonatomic) BOOL deleteConfirm; ///< confirm the range when delete in YYTextView
@end


/**
 YYTextShadow objects are used by the NSAttributedString class cluster
 as the values for shadow attributes (stored in the attributed string under
 the key named YYTextShadowAttributeName or YYTextInnerShadowAttributeName).
 
 类似于NSShadow，但是YYTextShadow提供了更多的功能
 
 It's similar to `NSShadow`, but offers more options.
 */
@interface YYTextShadow : NSObject <NSCoding, NSCopying>
+ (instancetype)shadowWithColor:(nullable UIColor *)color offset:(CGSize)offset radius:(CGFloat)radius;

@property (nullable, nonatomic, strong) UIColor *color; ///< shadow color 阴影颜色
@property (nonatomic) CGSize offset;                    ///< shadow offset 阴影偏移
@property (nonatomic) CGFloat radius;                   ///< shadow blur radius 阴影模糊半径
@property (nonatomic) CGBlendMode blendMode;            ///< shadow blend mode 阴影混合模式
@property (nullable, nonatomic, strong) YYTextShadow *subShadow;  ///< a sub shadow which will be added above the parent shadow 可以在原来shadow的基础上添加子shadow

// YYTextShadow和NSShadow的相互转换
+ (instancetype)shadowWithNSShadow:(NSShadow *)nsShadow; ///< convert NSShadow to YYTextShadow
- (NSShadow *)nsShadow; ///< convert YYTextShadow to NSShadow
@end


/**
 YYTextDecorationLine objects are used by the NSAttributedString class cluster
 as the values for decoration line attributes (stored in the attributed string under
 the key named YYTextUnderlineAttributeName or YYTextStrikethroughAttributeName).
 
 如果装饰线用做下划线，装饰线绘制在文本字形的下面
 如果装饰线用做删除线，装饰线绘制在文本字形的上面
 
 When it's used as underline, the line is drawn below text glyphs;
 when it's used as strikethrough, the line is drawn above text glyphs.
 */
@interface YYTextDecoration : NSObject <NSCoding, NSCopying>
+ (instancetype)decorationWithStyle:(YYTextLineStyle)style;
+ (instancetype)decorationWithStyle:(YYTextLineStyle)style width:(nullable NSNumber *)width color:(nullable UIColor *)color;
@property (nonatomic) YYTextLineStyle style;                   ///< line style
@property (nullable, nonatomic, strong) NSNumber *width;       ///< line width (nil means automatic width)
@property (nullable, nonatomic, strong) UIColor *color;        ///< line color (nil means automatic color)
@property (nullable, nonatomic, strong) YYTextShadow *shadow;  ///< line shadow 装饰线同样可以设置阴影
@end


/**
 YYTextBorder objects are used by the NSAttributedString class cluster
 as the values for border attributes (stored in the attributed string under
 the key named YYTextBorderAttributeName or YYTextBackgroundBorderAttributeName).
 
 可以用作为指定范围内的文本绘制边框，或者为指定范围内的文本绘制背景
 
 It can be used to draw a border around a range of text, or draw a background
 to a range of text.
 
 Example:
    ╭──────╮
    │ Text │
    ╰──────╯
 */
@interface YYTextBorder : NSObject <NSCoding, NSCopying>
+ (instancetype)borderWithLineStyle:(YYTextLineStyle)lineStyle lineWidth:(CGFloat)width strokeColor:(nullable UIColor *)color;
+ (instancetype)borderWithFillColor:(nullable UIColor *)color cornerRadius:(CGFloat)cornerRadius;
@property (nonatomic) YYTextLineStyle lineStyle;              ///< border line style 线条的类型
@property (nonatomic) CGFloat strokeWidth;                    ///< border line width 线条的宽度
@property (nullable, nonatomic, strong) UIColor *strokeColor; ///< border line color 线条的颜色
@property (nonatomic) CGLineJoin lineJoin;                    ///< border line join  线条的交接方式
@property (nonatomic) UIEdgeInsets insets;                    ///< border insets for text bounds 边框距离文本的边距
@property (nonatomic) CGFloat cornerRadius;                   ///< border corder radius 边界的圆角半径
@property (nullable, nonatomic, strong) YYTextShadow *shadow; ///< border shadow 边界的阴影
@property (nullable, nonatomic, strong) UIColor *fillColor;   ///< inner fill color 内部填充颜色（背景颜色）
@end


/**
 YYTextAttachment objects are used by the NSAttributedString class cluster 
 as the values for attachment attributes (stored in the attributed string under 
 the key named YYTextAttachmentAttributeName).
 
 当展示包含YYTextAttachment对象的属性字符串的时候，这个对象的content会替代相应的文本度量。
 content如果是UIImage对象，那么它会被绘制到CGContext，如果是UIView或者CALayer对象会被添加
 到文本容器的视图或者图层中
 
 When display an attributed string which contains `YYTextAttachment` object,
 the content will be placed in text metric. If the content is `UIImage`, 
 then it will be drawn to CGContext; if the content is `UIView` or `CALayer`, 
 then it will be added to the text container's view or layer.
 */
@interface YYTextAttachment : NSObject<NSCoding, NSCopying>
+ (instancetype)attachmentWithContent:(nullable id)content;
@property (nullable, nonatomic, strong) id content;             ///< Supported type: UIImage, UIView, CALayer
@property (nonatomic) UIViewContentMode contentMode;            ///< Content display mode. 内容填充方式
@property (nonatomic) UIEdgeInsets contentInsets;               ///< The insets when drawing content. 绘制content的边距
@property (nullable, nonatomic, strong) NSDictionary *userInfo; ///< The user information dictionary. user信息🤔️
@end


/**
 YYTextHighlight objects are used by the NSAttributedString class cluster
 as the values for touchable highlight attributes (stored in the attributed string
 under the key named YYTextHighlightAttributeName).
 
 当使用YYLabel或者YYTextView展示属性字符串的时候，高亮的文本可以被用户选中。
 如果一定范围内的文本被转换为高亮状态，YYTextHighlight类型中的attributes属性会修改（设置或者删除）原始的属性来展示文本
 
 When display an attributed string in `YYLabel` or `YYTextView`, the range of 
 highlight text can be toucheds down by users. If a range of text is turned into 
 highlighted state, the `attributes` in `YYTextHighlight` will be used to modify 
 (set or remove) the original attributes in the range for display.
 */
@interface YYTextHighlight : NSObject <NSCoding, NSCopying>

/**
 Attributes that you can apply to text in an attributed string when highlight.
 当处于高亮状态下的文本的属性（会覆盖文本原来的属性）
 Key:   Same as CoreText/YYText Attribute Name.
 Value: Modify attribute value when highlight (NSNull for remove attribute).
 */
@property (nullable, nonatomic, copy) NSDictionary<NSString *, id> *attributes;

/**
 Creates a highlight object with specified attributes.
 
 使用指定的属性创建高亮显示的对象
 
 @param attributes The attributes which will replace original attributes when highlight,
        If the value is NSNull, it will removed when highlight.
 */
+ (instancetype)highlightWithAttributes:(nullable NSDictionary<NSString *, id> *)attributes;

/**
 Convenience methods to create a default highlight with the specifeid background color.
 
 使用指定的背景颜色创建高亮文本的快捷方法
 
 @param color The background border color.
 */
+ (instancetype)highlightWithBackgroundColor:(nullable UIColor *)color;

// Convenience methods below to set the `attributes`.
// 一些设置属性字典的快捷方法，那么多的属性key好难记
- (void)setFont:(nullable UIFont *)font;
- (void)setColor:(nullable UIColor *)color;
- (void)setStrokeWidth:(nullable NSNumber *)width;
- (void)setStrokeColor:(nullable UIColor *)color;
- (void)setShadow:(nullable YYTextShadow *)shadow;
- (void)setInnerShadow:(nullable YYTextShadow *)shadow;
- (void)setUnderline:(nullable YYTextDecoration *)underline;
- (void)setStrikethrough:(nullable YYTextDecoration *)strikethrough;
- (void)setBackgroundBorder:(nullable YYTextBorder *)border;
- (void)setBorder:(nullable YYTextBorder *)border;
- (void)setAttachment:(nullable YYTextAttachment *)attachment;

/**
 The user information dictionary, default is nil.
 */
@property (nullable, nonatomic, copy) NSDictionary *userInfo;

/**
 Tap action when user tap the highlight, default is nil.
 If the value is nil, YYTextView or YYLabel will ask it's delegate to handle the tap action.
 */
@property (nullable, nonatomic, copy) YYTextAction tapAction;

/**
 Long press action when user long press the highlight, default is nil.
 If the value is nil, YYTextView or YYLabel will ask it's delegate to handle the long press action.
 */
@property (nullable, nonatomic, copy) YYTextAction longPressAction;

@end

NS_ASSUME_NONNULL_END
