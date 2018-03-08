/*
 * This file is part of the SDWebImage package.
 * (c) Olivier Poitrey <rs@dailymotion.com>
 *
 * For the full copyright and license information, please view the LICENSE
 * file that was distributed with this source code.
 */

#import <Foundation/Foundation.h>
#import "SDWebImageCompat.h"

@interface SDImageCacheConfig : NSObject

/**
 * wwt 解压下载和缓存的图片可以改进性能但是会消耗更多的内存，如果程序出现内存过大引起的崩溃设置成NO，默认位YES
 * Decompressing images that are downloaded and cached can improve performance but can consume lot of memory.
 * Defaults to YES. Set this to NO if you are experiencing a crash due to excessive memory consumption.
 */
@property (assign, nonatomic) BOOL shouldDecompressImages;

/**
 * wwt 禁用iCloud备份，默认YES
 * disable iCloud backup [defaults to YES]
 */
@property (assign, nonatomic) BOOL shouldDisableiCloud;

/**
 * wwt 使用内存缓存，默认位YES
 * use memory cache [defaults to YES]
 */
@property (assign, nonatomic) BOOL shouldCacheImagesInMemory;

/**
 * wwt 从硬盘读取缓存时的读取选项，默认位0，可以设置为“NSDataReadingMappedIfSafe”以改进性能
 * The reading options while reading cache from disk.
 * Defaults to 0. You can set this to `NSDataReadingMappedIfSafe` to improve performance.
 */
@property (assign, nonatomic) NSDataReadingOptions diskCacheReadingOptions;

/**
 * wwt 向硬盘写入数据时候的写入选项，默认时NSDataWritingAtomic，可以设置成NSDataWritingWithoutOverwriting防止覆盖已经存在的文件
 * The writing options while writing cache to disk.
 * Defaults to `NSDataWritingAtomic`. You can set this to `NSDataWritingWithoutOverwriting` to prevent overwriting an existing file.
 */
@property (assign, nonatomic) NSDataWritingOptions diskCacheWritingOptions;

/**
 * wwt 图片在缓存中存放的最长时间，以秒为单位，默认一周
 * The maximum length of time to keep an image in the cache, in seconds.
 */
@property (assign, nonatomic) NSInteger maxCacheAge;

/**
 * wwt 缓存的最大大小，以字节为单位
 * The maximum size of the cache, in bytes.
 */
@property (assign, nonatomic) NSUInteger maxCacheSize;

@end
