//
//  YYTextInput.h
//  YYKit <https://github.com/ibireme/YYKit>
//
//  Created by ibireme on 15/4/17.
//  Copyright (c) 2015 ibireme.
//
//  This source code is licensed under the MIT-style license found in the
//  LICENSE file in the root directory of this source tree.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

/**
 Text position affinity. For example, the offset appears after the last
 character on a line is backward affinity, before the first character on
 the following line is forward affinity.
 文本位置的关联。例如当偏移（offset）出现在一行里面的最后一个字符之后是向后的关联（backward），
 出现在在一行的第一个字符之前是向前的关联
 */
typedef NS_ENUM(NSInteger, YYTextAffinity) {
    YYTextAffinityForward  = 0, ///< offset appears before the character
    YYTextAffinityBackward = 1, ///< offset appears after the character
};


/**
 A YYTextPosition object represents a position in a text container; in other words, 
 it is an index into the backing string in a text-displaying view.
 
 一个YYTextPostion对象代表了一个文本容器的位置。换句话说，他是一个文本展示视图的字符串内的索引。
 YYTextPostion和UITextview/UITextField的实现具有相同的api，所有可以使用它和UITextView/UITextField交互
 
 YYTextPosition has the same API as Apple's implementation in UITextView/UITextField,
 so you can alse use it to interact with UITextView/UITextField.
 */
@interface YYTextPosition : UITextPosition <NSCopying>

// 偏移量
@property (nonatomic, readonly) NSInteger offset;
// 结合类型
@property (nonatomic, readonly) YYTextAffinity affinity;

// 快捷的初始化方法
+ (instancetype)positionWithOffset:(NSInteger)offset;
+ (instancetype)positionWithOffset:(NSInteger)offset affinity:(YYTextAffinity) affinity;

// 比较位置
- (NSComparisonResult)compare:(id)otherPosition;

@end


/**
 A YYTextRange object represents a range of characters in a text container; in other words, 
 it identifies a starting index and an ending index in string backing a text-displaying view.
 
 一个代表了在文本容器中的一个字符串的范围对象
 
 YYTextRange has the same API as Apple's implementation in UITextView/UITextField,
 so you can alse use it to interact with UITextView/UITextField.
 */
@interface YYTextRange : UITextRange <NSCopying>

// 起始位置
@property (nonatomic, readonly) YYTextPosition *start;
// 结束位置
@property (nonatomic, readonly) YYTextPosition *end;
// 是否是空的
@property (nonatomic, readonly, getter=isEmpty) BOOL empty;

// 根据range快速的初始化方法
+ (instancetype)rangeWithRange:(NSRange)range;
+ (instancetype)rangeWithRange:(NSRange)range affinity:(YYTextAffinity) affinity;
+ (instancetype)rangeWithStart:(YYTextPosition *)start end:(YYTextPosition *)end;
+ (instancetype)defaultRange; ///< <{0,0} Forward>

// 返回range类型的数据
- (NSRange)asRange;

@end


/**
 A YYTextSelectionRect object encapsulates information about a selected range of 
 text in a text-displaying view.
 
 在文本展示视图中选中的文本信息的包装对象
 
 YYTextSelectionRect has the same API as Apple's implementation in UITextView/UITextField,
 so you can alse use it to interact with UITextView/UITextField.
 */
@interface YYTextSelectionRect : UITextSelectionRect <NSCopying>

// 选中的rect
@property (nonatomic, readwrite) CGRect rect;
// 文字方向
@property (nonatomic, readwrite) UITextWritingDirection writingDirection;
// 矩形区域是否包含选择的开始
@property (nonatomic, readwrite) BOOL containsStart;
// 矩形区域是否包含选择的结束
@property (nonatomic, readwrite) BOOL containsEnd;
// 是否是垂直排版
@property (nonatomic, readwrite) BOOL isVertical;

@end

NS_ASSUME_NONNULL_END
