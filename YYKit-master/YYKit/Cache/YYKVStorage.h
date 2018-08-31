//
//  YYKVStorage.h
//  YYKit <https://github.com/ibireme/YYKit>
//
//  Created by ibireme on 15/4/22.
//  Copyright (c) 2015 ibireme.
//
//  This source code is licensed under the MIT-style license found in the
//  LICENSE file in the root directory of this source tree.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/**
 YYKVStorageItem is used by `YYKVStorage` to store key-value pair and meta data.
 Typically, you should not use this class directly.
 给YYKVStorage类型的对象使用的item，不要直接使用
 */
@interface YYKVStorageItem : NSObject
// 保存的key
@property (nonatomic, strong) NSString *key;                ///< key
// 保存的value
@property (nonatomic, strong) NSData *value;                ///< value
// 保存的文件名字，如果小于内联阀值，则为nil
@property (nullable, nonatomic, strong) NSString *filename; ///< filename (nil if inline)
// 文件大小
@property (nonatomic) int size;                             ///< value's size in bytes
// 修改时间（UNIX时间戳）
@property (nonatomic) int modTime;                          ///< modification unix timestamp
// 访问时间（UNIX时间戳）
@property (nonatomic) int accessTime;                       ///< last access unix timestamp
// 扩展数据
@property (nullable, nonatomic, strong) NSData *extendedData; ///< extended data (nil if no extended data)
@end

/**
 Storage type, indicated where the `YYKVStorageItem.value` stored.
 
 YYKVStorageItem.value的储存类型
 sqilte的写入速度高于文件，但是读取性能又数据的大小决定，作者测试当数据大于20k的时候从文件
 中读取数据的数独大于从sqite的读取速度
 
 * 如果你想储存大量的小数据，使用sqlite
 * 如果想储存大文件使用file
 * 同时可以使用Mixed为每个item选择储存类型
 
 @discussion Typically, write data to sqlite is faster than extern file, but 
 reading performance is dependent on data size. In my test (on iPhone 6 64G), 
 read data from extern file is faster than from sqlite when the data is larger 
 than 20KB.
 
 * If you want to store large number of small datas (such as contacts cache), 
   use YYKVStorageTypeSQLite to get better performance.
 * If you want to store large files (such as image cache),
   use YYKVStorageTypeFile to get better performance.
 * You can use YYKVStorageTypeMixed and choice your storage type for each item.
 
 See <http://www.sqlite.org/intern-v-extern-blob.html> for more information.
 */
typedef NS_ENUM(NSUInteger, YYKVStorageType) {
    
    /// The `value` is stored as a file in file system.
    YYKVStorageTypeFile = 0,
    
    /// The `value` is stored in sqlite with blob type.
    YYKVStorageTypeSQLite = 1,
    
    /// The `value` is stored in file system or sqlite based on your choice.
    YYKVStorageTypeMixed = 2,
};



/**
 YYKVStorage is a key-value storage based on sqlite and file system.
 Typically, you should not use this class directly.
 
 YYKVStorage是一个基于sqilte和文件系统的键值对缓存
 
 需要注意的是，这个类的实例不是线程安全的，你必须确保同义时间只能有一个线程能够访问到这个实例
 如果真的需要在多线程管理大量数据，你应该拆分数据到多个KVStorage实例（分片）
 
 @discussion The designated initializer for YYKVStorage is `initWithPath:type:`. 
 After initialized, a directory is created based on the `path` to hold key-value data.
 Once initialized you should not read or write this directory without the instance.
 
 You may compile the latest version of sqlite and ignore the libsqlite3.dylib in
 iOS system to get 2x~4x speed up.
 
 @warning The instance of this class is *NOT* thread safe, you need to make sure 
 that there's only one thread to access the instance at the same time. If you really 
 need to process large amounts of data in multi-thread, you should split the data
 to multiple KVStorage instance (sharding).
 */
@interface YYKVStorage : NSObject

#pragma mark - Attribute
///=============================================================================
/// @name Attribute
///=============================================================================
// 缓存路径
@property (nonatomic, readonly) NSString *path;        ///< The path of this storage.
// 缓存类型
@property (nonatomic, readonly) YYKVStorageType type;  ///< The type of this storage.
// 是否允许错误日志
@property (nonatomic) BOOL errorLogsEnabled;           ///< Set `YES` to enable error logs for debug.

#pragma mark - Initializer
///=============================================================================
/// @name Initializer
///=============================================================================
- (instancetype)init UNAVAILABLE_ATTRIBUTE;
+ (instancetype)new UNAVAILABLE_ATTRIBUTE;

