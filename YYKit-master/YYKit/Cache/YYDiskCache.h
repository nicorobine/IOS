//
//  YYDiskCache.h
//  YYKit <https://github.com/ibireme/YYKit>
//
//  Created by ibireme on 15/2/11.
//  Copyright (c) 2015 ibireme.
//
//  This source code is licensed under the MIT-style license found in the
//  LICENSE file in the root directory of this source tree.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/**
 YYDiskCache is a thread-safe cache that stores key-value pairs backed by SQLite
 and file system (similar to NSURLCache's disk cache).
 
 YYDiskCache 是使用SQLite储存键值对的线程安全的缓存（类似于NSURLCache）
 YYDiskCache的特性：
 * 使用LRU移除数据
 * 可以根据数量，空间和时间移除缓存
 * 可以设置成当磁盘空间不足的时候自动清理磁盘缓存
 * 可以自动将不同的对象使用不同的缓存类型（sqlite/file），以获取更好的性能
 
 YYDiskCache has these features:
 
 * It use LRU (least-recently-used) to remove objects.
 * It can be controlled by cost, count, and age.
 * It can be configured to automatically evict objects when there's no free disk space.
 * It can automatically decide the storage type (sqlite/file) for each object to get
      better performance.
 
 You may compile the latest version of sqlite and ignore the libsqlite3.dylib in
 iOS system to get 2x~4x speed up.
 */
@interface YYDiskCache : NSObject

#pragma mark - Attribute
///=============================================================================
/// @name Attribute
///=============================================================================

/** The name of the cache. Default is nil. */
// cache的名字默认为nil
@property (nullable, copy) NSString *name;

/** The path of the cache (read-only). */
// 缓存的路径
@property (readonly) NSString *path;

/**
 If the object's data size (in bytes) is larger than this value, then object will
 be stored as a file, otherwise the object will be stored in sqlite.
 
 0 means all objects will be stored as separated files, NSUIntegerMax means all
 objects will be stored in sqlite. 
 
 The default value is 20480 (20KB).
 
 如果对象数据的大小比这个内联阀值小，则使用sqilte缓存；如果比这个值大则使用文件缓存
 也就以为着这个值为0，全部使用文件缓存，这个值为NSUIntegerMax会全部使用sqilte缓存
 默认大小为20480（20KB）
 */
@property (readonly) NSUInteger inlineThreshold;

/**
 If this block is not nil, then the block will be used to archive object instead
 of NSKeyedArchiver. You can use this block to support the objects which do not
 conform to the `NSCoding` protocol.
 
 如果这个block不是nil，会使用这个block代替NSKeyedArchiver来归档对象，
 你可以使用这个block来支持没有实现NSCoding协议的对象
 
 The default value is nil.
 */
@property (nullable, copy) NSData *(^customArchiveBlock)(id object);

/**
 If this block is not nil, then the block will be used to unarchive object instead
 of NSKeyedUnarchiver. You can use this block to support the objects which do not
 conform to the `NSCoding` protocol.
 
 如果这个block不是nil，就是使用这个block代替NSKeyedUnarchiver去解压对象，
 你可以使用这个block来支持没有实现NSCoding协议的对象
 
 The default value is nil.
 */
@property (nullable, copy) id (^customUnarchiveBlock)(NSData *data);

/**
 When an object needs to be saved as a file, this block will be invoked to generate
 a file name for a specified key. If the block is nil, the cache use md5(key) as 
 default file name.
 
 如果对象需要以文件的方式来存储，这个block会被调用来为指定的key指定一个文件名字，如果不设置block，
 默认以key的md5作为文件名字
 
 The default value is nil.
 */
@property (nullable, copy) NSString *(^customFileNameBlock)(NSString *key);



#pragma mark - Limit
///=============================================================================
/// @name Limit
///=============================================================================

/**
 The maximum number of objects the cache should hold.
 
 缓存对象的最大数量，默认是NSUIntegerMax（没有限制）
 这个限制是不太准确的，因为当超过限制后会在后台移除一些多余的对象
 
 @discussion The default value is NSUIntegerMax, which means no limit.
 This is not a strict limit — if the cache goes over the limit, some objects in the
 cache could be evicted later in background queue.
 */
@property NSUInteger countLimit;

/**
 The maximum total cost that the cache can hold before it starts evicting objects.
 
 缓存对象的最大空间，默认是NSUIntegerMax（没有限制）
 这个限制是不太准确的，因为当超过限制后会在后台移除一些多余的对象
 
 @discussion The default value is NSUIntegerMax, which means no limit.
 This is not a strict limit — if the cache goes over the limit, some objects in the
 cache could be evicted later in background queue.
 */
@property NSUInteger costLimit;

/**
 The maximum expiry time of objects in cache.
 
 缓存对象的最大数量，默认是DBL_MAX（没有限制）
 这个限制是不太准确的，因为当超过限制后会在后台移除一些多余的对象
 
 @discussion The default value is DBL_MAX, which means no limit.
 This is not a strict limit — if an object goes over the limit, the objects could
 be evicted later in background queue.
 */
@property NSTimeInterval ageLimit;

/**
 The minimum free disk space (in bytes) which the cache should kept.
 
 磁盘剩余空间的限制，默认是0（没有限制）
 这个限制是不太准确的，因为当超过限制后会在后台移除一些多余的对象
 
 @discussion The default value is 0, which means no limit.
 If the free disk space is lower than this value, the cache will remove objects
 to free some disk space. This is not a strict limit—if the free disk space goes
 over the limit, the objects could be evicted later in background queue.
 */
@property NSUInteger freeDiskSpaceLimit;

/**
 The auto trim check time interval in seconds. Default is 60 (1 minute).
 
 自动检测缓存的时间间隔，默认为1分钟
 
 @discussion The cache holds an internal timer to check whether the cache reaches
 its limits, and if the limit is reached, it begins to evict objects.
 */
@property NSTimeInterval autoTrimInterval;

/**
 Set `YES` to enable error logs for debug.
 设置成YES，会启用调试的错误日志
 */
@property BOOL errorLogsEnabled;

#pragma mark - Initializer
///=============================================================================
/// @name Initializer
///=============================================================================
- (instancetype)init UNAVAILABLE_ATTRIBUTE;
+ (instancetype)new UNAVAILABLE_ATTRIBUTE;

/**
 Create a new cache based on the specified path.
 
 根据指定的路径创建一个缓存对象
 指定的路径必须是全路径，一旦以初始化之后，就不要忘这个路径下进行读写了
 如果指定路径的YYDiskCache已经在内存中存在了，这个方法会直接返回这个对象，而不会再创建一个
 
 @param path Full path of a directory in which the cache will write data.
     Once initialized you should not read and write to this directory.
 
 @return A new cache object, or nil if an error occurs.
 
 @warning If the cache instance for the specified path already exists in memory,
     this method will return it directly, instead of creating a new instance.
 */
- (nullable instancetype)initWithPath:(NSString *)path;

/**
 The designated initializer.
 
 可以指定阀值的初始化方法，阀值是一个临界点，小于阀值会以sqlite缓存，大于阀值会以文件的方式缓存
 
 @param path       Full path of a directory in which the cache will write data.
     Once initialized you should not read and write to this directory.
 
 @param threshold  The data store inline threshold in bytes. If the object's data
     size (in bytes) is larger than this value, then object will be stored as a 
     file, otherwise the object will be stored in sqlite. 0 means all objects will 
     be stored as separated files, NSUIntegerMax means all objects will be stored 
     in sqlite. If you don't know your object's size, 20480 is a good choice.
     After first initialized you should not change this value of the specified path.
 
 @return A new cache object, or nil if an error occurs.
 
 @warning If the cache instance for the specified path already exists in memory,
     this method will return it directly, instead of creating a new instance.
 */
- (nullable instancetype)initWithPath:(NSString *)path
                      inlineThreshold:(NSUInteger)threshold NS_DESIGNATED_INITIALIZER;


#pragma mark - Access Methods
///=============================================================================
/// @name Access Methods
///=============================================================================

/**
 Returns a boolean value that indicates whether a given key is in cache.
 This method may blocks the calling thread until file read finished.
 
 根据给定的key是否已经被缓存返回一个布尔值
 这个方法可能阻塞线程，直到文件读取完成
 
 @param key A string identifying the value. If nil, just return NO.
 @return Whether the key is in cache.
 */
- (BOOL)containsObjectForKey:(NSString *)key;

/**
 Returns a boolean value with the block that indicates whether a given key is in cache.
 This method returns immediately and invoke the passed block in background queue 
 when the operation finished.
 
 根据给定的key，在block中返回指定的key是否已经被缓存了
 这个方法不会阻塞线程，查询完成后会在后台队列中回调block
 
 @param key   A string identifying the value. If nil, just return NO.
 @param block A block which will be invoked in background queue when finished.
 */
- (void)containsObjectForKey:(NSString *)key withBlock:(void(^)(NSString *key, BOOL contains))block;

/**
 Returns the value associated with a given key.
 This method may blocks the calling thread until file read finished.
 
 根据给定的key返回它关联的对象，这个方法可能会阻塞线程
 
 @param key A string identifying the value. If nil, just return nil.
 @return The value associated with key, or nil if no value is associated with key.
 */
- (nullable id<NSCoding>)objectForKey:(NSString *)key;

/**
 Returns the value associated with a given key.
 This method returns immediately and invoke the passed block in background queue
 when the operation finished.
 
 根据给定的key获取它关联的对象，这个方法不会阻塞线程
 block会在后台队列里回调
 
 @param key A string identifying the value. If nil, just return nil.
 @param block A block which will be invoked in background queue when finished.
 */
- (void)objectForKey:(NSString *)key withBlock:(void(^)(NSString *key, id<NSCoding> _Nullable object))block;

/**
 Sets the value of the specified key in the cache.
 This method may blocks the calling thread until file write finished.
 
 根据特定的key缓存对象，这个方法可能会阻塞线程
 
 @param object The object to be stored in the cache. If nil, it calls `removeObjectForKey:`.
 @param key    The key with which to associate the value. If nil, this method has no effect.
 */
- (void)setObject:(nullable id<NSCoding>)object forKey:(NSString *)key;

/**
 Sets the value of the specified key in the cache.
 This method returns immediately and invoke the passed block in background queue
 when the operation finished.
 
 根据特定的key缓存对象，完成后会在后台线程回调block
 
 @param object The object to be stored in the cache. If nil, it calls `removeObjectForKey:`.
 @param block  A block which will be invoked in background queue when finished.
 */
- (void)setObject:(nullable id<NSCoding>)object forKey:(NSString *)key withBlock:(void(^)(void))block;

/**
 Removes the value of the specified key in the cache.
 This method may blocks the calling thread until file delete finished.
 
 根据指定的key移除磁盘缓存的缓存，可能有阻塞线程
 
 @param key The key identifying the value to be removed. If nil, this method has no effect.
 */
- (void)removeObjectForKey:(NSString *)key;

/**
 Removes the value of the specified key in the cache.
 This method returns immediately and invoke the passed block in background queue
 when the operation finished.
 
 根据指定的key移除磁盘缓存的缓存，会在后台队列回调block，不会阻塞线程
 
 @param key The key identifying the value to be removed. If nil, this method has no effect.
 @param block  A block which will be invoked in background queue when finished.
 */
- (void)removeObjectForKey:(NSString *)key withBlock:(void(^)(NSString *key))block;

/**
 Empties the cache.
 This method may blocks the calling thread until file delete finished.
 
 移除所有的缓存，会阻塞线程
 */
- (void)removeAllObjects;

/**
 Empties the cache.
 This method returns immediately and invoke the passed block in background queue
 when the operation finished.
 
 移除所有缓存，不会阻塞线程，后在后台队列中回调block
 
 @param block  A block which will be invoked in background queue when finished.
 */
- (void)removeAllObjectsWithBlock:(void(^)(void))block;

/**
 Empties the cache with block.
 This method returns immediately and executes the clear operation with block in background.
 
 移除所有缓存的对象，不会阻塞线程，progress和endblock后在后台线程回调
 
 @warning You should not send message to this instance in these blocks.
 @param progress This block will be invoked during removing, pass nil to ignore.
 @param end      This block will be invoked at the end, pass nil to ignore.
 */
- (void)removeAllObjectsWithProgressBlock:(nullable void(^)(int removedCount, int totalCount))progress
                                 endBlock:(nullable void(^)(BOOL error))end;


/**
 Returns the number of objects in this cache.
 This method may blocks the calling thread until file read finished.
 
 返回已经缓存的数量，会阻塞线程
 
 @return The total objects count.
 */
- (NSInteger)totalCount;

/**
 Get the number of objects in this cache.
 This method returns immediately and invoke the passed block in background queue
 when the operation finished.
 
 获取已经缓存的数量，不会阻塞线程，会在后台队列回调block
 
 @param block  A block which will be invoked in background queue when finished.
 */
- (void)totalCountWithBlock:(void(^)(NSInteger totalCount))block;

/**
 Returns the total cost (in bytes) of objects in this cache.
 This method may blocks the calling thread until file read finished.
 
 返回已经占用的空间，回阻塞线程
 
 @return The total objects cost in bytes.
 */
- (NSInteger)totalCost;

/**
 Get the total cost (in bytes) of objects in this cache.
 This method returns immediately and invoke the passed block in background queue
 when the operation finished.
 
 获取已经占用的空间，不会阻塞线程，会在后台队列回调block
 
 @param block  A block which will be invoked in background queue when finished.
 */
- (void)totalCostWithBlock:(void(^)(NSInteger totalCost))block;


#pragma mark - Trim
///=============================================================================
/// @name Trim
///=============================================================================

/**
 Removes objects from the cache use LRU, until the `totalCount` is below the specified value.
 This method may blocks the calling thread until operation finished.
 
 移除缓存到指定的数量，可能会阻塞线程
 
 @param count  The total count allowed to remain after the cache has been trimmed.
 */
- (void)trimToCount:(NSUInteger)count;

/**
 Removes objects from the cache use LRU, until the `totalCount` is below the specified value.
 This method returns immediately and invoke the passed block in background queue
 when the operation finished.
 
 移除缓存到指定的数量，不会阻塞线程，在后台队列回调block
 
 @param count  The total count allowed to remain after the cache has been trimmed.
 @param block  A block which will be invoked in background queue when finished.
 */
- (void)trimToCount:(NSUInteger)count withBlock:(void(^)(void))block;

/**
 Removes objects from the cache use LRU, until the `totalCost` is below the specified value.
 This method may blocks the calling thread until operation finished.
 
 移除缓存直到指定的空间，可能会阻塞线程
 
 @param cost The total cost allowed to remain after the cache has been trimmed.
 */
- (void)trimToCost:(NSUInteger)cost;

/**
 Removes objects from the cache use LRU, until the `totalCost` is below the specified value.
 This method returns immediately and invoke the passed block in background queue
 when the operation finished.
 
 移除缓存直到指定的空间，不会阻塞线程，在后台队列回调block
 
 @param cost The total cost allowed to remain after the cache has been trimmed.
 @param block  A block which will be invoked in background queue when finished.
 */
- (void)trimToCost:(NSUInteger)cost withBlock:(void(^)(void))block;

/**
 Removes objects from the cache use LRU, until all expiry objects removed by the specified value.
 This method may blocks the calling thread until operation finished.
 
 移除缓存直到指定的时间之前，可能会阻塞线程
 
 @param age  The maximum age of the object.
 */
- (void)trimToAge:(NSTimeInterval)age;

/**
 Removes objects from the cache use LRU, until all expiry objects removed by the specified value.
 This method returns immediately and invoke the passed block in background queue
 when the operation finished.
 
 移除缓存直到指定的时间之前，不会阻塞线程，在后台队列回调
 
 @param age  The maximum age of the object.
 @param block  A block which will be invoked in background queue when finished.
 */
- (void)trimToAge:(NSTimeInterval)age withBlock:(void(^)(void))block;


#pragma mark - Extended Data
///=============================================================================
/// @name Extended Data
///=============================================================================

/**
 Get extended data from an object.
 
 获取对象的扩展数据对象
 
 @discussion See 'setExtendedData:toObject:' for more information.
 
 @param object An object.
 @return The extended data.
 */
+ (nullable NSData *)getExtendedDataFromObject:(id)object;

/**
 Set extended data to an object.
 
 在将对象保存到磁盘之前你可以为对象设置扩展数据，扩展数据会和对象一起储存
 
 @discussion You can set any extended data to an object before you save the object
 to disk cache. The extended data will also be saved with this object. You can get
 the extended data later with "getExtendedDataFromObject:".
 
 @param extendedData The extended data (pass nil to remove).
 @param object       The object.
 */
+ (void)setExtendedData:(nullable NSData *)extendedData toObject:(id)object;

@end

NS_ASSUME_NONNULL_END
