//
//  YYMemoryCache.h
//  YYKit <https://github.com/ibireme/YYKit>
//
//  Created by ibireme on 15/2/7.
//  Copyright (c) 2015 ibireme.
//
//  This source code is licensed under the MIT-style license found in the
//  LICENSE file in the root directory of this source tree.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/**
 YYMemoryCache is a fast in-memory cache that stores key-value pairs.
 In contrast to NSDictionary, keys are retained and not copied.
 The API and performance is similar to `NSCache`, all methods are thread-safe.
 
 YYMemoryCache 是一个储存键值对的快速的内存缓存，和NSDictionary不同的是，keys只是被Retain，没有被copy
 YYMemoryCache的API和NSCache相似，而且多有的方法都是线程安全的
 
 YYMemoryCache objects differ from NSCache in a few ways:
 
 * It uses LRU (least-recently-used) to remove objects; NSCache's eviction method
   is non-deterministic.
 * It can be controlled by cost, count and age; NSCache's limits are imprecise.
 * It can be configured to automatically evict objects when receive memory 
   warning or app enter background.
 
 YYMemoryCache和NSCache的不同之处主要表现在以下
 * 使用LRU移除对象，而NSCache的回收方法是不能确定的
 * 可以根据消耗的空间，数量和日期控制，而NSCache的限制是不精确的
 * 当接收到内存警告或者app进入后台的时候可以设置自动回收对象
 
 The time of `Access Methods` in YYMemoryCache is typically in constant time (O(1)).
 时间复杂度为（O(1)）
 */
@interface YYMemoryCache : NSObject

#pragma mark - Attribute
///=============================================================================
/// @name Attribute
///=============================================================================

// 缓存的名字
/** The name of the cache. Default is nil. */
@property (nullable, copy) NSString *name;

// 缓存的对象数
/** The number of objects in the cache (read-only) */
@property (readonly) NSUInteger totalCount;

// 缓存中的对象所占用的空间
/** The total cost of objects in the cache (read-only). */
@property (readonly) NSUInteger totalCost;


#pragma mark - Limit
///=============================================================================
/// @name Limit
///=============================================================================

/**
 The maximum number of objects the cache should hold.
 最大可以缓存的对象数目
 
 @discussion The default value is NSUIntegerMax, which means no limit.
 This is not a strict limit—if the cache goes over the limit, some objects in the
 cache could be evicted later in backgound thread.
 @discussion 默认值是最大整数，也就是没有显示。而且这也不是一个精准的限制，如果缓存超过了限制，
 一些缓存的对象会在后台线程随后被释放
 */
@property NSUInteger countLimit;

/**
 The maximum total cost that the cache can hold before it starts evicting objects.
 在开始释放缓存的对象之前，缓存可以保持的最大空间
 
 @discussion The default value is NSUIntegerMax, which means no limit.
 This is not a strict limit—if the cache goes over the limit, some objects in the
 cache could be evicted later in backgound thread.
 */
@property NSUInteger costLimit;

/**
 The maximum expiry time of objects in cache.
 缓存对象的最大逾期时间
 
 @discussion The default value is DBL_MAX, which means no limit.
 This is not a strict limit—if an object goes over the limit, the object could 
 be evicted later in backgound thread.
 */
@property NSTimeInterval ageLimit;

/**
 The auto trim check time interval in seconds. Default is 5.0.
 自动回收的时间间隔，模式是5.0s
 
 @discussion The cache holds an internal timer to check whether the cache reaches 
 its limits, and if the limit is reached, it begins to evict objects.
 */
@property NSTimeInterval autoTrimInterval;

/**
 If `YES`, the cache will remove all objects when the app receives a memory warning.
 The default value is `YES`.
 当接收到内存警告的时候是否移除全部缓存
 */
@property BOOL shouldRemoveAllObjectsOnMemoryWarning;

/**
 If `YES`, The cache will remove all objects when the app enter background.
 The default value is `YES`.
 当进入后台的时候是否移除劝募缓存
 */
@property BOOL shouldRemoveAllObjectsWhenEnteringBackground;

/**
 A block to be executed when the app receives a memory warning.
 The default value is nil.
 当app收到内存警告的时候的回调block，默认nil
 */
@property (nullable, copy) void(^didReceiveMemoryWarningBlock)(YYMemoryCache *cache);