/**
 The designated initializer.
 
 根据指定路径和类型实例化对象
 需要注意的是
 1.路径必须是全路径
 2.具有相同路径的多个实例将会使储存不稳定
 
 @param path  Full path of a directory in which the storage will write data. If
    the directory is not exists, it will try to create one, otherwise it will 
    read the data in this directory.
 @param type  The storage type. After first initialized you should not change the 
    type of the specified path.
 @return  A new storage object, or nil if an error occurs.
 @warning Multiple instances with the same path will make the storage unstable.
 */
- (nullable instancetype)initWithPath:(NSString *)path type:(YYKVStorageType)type NS_DESIGNATED_INITIALIZER;


#pragma mark - Save Items
///=============================================================================
/// @name Save Items
///=============================================================================

/**
 Save an item or update the item with 'key' if it already exists.
 
 保存item，如果item已经存在更新项目
 这个方法会保存item的key，value， fileName extentedData到sqilte或者disk，会忽略其他属性
 item的key和value不能为空（nil或者长度为0）
 
 如果type是文件的话，filename不能为空
 如果type是sqlite的话，fileName会被忽略
 如果type是mixed，如果文件名字不为空的话会储存到文件系统，否则会储存到sqlite
 
 @discussion This method will save the item.key, item.value, item.filename and
 item.extendedData to disk or sqlite, other properties will be ignored. item.key 
 and item.value should not be empty (nil or zero length).
 
 If the `type` is YYKVStorageTypeFile, then the item.filename should not be empty.
 If the `type` is YYKVStorageTypeSQLite, then the item.filename will be ignored.
 It the `type` is YYKVStorageTypeMixed, then the item.value will be saved to file 
 system if the item.filename is not empty, otherwise it will be saved to sqlite.
 
 @param item  An item.
 @return Whether succeed.
 */
- (BOOL)saveItem:(YYKVStorageItem *)item;

/**
 Save an item or update the item with 'key' if it already exists.
 
 保存一个item，如果已经存在，会根据key更新item
 这个方法只能将键值对储存到sqlite，如果_type的类型是YYKVStorageTypeFile，这个方法会失败
 
 @discussion This method will save the key-value pair to sqlite. If the `type` is
 YYKVStorageTypeFile, then this method will failed.
 
 @param key   The key, should not be empty (nil or zero length).
 @param value The key, should not be empty (nil or zero length).
 @return Whether succeed.
 */
- (BOOL)saveItemWithKey:(NSString *)key value:(NSData *)value;

/**
 Save an item or update the item with 'key' if it already exists.
 
 保存一个item，如果已经存在，会根据key更新item
 
 如果type是File，fileName不能为空
 如果type是SQLite，fileName会被忽略
 如果type是Mixed，如果指定了fileName会储存到文件系统，否则会存入sqlite
 
 @discussion
 If the `type` is YYKVStorageTypeFile, then the `filename` should not be empty.
 If the `type` is YYKVStorageTypeSQLite, then the `filename` will be ignored.
 It the `type` is YYKVStorageTypeMixed, then the `value` will be saved to file
 system if the `filename` is not empty, otherwise it will be saved to sqlite.
 
 @param key           The key, should not be empty (nil or zero length).
 @param value         The key, should not be empty (nil or zero length).
 @param filename      The filename.
 @param extendedData  The extended data for this item (pass nil to ignore it).
 
 @return Whether succeed.
 */
- (BOOL)saveItemWithKey:(NSString *)key
                  value:(NSData *)value
               filename:(nullable NSString *)filename
           extendedData:(nullable NSData *)extendedData;

#pragma mark - Remove Items
///=============================================================================
/// @name Remove Items
///=============================================================================

/**
 Remove an item with 'key'.
 
 根据key移除缓存
 
 @param key The item's key.
 @return Whether succeed.
 */
- (BOOL)removeItemForKey:(NSString *)key;

/**
 Remove items with an array of keys.
 
 根据keys移除缓存
 
 @param keys An array of specified keys.
 
 @return Whether succeed.
 */
- (BOOL)removeItemForKeys:(NSArray<NSString *> *)keys;

/**
 Remove all items which `value` is larger than a specified size.
 
 移除item.value的大小比指定大小大的所有items
 
 @param size  The maximum size in bytes.
 @return Whether succeed.
 */
- (BOOL)removeItemsLargerThanSize:(int)size;

/**
 Remove all items which last access time is earlier than a specified timestamp.
 
 移除最近访问时间小于指定时间戳的的item
 
 @param time  The specified unix timestamp.
 @return Whether succeed.
 */
