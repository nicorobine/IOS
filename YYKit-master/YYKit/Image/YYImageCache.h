//
//  YYImageCache.h
//  YYKit <https://github.com/ibireme/YYKit>
//
//  Created by ibireme on 15/2/15.
//  Copyright (c) 2015 ibireme.
//
//  This source code is licensed under the MIT-style license found in the
//  LICENSE file in the root directory of this source tree.
//

#import <UIKit/UIKit.h>

@class YYMemoryCache, YYDiskCache;

NS_ASSUME_NONNULL_BEGIN

/// Image cache type
typedef NS_OPTIONS(NSUInteger, YYImageCacheType) {
    /// No value.
    // 不缓存
    YYImageCacheTypeNone   = 0,
    
    /// Get/store image with memory cache.
    // 内存缓存
    YYImageCacheTypeMemory = 1 << 0,
    
    /// Get/store image with disk cache.
    // 磁盘缓存
    YYImageCacheTypeDisk   = 1 << 1,
    
    /// Get/store image with both memory cache and disk cache.
    // 内存缓存和磁盘缓存
    YYImageCacheTypeAll    = YYImageCacheTypeMemory | YYImageCacheTypeDisk,
};


/**
 YYImageCache is a cache that stores UIImage and image data based on memory cache and disk cache.
 
 @discussion The disk cache will try to protect the original image data:
 
 * If the original image is still image, it will be saved as png/jpeg file based on alpha information.
 * If the original image is animated gif, apng or webp, it will be saved as original format.
 * If the original image's scale is not 1, the scale value will be saved as extended data.
 
 * 如果原始图片是静态图片，将会基于alpha通道信息将图片存在png/jpeg类型的图片
 * 如果原始图片是动态gif、apng或者webp类型的动态图片，会以原始格式存储
 * 如果原始图片的scale不是1，scale的值会在附加数据中存储
 
 Although UIImage can be serialized with NSCoding protocol, but it's not a good idea:
 Apple actually use UIImagePNGRepresentation() to encode all kind of image, it may 
 lose the original multi-frame data. The result is packed to plist file and cannot
 view with photo viewer directly. If the image has no alpha channel, using JPEG 
 instead of PNG can save more disk size and encoding/decoding time.
 
 当然UIImage类型的对象可以使用NSCoding协议储存，但是这不是一个号方法：
 Apple实际上使用UIImagePNGRepresentation() 来编码所有类型的图片，着可能导致丢失原始多帧的数据。而且结果缓存在plist文件，并不能使用图片查看器直接查看。如果图片没有alpha通道，使用JPEG来代替PNG可以节省更多的磁盘空间、编码和解码时间。
 */
@interface YYImageCache : NSObject

#pragma mark - Attribute
///=============================================================================
/// @name Attribute
///=============================================================================

/** The name of the cache. Default is nil. */
@property (nullable, copy) NSString *name;

/** The underlying memory cache. see `YYMemoryCache` for more information.*/
// 内存缓存
@property (strong, readonly) YYMemoryCache *memoryCache;

/** The underlying disk cache. see `YYDiskCache` for more information.*/
// 硬盘缓存
@property (strong, readonly) YYDiskCache *diskCache;

/**
 Whether decode animated image when fetch image from disk cache. Default is YES.
 
 从磁盘中获取图片的时候是否解码同台图片，默认解码
 
 @discussion When fetch image from disk cache, it will use 'YYImage' to decode 
 animated image such as WebP/APNG/GIF. Set to 'NO' to ignore animated image.
 */
@property BOOL allowAnimatedImage;

/**
 Whether decode the image to memory bitmap. Default is YES.
 
 是否将图片解码为内存位图，默认为YES
 
 @discussion If the value is YES, then the image will be decoded to memory bitmap
 for better display performance, but may cost more memory.
 */
@property BOOL decodeForDisplay;


#pragma mark - Initializer
///=============================================================================
/// @name Initializer 各种初始化方法
///=============================================================================
- (instancetype)init UNAVAILABLE_ATTRIBUTE;
+ (instancetype)new UNAVAILABLE_ATTRIBUTE;

/**
 Returns global shared image cache instance.
 @return  The singleton YYImageCache instance.
 */
+ (instancetype)sharedCache;

/**
 The designated initializer. Multiple instances with the same path will make the
 cache unstable.
 
 @param path Full path of a directory in which the cache will write data.
 Once initialized you should not read and write to this directory.
 @result A new cache object, or nil if an error occurs.
 */
- (nullable instancetype)initWithPath:(NSString *)path NS_DESIGNATED_INITIALIZER;


#pragma mark - Access Methods
///=============================================================================
/// @name Access Methods
///=============================================================================

