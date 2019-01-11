//
//  YYTextUtilities.h
//  YYKit <https://github.com/ibireme/YYKit>
//
//  Created by ibireme on 15/4/6.
//  Copyright (c) 2015 ibireme.
//
//  This source code is licensed under the MIT-style license found in the
//  LICENSE file in the root directory of this source tree.
//

#import <UIKit/UIKit.h>
#import <CoreText/CoreText.h>

#if __has_include(<YYKit/YYKit.h>)
#import <YYKit/YYKitMacro.h>
#else
#import "YYKitMacro.h"
#endif

YY_EXTERN_C_BEGIN
NS_ASSUME_NONNULL_BEGIN

/**
 Whether the character is 'line break char':
 U+000D (\\r or CR)
 U+2028 (Unicode line separator)
 U+000A (\\n or LF)
 U+2029 (Unicode paragraph separator)
 判断一个字符是不是截断字符（根据ASCII码）
 @param c  A character
 @return YES or NO.
 */
static inline BOOL YYTextIsLinebreakChar(unichar c) {
    switch (c) {
        case 0x000D:
        case 0x2028:
        case 0x000A:
        case 0x2029:
            return YES;
        default:
            return NO;
    }
}

/**
 Whether the string is a 'line break':
 U+000D (\\r or CR)
 U+2028 (Unicode line separator)
 U+000A (\\n or LF)
 U+2029 (Unicode paragraph separator)
 \\r\\n, in that order (also known as CRLF)
 判断字符串是否是换行字符串，处理\\r\\n换行的情况
 @param str A string
 @return YES or NO.
 */
static inline BOOL YYTextIsLinebreakString(NSString * _Nullable str) {
    if (str.length > 2 || str.length == 0) return NO;
    if (str.length == 1) {
        unichar c = [str characterAtIndex:0];
        return YYTextIsLinebreakChar(c);
    } else {
        return ([str characterAtIndex:0] == '\r') && ([str characterAtIndex:1] == '\n');
    }
}

/**
 If the string has a 'line break' suffix, return the 'line break' length.
 
 获取换行字符串占用的长度，一般情况下没有换行是0，有换行是1，当换行采用\\r\\n的时候是2
 
 @param str  A string.
 @return The length of the tail line break: 0, 1 or 2.
 */
static inline NSUInteger YYTextLinebreakTailLength(NSString * _Nullable str) {
    if (str.length >= 2) {
        unichar c2 = [str characterAtIndex:str.length - 1];
        if (YYTextIsLinebreakChar(c2)) {
            unichar c1 = [str characterAtIndex:str.length - 2];
            if (c1 == '\r' && c2 == '\n') return 2;
            else return 1;
        } else {
            return 0;
        }
    } else if (str.length == 1) {
        return YYTextIsLinebreakChar([str characterAtIndex:0]) ? 1 : 0;
    } else {
        return 0;
    }
}

/**
 Convert `UIDataDetectorTypes` to `NSTextCheckingType`.
 
 UIDataDetectorTypes转换为NSTextCheckingType
 
 @param types  The `UIDataDetectorTypes` type.
 @return The `NSTextCheckingType` type.
 */
static inline NSTextCheckingType NSTextCheckingTypeFromUIDataDetectorType(UIDataDetectorTypes types) {
    NSTextCheckingType t = 0;
    if (types & UIDataDetectorTypePhoneNumber) t |= NSTextCheckingTypePhoneNumber;
    if (types & UIDataDetectorTypeLink) t |= NSTextCheckingTypeLink;
    if (types & UIDataDetectorTypeAddress) t |= NSTextCheckingTypeAddress;
    if (types & UIDataDetectorTypeCalendarEvent) t |= NSTextCheckingTypeDate;
    return t;
}

/**
 Whether the font is `AppleColorEmoji` font.
 
 判断是不是苹果彩色emoji字体
 
 @param font  A font.
 @return YES: the font is Emoji, NO: the font is not Emoji.
 */
static inline BOOL UIFontIsEmoji(UIFont *font) {
    return [font.fontName isEqualToString:@"AppleColorEmoji"];
}

/**
 Whether the font is `AppleColorEmoji` font.
 
 判断是不是苹果彩色emoji字体
 
 @param font  A font.
 @return YES: the font is Emoji, NO: the font is not Emoji.
 */
static inline BOOL CTFontIsEmoji(CTFontRef font) {
    BOOL isEmoji = NO;
    CFStringRef name = CTFontCopyPostScriptName(font);
    if (name && CFEqual(CFSTR("AppleColorEmoji"), name)) isEmoji = YES;
    if (name) CFRelease(name);
    return isEmoji;
}

/**
 Whether the font is `AppleColorEmoji` font.
 
 判断是不是苹果彩色emoji字体
 
 @param font  A font.
 @return YES: the font is Emoji, NO: the font is not Emoji.
 */
static inline BOOL CGFontIsEmoji(CGFontRef font) {
    BOOL isEmoji = NO;
    CFStringRef name = CGFontCopyPostScriptName(font);
    if (name && CFEqual(CFSTR("AppleColorEmoji"), name)) isEmoji = YES;
    if (name) CFRelease(name);
    return isEmoji;
}

