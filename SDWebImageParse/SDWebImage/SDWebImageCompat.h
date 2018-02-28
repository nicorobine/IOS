/*
 * This file is part of the SDWebImage package.
 * (c) Olivier Poitrey <rs@dailymotion.com>
 * (c) Jamie Pinkham
 *
 * For the full copyright and license information, please view the LICENSE
 * file that was distributed with this source code.
 */

#import <TargetConditionals.h>

// wwt SDWebImage不支持垃圾回收机制
#ifdef __OBJC_GC__
    #error SDWebImage does not support Objective-C Garbage Collection
#endif

// wwt 判断是不是再Mac上使用
// Apple's defines from TargetConditionals.h are a bit weird.
// Seems like TARGET_OS_MAC is always defined (on all platforms).
// To determine if we are running on OSX, we can only rely on TARGET_OS_IPHONE=0 and all the other platforms
#if !TARGET_OS_IPHONE && !TARGET_OS_IOS && !TARGET_OS_TV && !TARGET_OS_WATCH
    #define SD_MAC 1
#else
    #define SD_MAC 0
#endif

// wwt 判读是否是在iOS平台和tvOS平台（UIKit在两个平台都支持），watchOS的UIKit收到限制
// iOS and tvOS are very similar, UIKit exists on both platforms
// Note: watchOS also has UIKit, but it's very limited
#if TARGET_OS_IOS || TARGET_OS_TV
    #define SD_UIKIT 1
#else
    #define SD_UIKIT 0
#endif

// wwt 判断是不是iOS平台
#if TARGET_OS_IOS
    #define SD_IOS 1
#else
    #define SD_IOS 0
#endif

// wwt 是否是tvOS平台
#if TARGET_OS_TV
    #define SD_TV 1
#else
    #define SD_TV 0
#endif

// wwt 是否是watchOS平台
#if TARGET_OS_WATCH
    #define SD_WATCH 1
#else
    #define SD_WATCH 0
#endif

// wwt 如果是Mac平台，将NSImage，NSImageView和NSView定义一个UI开头的宏
// wwt 只支持5.0及以上版本
// wwt 导入相应的库
#if SD_MAC
    #import <AppKit/AppKit.h>
    #ifndef UIImage
        #define UIImage NSImage
    #endif
    #ifndef UIImageView
        #define UIImageView NSImageView
    #endif
    #ifndef UIView
        #define UIView NSView
    #endif
#else
    #if __IPHONE_OS_VERSION_MIN_REQUIRED != 20000 && __IPHONE_OS_VERSION_MIN_REQUIRED < __IPHONE_5_0
        #error SDWebImage doesn't support Deployment Target version < 5.0
    #endif

    #if SD_UIKIT
        #import <UIKit/UIKit.h>
    #endif
    #if SD_WATCH
        #import <WatchKit/WatchKit.h>
    #endif
#endif

// wwt 定义NS_ENUM
#ifndef NS_ENUM
#define NS_ENUM(_type, _name) enum _name : _type _name; enum _name : _type
#endif

// wwt 定义NS_OPTIONS 和enum的区别是一般为位枚举
// wwt 这里为什么会出现NS_OPTIONS与NS_ENUM且为什么不直接一个就行，且枚举值可多选。因为有个是否将代码按照C++模式编译，若是不按照C++模式编译，NS_OPTIONS与NS_ENUM展开方式就一样，若是要按照C++模式编译，就不同了。在使用或运算操作两个枚举值时，C++默认为运算结果的数据类型是枚举的底层数据类型即NSUInteger,且C++不允许它隐式转换为枚举类型本身，所以C++模式下定义了NS_OPTIONS宏以保证不出现类型转换。
#ifndef NS_OPTIONS
#define NS_OPTIONS(_type, _name) enum _name : _type _name; enum _name : _type
#endif

// wwt 缩放图片根据key缩放图片（key包含@2x.或者@3x.的关键字，将图片变为二倍或者三倍图）
FOUNDATION_EXPORT UIImage *SDScaledImageForKey(NSString *key, UIImage *image);

// wwt 无参数的block
typedef void(^SDWebImageNoParamsBlock)(void);

// wwt SDWebImage错误域
FOUNDATION_EXPORT NSString *const SDWebImageErrorDomain;

// wwt 如果队列参数为NULL，则直接执行block
#ifndef dispatch_queue_async_safe
#define dispatch_queue_async_safe(queue, block)\
    if (strcmp(dispatch_queue_get_label(DISPATCH_CURRENT_QUEUE_LABEL), dispatch_queue_get_label(queue)) == 0) {\
        block();\
    } else {\
        dispatch_async(queue, block);\
    }
#endif

// wwt 在主队列中安全的异步执行（应该是防止传错队列参数）
#ifndef dispatch_main_async_safe
#define dispatch_main_async_safe(block) dispatch_queue_async_safe(dispatch_get_main_queue(), block)
#endif
