/*
 * This file is part of the SDWebImage package.
 * (c) Olivier Poitrey <rs@dailymotion.com>
 *
 * For the full copyright and license information, please view the LICENSE
 * file that was distributed with this source code.
 */

#import <Foundation/Foundation.h>
#import "SDWebImageCoder.h"

/**
 wwt 持有编码器数组的全局对象，避免在各种类中来回传递
     使用场景优先队列，意味着新添加的解码器具有最高的优先级
     在编码/解码某些数据的时候，我们根据编码器列表查询每个编码器是否可以处理当前的数据，这样可以添加自定义的编码器，同时保留预置的编码器，同时要求编码器必须遵循SDWebImageCoder协议或者SDWebIageProgresiveCoder协议
 
 Global object holding the array of coders, so that we avoid passing them from object to object.
 Uses a priority queue behind scenes, which means the latest added coders have the highest priority.
 This is done so when encoding/decoding something, we go through the list and ask each coder if they can handle the current data.
 That way, users can add their custom coders while preserving our existing prebuilt ones
 
 Note: the `coders` getter will return the coders in their reversed order
 Example:
 - by default we internally set coders = `IOCoder`, `WebPCoder`. (`GIFCoder` is not recommended to add only if you want to get GIF support without `FLAnimatedImage`)
 - calling `coders` will return `@[WebPCoder, IOCoder]`
 - call `[addCoder:[MyCrazyCoder new]]`
 - calling `coders` now returns `@[MyCrazyCoder, WebPCoder, IOCoder]`
 
 Coders
 ------
 A coder must conform to the `SDWebImageCoder` protocol or even to `SDWebImageProgressiveCoder` if it supports progressive decoding
 Conformance is important because that way, they will implement `canDecodeFromData` or `canEncodeToFormat`
 Those methods are called on each coder in the array (using the priority order) until one of them returns YES.
 That means that coder can decode that data / encode to that format
 */
@interface SDWebImageCodersManager : NSObject<SDWebImageCoder>

/**
 Shared reusable instance
 */
+ (nonnull instancetype)sharedInstance;

/**
 wwt 编码器管理的所有编码器，越后添加的编码器优先级越高
 All coders in coders manager. The coders array is a priority queue, which means the later added coder will have the highest priority
 */
@property (nonatomic, strong, readwrite, nullable) NSArray<SDWebImageCoder>* coders;

/**
 Add a new coder to the end of coders array. Which has the highest priority.

 @param coder coder
 */
- (void)addCoder:(nonnull id<SDWebImageCoder>)coder;

/**
 Remove a coder in the coders array.

 @param coder coder
 */
- (void)removeCoder:(nonnull id<SDWebImageCoder>)coder;

@end
