//
//  YYTextDebugOption.h
//  YYKit <https://github.com/ibireme/YYKit>
//
//  Created by ibireme on 15/4/8.
//  Copyright (c) 2015 ibireme.
//
//  This source code is licensed under the MIT-style license found in the
//  LICENSE file in the root directory of this source tree.
//

#import <UIKit/UIKit.h>

@class YYTextDebugOption;

NS_ASSUME_NONNULL_BEGIN

/**
 The YYTextDebugTarget protocol defines the method a debug target should implement.
 A debug target can be add to the global container to receive the shared debug
 option changed notification.
 */
@protocol YYTextDebugTarget <NSObject>

@required
/**
 When the shared debug option changed, this method would be called on main thread.
 It should return as quickly as possible. The option's property should not be changed
 in this method.
 
 当公用的调试选型改变的时候，这个方法会在主线程被调用。
 
 @param option  The shared debug option.
 */
- (void)setDebugOption:(nullable YYTextDebugOption *)option;
@end



/**
 The debug option for YYText.
 */
@interface YYTextDebugOption : NSObject <NSCopying>
@property (nullable, nonatomic, strong) UIColor *baselineColor;      ///< baseline color 基线颜色
@property (nullable, nonatomic, strong) UIColor *CTFrameBorderColor; ///< CTFrame path border color frame边界颜色
@property (nullable, nonatomic, strong) UIColor *CTFrameFillColor;   ///< CTFrame path fill color 边界填充颜色
@property (nullable, nonatomic, strong) UIColor *CTLineBorderColor;  ///< CTLine bounds border color CTLine边界颜色
@property (nullable, nonatomic, strong) UIColor *CTLineFillColor;    ///< CTLine bounds fill color CTLine边界填充颜色
@property (nullable, nonatomic, strong) UIColor *CTLineNumberColor;  ///< CTLine line number color CTLIne数字颜色
@property (nullable, nonatomic, strong) UIColor *CTRunBorderColor;   ///< CTRun bounds border color CTRun边界边框颜色
@property (nullable, nonatomic, strong) UIColor *CTRunFillColor;     ///< CTRun bounds fill color CTRun边界填充颜色
@property (nullable, nonatomic, strong) UIColor *CTRunNumberColor;   ///< CTRun number color CTRun 数字颜色
@property (nullable, nonatomic, strong) UIColor *CGGlyphBorderColor; ///< CGGlyph bounds border color 字形边界颜色
@property (nullable, nonatomic, strong) UIColor *CGGlyphFillColor;   ///< CGGlyph bounds fill color 字形填充颜色

- (BOOL)needDrawDebug; ///< `YES`: at least one debug color is visible. `NO`: all debug color is invisible/nil. 如果设置了至少一个调试颜色，则返回YES
- (void)clear; ///< Set all debug color to nil.

/**
 Add a debug target.
 
 添加一个debug的目标对象，当setSharedDebugOption:被调用的时候，所有已经添加的调试对象都在主线程会收到
 setDebugOption的消息，它维护了调试对象的一个不安全的引用，在调试对象被释放之前一个要移除从列表中移除
 
 @discussion When `setSharedDebugOption:` is called, all added debug target will 
 receive `setDebugOption:` in main thread. It maintains an unsafe_unretained
 reference to this target. The target must to removed before dealloc.
 
 @param target A debug target.
 */
+ (void)addDebugTarget:(id<YYTextDebugTarget>)target;

/**
 Remove a debug target which is added by `addDebugTarget:`.
 
 移除调试对象
 
 @param target A debug target.
 */
+ (void)removeDebugTarget:(id<YYTextDebugTarget>)target;

/**
 Returns the shared debug option.
 
 返回一个共享的调试对象
 
 @return The shared debug option, default is nil.
 */
+ (nullable YYTextDebugOption *)sharedDebugOption;

/**
 Set a debug option as shared debug option.
 This method must be called on main thread.
 
 讲一个调试对象设置为共享的调试对象，这个方法必须在主线程调用
 
 @discussion When call this method, the new option will set to all debug target
 which is added by `addDebugTarget:`.
 
 @param option  A new debug option (nil is valid).
 */
+ (void)setSharedDebugOption:(nullable YYTextDebugOption *)option;

@end

NS_ASSUME_NONNULL_END