/**
 Sets the image with the specified key in the cache (both memory and disk).
 This method returns immediately and executes the store operation in background.
 
 使用key缓存这个图片（内存和磁盘），这个方法会直接返回，实际储存操作在一个后台队列
 
 @param image The image to be stored in the cache. If nil, this method has no effect.
 @param key   The key with which to associate the image. If nil, this method has no effect.
 */
- (void)setImage:(UIImage *)image forKey:(NSString *)key;

/**
 Sets the image with the specified key in the cache.
 This method returns immediately and executes the store operation in background.
 
 使用key缓存这个图片（可以选择缓存类型和图片数据缓存方式），这个方法会直接返回，实际储存操作在一个后台队列
 
 @discussion If the `type` contain `YYImageCacheTypeMemory`, then the `image` will 
 be stored in the memory cache; `imageData` will be used instead if `image` is nil.
 If the `type` contain `YYImageCacheTypeDisk`, then the `imageData` will
 be stored in the disk cache; `image` will be used instead if `imageData` is nil.
 
 @param image     The image to be stored in the cache.
 @param imageData The image data to be stored in the cache.
 @param key       The key with which to associate the image. If nil, this method has no effect.
 @param type      The cache type to store image.
 */
- (void)setImage:(nullable UIImage *)image
       imageData:(nullable NSData *)imageData
          forKey:(NSString *)key
        withType:(YYImageCacheType)type;

/**
 Removes the image of the specified key in the cache (both memory and disk).
 This method returns immediately and executes the remove operation in background.
 
 根据key移除缓存，这个方法马上返回，实际移除操作在后台队列
 
 @param key The key identifying the image to be removed. If nil, this method has no effect.
 */
- (void)removeImageForKey:(NSString *)key;

/**
 Removes the image of the specified key in the cache.
 This method returns immediately and executes the remove operation in background.
 
 根据key移除缓存指定的缓存，这个方法马上返回，实际移除操作在后台队列
 
 @param key  The key identifying the image to be removed. If nil, this method has no effect.
 @param type The cache type to remove image.
 */
- (void)removeImageForKey:(NSString *)key withType:(YYImageCacheType)type;

/**
 Returns a Boolean value that indicates whether a given key is in cache.
 If the image is not in memory, this method may blocks the calling thread until 
 file read finished.
 
 某个key是否有缓存
 
 @param key A string identifying the image. If nil, just return NO.
 @return Whether the image is in cache.
 */
- (BOOL)containsImageForKey:(NSString *)key;

/**
 Returns a Boolean value that indicates whether a given key is in cache.
 If the image is not in memory and the `type` contains `YYImageCacheTypeDisk`,
 this method may blocks the calling thread until file read finished.
 
 某个key是否有指定类型的缓存
 
 @param key  A string identifying the image. If nil, just return NO.
 @param type The cache type.
 @return Whether the image is in cache.
 */
- (BOOL)containsImageForKey:(NSString *)key withType:(YYImageCacheType)type;

/**
 Returns the image associated with a given key.
 If the image is not in memory, this method may blocks the calling thread until
 file read finished.
 
 根据key获取缓存的图片，如果内存中没有缓存，在从磁盘读取缓存的时候会阻塞线程
 
 @param key A string identifying the image. If nil, just return nil.
 @return The image associated with key, or nil if no image is associated with key.
 */
- (nullable UIImage *)getImageForKey:(NSString *)key;

/**
 Returns the image associated with a given key.
 If the image is not in memory and the `type` contains `YYImageCacheTypeDisk`,
 this method may blocks the calling thread until file read finished.
 
 根据key从指定类型的缓存中获取图片（会阻塞线程）
 
 @param key A string identifying the image. If nil, just return nil.
 @return The image associated with key, or nil if no image is associated with key.
 */
- (nullable UIImage *)getImageForKey:(NSString *)key withType:(YYImageCacheType)type;

/**
 Asynchronously get the image associated with a given key.
 
 根据key获取指定类型的缓存（不会阻塞线程）
 
 @param key   A string identifying the image. If nil, just return nil.
 @param type  The cache type.
 @param block A completion block which will be called on main thread.
 */
- (void)getImageForKey:(NSString *)key
              withType:(YYImageCacheType)type
             withBlock:(void(^)(UIImage * _Nullable image, YYImageCacheType type))block;

/**
 Returns the image data associated with a given key.
 This method may blocks the calling thread until file read finished.
 
 根据key获取缓存的图片data
 
 @param key A string identifying the image. If nil, just return nil.
 @return The image data associated with key, or nil if no image is associated with key.
 */
- (nullable NSData *)getImageDataForKey:(NSString *)key;

/**
 Asynchronously get the image data associated with a given key.
 
 根据key，异步的获取缓存的图片data
 
 @param key   A string identifying the image. If nil, just return nil.
 @param block A completion block which will be called on main thread.
 */
- (void)getImageDataForKey:(NSString *)key
                 withBlock:(void(^)(NSData * _Nullable imageData))block;

@end

NS_ASSUME_NONNULL_END
