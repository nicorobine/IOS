//
//  YYTextParser.h
//  YYKit <https://github.com/ibireme/YYKit>
//
//  Created by ibireme on 15/3/6.
//  Copyright (c) 2015 ibireme.
//
//  This source code is licensed under the MIT-style license found in the
//  LICENSE file in the root directory of this source tree.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

/**
 The YYTextParser protocol declares the required method for YYTextView and YYLabel
 to modify the text during editing.
 
 YYTextParser协议声明了在YYTextView和YYLabel文本编辑过程中用来修改文本信息的必要的方法
 
 你可以实现此协议为YYTextView和YYLabel代码突出显示或者表情替换
 
 You can implement this protocol to add code highlighting or emoticon replacement for
 YYTextView and YYLabel. See `YYTextSimpleMarkdownParser` and `YYTextSimpleEmoticonParser` for example.
 */
@protocol YYTextParser <NSObject>
@required
/**
 When text is changed in YYTextView or YYLabel, this method will be called.
 
 当YYTextView或者YYLable的文本改变后这个方法会被调用
 
 @param text  The original attributed string. This method may parse the text and
 change the text attributes or content.
 原始的属性字符串。此方法可以解析文本，病也改变文本属性或者内容
 
 @param selectedRange  Current selected range in `text`.
 This method should correct the range if the text content is changed. If there's 
 no selected range (such as YYLabel), this value is NULL.
 
 @return If the 'text' is modified in this method, returns `YES`, otherwise returns `NO`.
 */
- (BOOL)parseText:(nullable NSMutableAttributedString *)text selectedRange:(nullable NSRangePointer)selectedRange;
@end



/**
 A simple markdown parser.
 
 It'a very simple markdown parser, you can use this parser to highlight some 
 small piece of markdown text.
 
 一个简单的标记解析器，你可以使用这个解析器突出显示一小段标记的文本
 
 This markdown parser use regular expression to parse text, slow and weak.
 这个标记解析器使用正则表达式解析文本，比较慢而且弱爆了，如果想要写一个更好的解析器，可以尝试下面吊炸天的方案
 If you want to write a better parser, try these projests:
 https://github.com/NimbusKit/markdown
 https://github.com/dreamwieber/AttributedMarkdown
 https://github.com/indragiek/CocoaMarkdown
 
 Or you can use lex/yacc to generate your custom parser.
 */
@interface YYTextSimpleMarkdownParser : NSObject <YYTextParser>
@property (nonatomic) CGFloat fontSize;         ///< default is 14
@property (nonatomic) CGFloat headerFontSize;   ///< default is 20

@property (nullable, nonatomic, strong) UIColor *textColor;
@property (nullable, nonatomic, strong) UIColor *controlTextColor;
@property (nullable, nonatomic, strong) UIColor *headerTextColor;
@property (nullable, nonatomic, strong) UIColor *inlineTextColor;
@property (nullable, nonatomic, strong) UIColor *codeTextColor;
@property (nullable, nonatomic, strong) UIColor *linkTextColor;

- (void)setColorWithBrightTheme; ///< reset the color properties to pre-defined value.
- (void)setColorWithDarkTheme;   ///< reset the color properties to pre-defined value.
@end



/**
 A simple emoticon parser.
 
 Use this parser to map some specified piece of string to image emoticon.
 Example: "Hello :smile:"  ->  "Hello 😀"
 
 It can also be used to extend the "unicode emoticon".
 */
@interface YYTextSimpleEmoticonParser : NSObject <YYTextParser>

/**
 The custom emoticon mapper.
 The key is a specified plain string, such as @":smile:".
 The value is a UIImage which will replace the specified plain string in text.
 */
@property (nullable, copy) NSDictionary<NSString *, __kindof UIImage *> *emoticonMapper;
@end

NS_ASSUME_NONNULL_END