/**
 Whether the font contains color bitmap glyphs.
 
 字体是否包含颜色位图字形
 
 @discussion Only `AppleColorEmoji` contains color bitmap glyphs in iOS system fonts.
 @param font  A font.
 @return YES: the font contains color bitmap glyphs, NO: the font has no color bitmap glyph.
 */
static inline BOOL CTFontContainsColorBitmapGlyphs(CTFontRef font) {
    return  (CTFontGetSymbolicTraits(font) & kCTFontTraitColorGlyphs) != 0;
}

/**
 Whether the glyph is bitmap.
 
 字形是否是bitMap的
 
 @param font  The glyph's font.
 @param glyph The glyph which is created from the specified font.
 @return YES: the glyph is bitmap, NO: the glyph is vector.
 */
static inline BOOL CGGlyphIsBitmap(CTFontRef font, CGGlyph glyph) {
    if (!font && !glyph) return NO;
    if (!CTFontContainsColorBitmapGlyphs(font)) return NO;
    CGPathRef path = CTFontCreatePathForGlyph(font, glyph, NULL);
    if (path) {
        CFRelease(path);
        return NO;
    }
    return YES;
}

/**
 Get the `AppleColorEmoji` font's ascent with a specified font size.
 It may used to create custom emoji.
 
 获取emoji基线以上的高度 增加 的emoji字体大小，可以用来自定义emoji
 
 @param fontSize  The specified font size.
 @return The font ascent.
 */
static inline CGFloat YYEmojiGetAscentWithFontSize(CGFloat fontSize) {
    if (fontSize < 16) {
        return 1.25 * fontSize;
    } else if (16 <= fontSize && fontSize <= 24) {
        return 0.5 * fontSize + 12;
    } else {
        return fontSize;
    }
}

/**
 Get the `AppleColorEmoji` font's descent with a specified font size.
 It may used to create custom emoji.
 
 🤔️根据字体大小获取 缩小 的emoji字体大小， 可以用来自定义emoji
 
 @param fontSize  The specified font size.
 @return The font descent.
 */
static inline CGFloat YYEmojiGetDescentWithFontSize(CGFloat fontSize) {
    if (fontSize < 16) {
        return 0.390625 * fontSize;
    } else if (16 <= fontSize && fontSize <= 24) {
        return 0.15625 * fontSize + 3.75;
    } else {
        return 0.3125 * fontSize;
    }
    return 0;
}

/**
 Get the `AppleColorEmoji` font's glyph bounding rect with a specified font size.
 It may used to create custom emoji.
 
 获取指定字体大小的字形边界，可能会用来创建自定义emoji
 
 @param fontSize  The specified font size.
 @return The font glyph bounding rect.
 */
static inline CGRect YYEmojiGetGlyphBoundingRectWithFontSize(CGFloat fontSize) {
    CGRect rect;
    rect.origin.x = 0.75;
    rect.size.width = rect.size.height = YYEmojiGetAscentWithFontSize(fontSize);
    if (fontSize < 16) {
        rect.origin.y = -0.2525 * fontSize;
    } else if (16 <= fontSize && fontSize <= 24) {
        rect.origin.y = 0.1225 * fontSize -6;
    } else {
        rect.origin.y = -0.1275 * fontSize;
    }
    return rect;
}

/**
 Convert a UTF-32 character (equal or larger than 0x10000) to two UTF-16 surrogate pair.
 
 将一个UTF-32拆分成两个UTF-16🤔️
 
 @param char32 Input: a UTF-32 character (equal or larger than 0x10000, not in BMP)
 @param char16 Output: two UTF-16 characters.
 */
static inline void UTF32CharToUTF16SurrogatePair(UTF32Char char32, UTF16Char char16[_Nonnull 2]) {
    char32 -= 0x10000;
    char16[0] = (char32 >> 10) + 0xD800;
    char16[1] = (char32 & 0x3FF) + 0xDC00;
}

/**
 Convert UTF-16 surrogate pair to a UTF-32 character.
 
 将两个UTF-16转换成UTF-32
 
 @param char16 Two UTF-16 characters.
 @return A single UTF-32 character.
 */
static inline UTF32Char UTF16SurrogatePairToUTF32Char(UTF16Char char16[_Nonnull 2]) {
    return ((char16[0] - 0xD800) << 10) + (char16[1] - 0xDC00) + 0x10000;
}

/**
 Get the character set which should rotate in vertical form.
 获取以垂直形式旋转的字符集
 @return The shared character set.
 */
NSCharacterSet *YYTextVerticalFormRotateCharacterSet(void);

/**
 Get the character set which should rotate and move in vertical form.
 获取应该旋转并且以垂直形式移动的字符集
 @return The shared character set.
 */
NSCharacterSet *YYTextVerticalFormRotateAndMoveCharacterSet(void);

NS_ASSUME_NONNULL_END
YY_EXTERN_C_END