- (BOOL)removeItemsEarlierThanTime:(int)time;

/**
 Remove items to make the total size not larger than a specified size.
 The least recently used (LRU) items will be removed first.
 
 移除一些item，使缓存的总大小小于指定的大小，会优先移除满足LRU的item
 
 @param maxSize The specified size in bytes.
 @return Whether succeed.
 */
- (BOOL)removeItemsToFitSize:(int)maxSize;

/**
 Remove items to make the total count not larger than a specified count.
 The least recently used (LRU) items will be removed first.
 
 移除一些item，使缓存的总数量小于指定的数量，会优先移除满足LRU的item
 
 @param maxCount The specified item count.
 @return Whether succeed.
 */
- (BOOL)removeItemsToFitCount:(int)maxCount;

/**
 Remove all items in background queue.
 
 在后台队列里移除所有的item
 这个方法会将files和sqlite数据库移动到一个垃圾文件夹，然后在后台队列清除这个文件夹
 所以这个方法会比removeAllItemsWithProgressBlock:endBlock:快的多
 
 @discussion This method will remove the files and sqlite database to a trash
 folder, and then clear the folder in background queue. So this method is much 
 faster than `removeAllItemsWithProgressBlock:endBlock:`.
 
 @return Whether succeed.
 */
- (BOOL)removeAllItems;

/**
 Remove all items.
 
 移除所有的item，需要注意的是不要在这些block中给这个实例发送消息
 
 @warning You should not send message to this instance in these blocks.
 @param progress This block will be invoked during removing, pass nil to ignore.
 @param end      This block will be invoked at the end, pass nil to ignore.
 */
- (void)removeAllItemsWithProgressBlock:(nullable void(^)(int removedCount, int totalCount))progress
                               endBlock:(nullable void(^)(BOOL error))end;


#pragma mark - Get Items
///=============================================================================
/// @name Get Items
///=============================================================================

/**
 Get item with a specified key.
 
 根据key获取item
 
 @param key A specified key.
 @return Item for the key, or nil if not exists / error occurs.
 */
- (nullable YYKVStorageItem *)getItemForKey:(NSString *)key;

/**
 Get item information with a specified key.
 The `value` in this item will be ignored.
 
 根据key获取item的信息，item的value会被忽略
 
 @param key A specified key.
 @return Item information for the key, or nil if not exists / error occurs.
 */
- (nullable YYKVStorageItem *)getItemInfoForKey:(NSString *)key;

/**
 Get item value with a specified key.
 
 根据指定的key获取item的value，也就是缓存的对象
 
 @param key  A specified key.
 @return Item's value, or nil if not exists / error occurs.
 */
- (nullable NSData *)getItemValueForKey:(NSString *)key;

/**
 Get items with an array of keys.
 
 根据keys获取items
 
 @param keys  An array of specified keys.
 @return An array of `YYKVStorageItem`, or nil if not exists / error occurs.
 */
- (nullable NSArray<YYKVStorageItem *> *)getItemForKeys:(NSArray<NSString *> *)keys;

/**
 Get item infomartions with an array of keys.
 The `value` in items will be ignored.
 
 根据keys获取items的信息
 
 @param keys  An array of specified keys.
 @return An array of `YYKVStorageItem`, or nil if not exists / error occurs.
 */
- (nullable NSArray<YYKVStorageItem *> *)getItemInfoForKeys:(NSArray<NSString *> *)keys;

/**
 Get items value with an array of keys.
 
 根据keys获取items的value
 
 @param keys  An array of specified keys.
 @return A dictionary which key is 'key' and value is 'value', or nil if not 
    exists / error occurs.
 */
- (nullable NSDictionary<NSString *, NSData *> *)getItemValueForKeys:(NSArray<NSString *> *)keys;

#pragma mark - Get Storage Status
///=============================================================================
/// @name Get Storage Status
///=============================================================================

/**
 Whether an item exists for a specified key.
 
 判断指定key是否已经有缓存
 
 @param key  A specified key.
 
 @return `YES` if there's an item exists for the key, `NO` if not exists or an error occurs.
 */
- (BOOL)itemExistsForKey:(NSString *)key;

/**
 Get total item count.
 获取缓存的数量
 @return Total item count, -1 when an error occurs.
 */
- (int)getItemsCount;

/**
 Get item value's total size in bytes.
 获取已经缓存的大小
 @return Total size in bytes, -1 when an error occurs.
 */
- (int)getItemsSize;

@end

NS_ASSUME_NONNULL_END