/**
 A block to be executed when the app enter background.
 The default value is nil.
 当app进入后台的回调，默认为nil
 */
@property (nullable, copy) void(^didEnterBackgroundBlock)(YYMemoryCache *cache);

/**
 If `YES`, the key-value pair will be released on main thread, otherwise on
 background thread. Default is NO.
 如果是YEs，key-value对会在主线程释放，否则在后台线程释放，默认NO
 
 @discussion You may set this value to `YES` if the key-value object contains
 the instance which should be released in main thread (such as UIView/CALayer).
 如果key-value对包含需要在主线程释放的对象（如UIView/CALayer）设置成YES
 */
@property BOOL releaseOnMainThread;

/**
 If `YES`, the key-value pair will be released asynchronously to avoid blocking 
 the access methods, otherwise it will be released in the access method  
 (such as removeObjectForKey:). Default is YES.
 如果为YES，key-value对会异步的释放，以避免阻塞访问方法，否则会在访问方法中释放（如removeObjectForKey:）
 默认为YES
 */
@property BOOL releaseAsynchronously;


#pragma mark - Access Methods
///=============================================================================
/// @name Access Methods
///=============================================================================

/**
 Returns a Boolean value that indicates whether a given key is in cache.
 返回给定key是否已经在缓存中的布尔值
 
 @param key An object identifying the value. If nil, just return `NO`.
 @return Whether the key is in cache.
 */
- (BOOL)containsObjectForKey:(id)key;

/**
 Returns the value associated with a given key.
 返回可传入key相关联的对象，如果没有返回nil
 
 @param key An object identifying the value. If nil, just return nil.
 @return The value associated with key, or nil if no value is associated with key.
 */
- (nullable id)objectForKey:(id)key;

/**
 Sets the value of the specified key in the cache (0 cost).
 根据指定的key将对象放入缓存，如果objec为nil，则会调用removeObjectForKey:默认cost为0
 如果key为nil不会有认可作用，不像NSMutableDictionary，缓存不会复制一份key对象
 
 @param object The object to be stored in the cache. If nil, it calls `removeObjectForKey:`.
 @param key    The key with which to associate the value. If nil, this method has no effect.
 @discussion Unlike an NSMutableDictionary object, a cache does not copy the key 
 objects that are put into it.
 */
- (void)setObject:(nullable id)object forKey:(id)key;

/**
 Sets the value of the specified key in the cache, and associates the key-value 
 pair with the specified cost.
 根据指定的key将对象放入缓存，如果objec为nil，则会调用removeObjectForKey:同时可以指定缓存的消耗
 
 @param object The object to store in the cache. If nil, it calls `removeObjectForKey`.
 @param key    The key with which to associate the value. If nil, this method has no effect.
 @param cost   The cost with which to associate the key-value pair.
 @discussion Unlike an NSMutableDictionary object, a cache does not copy the key
 objects that are put into it.
 */
- (void)setObject:(nullable id)object forKey:(id)key withCost:(NSUInteger)cost;

/**
 Removes the value of the specified key in the cache.
 根据指定的key移除缓存中的对象
 
 @param key The key identifying the value to be removed. If nil, this method has no effect.
 */
- (void)removeObjectForKey:(id)key;

/**
 Empties the cache immediately.
 清空缓存
 */
- (void)removeAllObjects;


#pragma mark - Trim
///=============================================================================
/// @name Trim
///=============================================================================

/**
 Removes objects from the cache with LRU, until the `totalCount` is below or equal to
 the specified value.
 使用lRU清除缓存的对象，直到totalCount小于或者等于指定的值
 @param count  The total count allowed to remain after the cache has been trimmed.
 */
- (void)trimToCount:(NSUInteger)count;

/**
 Removes objects from the cache with LRU, until the `totalCost` is or equal to
 the specified value.
 使用lRU清除缓存的对象，直到totalCost小于或者等于指定的值
 @param cost The total cost allowed to remain after the cache has been trimmed.
 */
- (void)trimToCost:(NSUInteger)cost;

/**
 Removes objects from the cache with LRU, until all expiry objects removed by the
 specified value.
 使用lRU清除缓存的对象，直到age小于或者等于指定的值
 @param age  The maximum age (in seconds) of objects.
 */
- (void)trimToAge:(NSTimeInterval)age;

@end

NS_ASSUME_NONNULL_END
