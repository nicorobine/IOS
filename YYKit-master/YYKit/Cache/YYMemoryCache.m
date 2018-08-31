//
//  YYMemoryCache.m
//  YYKit <https://github.com/ibireme/YYKit>
//
//  Created by ibireme on 15/2/7.
//  Copyright (c) 2015 ibireme.
//
//  This source code is licensed under the MIT-style license found in the
//  LICENSE file in the root directory of this source tree.
//

#import "YYMemoryCache.h"
#import <UIKit/UIKit.h>
#import <CoreFoundation/CoreFoundation.h>
#import <QuartzCore/QuartzCore.h>
#import <pthread.h>

#if __has_include("YYDispatchQueuePool.h")
#import "YYDispatchQueuePool.h"
#endif

// 如果导入了YYDispatchQueuePool类，则使用YYDispatchQueueGetForQOS获取队列
// 如果没有导入获取golbal队列
#ifdef YYDispatchQueuePool_h
static inline dispatch_queue_t YYMemoryCacheGetReleaseQueue() {
    return YYDispatchQueueGetForQOS(NSQualityOfServiceUtility);
}
#else
static inline dispatch_queue_t YYMemoryCacheGetReleaseQueue() {
    return dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0);
}
#endif

/**
 A node in linked map.
 Typically, you should not use this class directly.
 链表的节点，不要直接使用
 */
@interface _YYLinkedMapNode : NSObject {
    @package
    // 指向上一个节点
    __unsafe_unretained _YYLinkedMapNode *_prev; // retained by dic
    // 指向下一个节点
    __unsafe_unretained _YYLinkedMapNode *_next; // retained by dic
    id _key;
    id _value;
    NSUInteger _cost;
    NSTimeInterval _time;
}
@end

@implementation _YYLinkedMapNode
@end


/**
 A linked map used by YYMemoryCache.
 It's not thread-safe and does not validate the parameters.
 
 这是YYMemoryCache使用的链表，不是线程安全的，而且不验证参数
 不要直接修改，使用_YYLinkedMap提供的方法修改
 
 Typically, you should not use this class directly.
 */
@interface _YYLinkedMap : NSObject {
    @package
    CFMutableDictionaryRef _dic; // do not set object directly
    NSUInteger _totalCost;
    NSUInteger _totalCount;
    _YYLinkedMapNode *_head; // MRU, do not change it directly
    _YYLinkedMapNode *_tail; // LRU, do not change it directly
    BOOL _releaseOnMainThread;   // 是否在主线程释放 默认NO
    BOOL _releaseAsynchronously; // 是否异步释放    默认YES
}

/// Insert a node at head and update the total cost.
/// Node and node.key should not be nil.
// 向链表的头部插入一个节点，更新totalCost，需要注意的是node和node.key不能为nil
- (void)insertNodeAtHead:(_YYLinkedMapNode *)node;

/// Bring a inner node to header.
/// Node should already inside the dic.
// 将指定的节点放到链表的头部，节点应该已经在dic里
- (void)bringNodeToHead:(_YYLinkedMapNode *)node;

/// Remove a inner node and update the total cost.
/// Node should already inside the dic.
// 移除一个节点，并更新totalCost，节点应该在dic里
- (void)removeNode:(_YYLinkedMapNode *)node;

/// Remove tail node if exist.
// 移除最后一个节点
- (_YYLinkedMapNode *)removeTailNode;

/// Remove all node in background queue.
// 移除所有节点
- (void)removeAll;

@end

@implementation _YYLinkedMap

// 初始化map
- (instancetype)init {
    self = [super init];
    _dic = CFDictionaryCreateMutable(CFAllocatorGetDefault(), 0, &kCFTypeDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks);
    _releaseOnMainThread = NO;
    _releaseAsynchronously = YES;
    return self;
}

// map释放的时候同时释放_dic, CoreFoundation的对象ARC不管理
- (void)dealloc {
    CFRelease(_dic);
}

// 将一个节点插入链表的头部
- (void)insertNodeAtHead:(_YYLinkedMapNode *)node {
    // 存入字典
    CFDictionarySetValue(_dic, (__bridge const void *)(node->_key), (__bridge const void *)(node));
    // 累计花费
    _totalCost += node->_cost;
    // 累计数量
    _totalCount++;
    // 如果有_head将_node放到头部，如果没有证明是一个新的链表，_head和_tail都指向node
    if (_head) {
        node->_next = _head;
        _head->_prev = node;
        _head = node;
    } else {
        _head = _tail = node;
    }
}

// 将一个已经存在的节点放到head
// 这里需要注意的是如果node不在链表里面，会将这个node添加到链表的头部
- (void)bringNodeToHead:(_YYLinkedMapNode *)node {
    if (_head == node) return;
    
    if (_tail == node) {
        _tail = node->_prev;
        _tail->_next = nil;
    } else {
        node->_next->_prev = node->_prev;
        node->_prev->_next = node->_next;
    }
    node->_next = _head;
    node->_prev = nil;
    _head->_prev = node;
    _head = node;
}

// 移除一个节点
- (void)removeNode:(_YYLinkedMapNode *)node {
    CFDictionaryRemoveValue(_dic, (__bridge const void *)(node->_key));
    _totalCost -= node->_cost;
    _totalCount--;
    if (node->_next) node->_next->_prev = node->_prev;
    if (node->_prev) node->_prev->_next = node->_next;
    if (_head == node) _head = node->_next;
    if (_tail == node) _tail = node->_prev;
}

// 移除最后一个节点
- (_YYLinkedMapNode *)removeTailNode {
    if (!_tail) return nil;
    _YYLinkedMapNode *tail = _tail;
    CFDictionaryRemoveValue(_dic, (__bridge const void *)(_tail->_key));
    _totalCost -= _tail->_cost;
    _totalCount--;
    if (_head == _tail) {
        _head = _tail = nil;
    } else {
        _tail = _tail->_prev;
        _tail->_next = nil;
    }
    return tail;
}
// 清除所有的节点
- (void)removeAll {
    _totalCost = 0;
    _totalCount = 0;
    _head = nil;
    _tail = nil;
    // 释放缓存字典
    if (CFDictionaryGetCount(_dic) > 0) {
        // 创建一个临时变量指向_dic,_dic再指向一个新的对象
        // 使用临时变量释放原来的缓存
        CFMutableDictionaryRef holder = _dic;
        _dic = CFDictionaryCreateMutable(CFAllocatorGetDefault(), 0, &kCFTypeDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks);
        
        // 如果是异步释放，则在根据是否要在主线程释放去异步释放holder
        if (_releaseAsynchronously) {
            dispatch_queue_t queue = _releaseOnMainThread ? dispatch_get_main_queue() : YYMemoryCacheGetReleaseQueue();
            dispatch_async(queue, ^{
                CFRelease(holder); // hold and release in specified queue
            });
        }
        // 如果不是异步释放，且在主线程释放，而且当前线程不在主线程，则在主线程异步释放
        else if (_releaseOnMainThread && !pthread_main_np()) {
            dispatch_async(dispatch_get_main_queue(), ^{
                CFRelease(holder); // hold and release in specified queue
            });
        }
        // 其他情况下，在本线程释放
        else {
            CFRelease(holder);
        }
    }
}

@end



@implementation YYMemoryCache {
    // 同步锁
    pthread_mutex_t _lock;
    // 缓存链表
    _YYLinkedMap *_lru;
    // 清除缓存的线性队列
    dispatch_queue_t _queue;
}

// 自动回收缓存的递归循环
// 这里的处理有意思并不是使用定时器处理的，使用dispatch_after,每次调用block后重新调用本方法清理
- (void)_trimRecursively {
    // 防止循环引用
    __weak typeof(self) _self = self;
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(_autoTrimInterval * NSEC_PER_SEC)), dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0), ^{
        __strong typeof(_self) self = _self;
        if (!self) return;
        [self _trimInBackground];
        [self _trimRecursively];
    });
}

// 在回收队列里面回收超过了消耗、数量和时间的缓存
- (void)_trimInBackground {
    dispatch_async(_queue, ^{
        [self _trimToCost:self->_costLimit];
        [self _trimToCount:self->_countLimit];
        [self _trimToAge:self->_ageLimit];
    });
}

// 回收超过花费的缓存
- (void)_trimToCost:(NSUInteger)costLimit {
    BOOL finish = NO;
    // 先判断costLimit为0和没有超过限制的情况
    pthread_mutex_lock(&_lock);
    if (costLimit == 0) {
        [_lru removeAll];
        finish = YES;
    } else if (_lru->_totalCost <= costLimit) {
        finish = YES;
    }
    pthread_mutex_unlock(&_lock);
    if (finish) return;
    
    // 用来暂时储存要删除的缓存
    NSMutableArray *holder = [NSMutableArray new];
    while (!finish) {
        // 尝试获取锁，如果没有获取到锁，则线程休眠10ms后再次尝试获取锁，依次类推
        // 自己猜想原因，因为释放多余缓存的优先级比较低，所以会尝试获取锁，直到获取
        // 到锁才删除多余缓存
        // @note 作者的锁选用的是同步锁，并没有采用递归锁，猜测原因是用这种方法来实现
        // 低优先级释放多余缓存
        if (pthread_mutex_trylock(&_lock) == 0) {
            if (_lru->_totalCost > costLimit) {
                _YYLinkedMapNode *node = [_lru removeTailNode];
                if (node) [holder addObject:node];
            } else {
                finish = YES;
            }
            pthread_mutex_unlock(&_lock);
        } else {
            usleep(10 * 1000); //10 ms
        }
    }
    // 在异步线程释放要释放多余的缓存
    if (holder.count) {
        dispatch_queue_t queue = _lru->_releaseOnMainThread ? dispatch_get_main_queue() : YYMemoryCacheGetReleaseQueue();
        dispatch_async(queue, ^{
            [holder count]; // release in queue
        });
    }
}

// 回收超过最大数量限制的缓存
// 处理方法类似_trimToCost:
- (void)_trimToCount:(NSUInteger)countLimit {
    BOOL finish = NO;
    pthread_mutex_lock(&_lock);
    if (countLimit == 0) {
        [_lru removeAll];
        finish = YES;
    } else if (_lru->_totalCount <= countLimit) {
        finish = YES;
    }
    pthread_mutex_unlock(&_lock);
    if (finish) return;
    
    NSMutableArray *holder = [NSMutableArray new];
    while (!finish) {
        if (pthread_mutex_trylock(&_lock) == 0) {
            if (_lru->_totalCount > countLimit) {
                _YYLinkedMapNode *node = [_lru removeTailNode];
                if (node) [holder addObject:node];
            } else {
                finish = YES;
            }
            pthread_mutex_unlock(&_lock);
        } else {
            usleep(10 * 1000); //10 ms
        }
    }
    if (holder.count) {
        dispatch_queue_t queue = _lru->_releaseOnMainThread ? dispatch_get_main_queue() : YYMemoryCacheGetReleaseQueue();
        dispatch_async(queue, ^{
            [holder count]; // release in queue
        });
    }
}

// 回收超过最大期限限制的缓存
// 处理方法类似_trimToCost:
- (void)_trimToAge:(NSTimeInterval)ageLimit {
    BOOL finish = NO;
    NSTimeInterval now = CACurrentMediaTime();
    pthread_mutex_lock(&_lock);
    if (ageLimit <= 0) {
        [_lru removeAll];
        finish = YES;
    } else if (!_lru->_tail || (now - _lru->_tail->_time) <= ageLimit) {
        finish = YES;
    }
    pthread_mutex_unlock(&_lock);
    if (finish) return;
    
    NSMutableArray *holder = [NSMutableArray new];
    while (!finish) {
        if (pthread_mutex_trylock(&_lock) == 0) {
            if (_lru->_tail && (now - _lru->_tail->_time) > ageLimit) {
                _YYLinkedMapNode *node = [_lru removeTailNode];
                if (node) [holder addObject:node];
            } else {
                finish = YES;
            }
            pthread_mutex_unlock(&_lock);
        } else {
            usleep(10 * 1000); //10 ms
        }
    }
    if (holder.count) {
        dispatch_queue_t queue = _lru->_releaseOnMainThread ? dispatch_get_main_queue() : YYMemoryCacheGetReleaseQueue();
        dispatch_async(queue, ^{
            [holder count]; // release in queue
        });
    }
}

// 监测收到系统内存警告的通知
- (void)_appDidReceiveMemoryWarningNotification {
    // 如果设置了内存警告block，执行block
    if (self.didReceiveMemoryWarningBlock) {
        self.didReceiveMemoryWarningBlock(self);
    }
    // 如果设置了收到内存警告清除所有的缓存（默认YES），清理有所缓存
    if (self.shouldRemoveAllObjectsOnMemoryWarning) {
        [self removeAllObjects];
    }
}

// 监测收到进入后台的通知
- (void)_appDidEnterBackgroundNotification {
    // 回调block
    if (self.didEnterBackgroundBlock) {
        self.didEnterBackgroundBlock(self);
    }
    // 根据设置决定是否清理全部缓存
    if (self.shouldRemoveAllObjectsWhenEnteringBackground) {
        [self removeAllObjects];
    }
}

#pragma mark - public
// 初始化方法
- (instancetype)init {
    self = super.init;
    // 初始互斥化锁
    pthread_mutex_init(&_lock, NULL);
    // 初始化链表
    _lru = [_YYLinkedMap new];
    // 初始化缓存队列
    _queue = dispatch_queue_create("com.ibireme.cache.memory", DISPATCH_QUEUE_SERIAL);
    
    // 初始化一些默认设置
    _countLimit = NSUIntegerMax;
    _costLimit = NSUIntegerMax;
    _ageLimit = DBL_MAX;
    _autoTrimInterval = 5.0;
    _shouldRemoveAllObjectsOnMemoryWarning = YES;
    _shouldRemoveAllObjectsWhenEnteringBackground = YES;
    
    // 添加监听app收到内存警告和进入后台
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_appDidReceiveMemoryWarningNotification) name:UIApplicationDidReceiveMemoryWarningNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_appDidEnterBackgroundNotification) name:UIApplicationDidEnterBackgroundNotification object:nil];
    
    // 执行缓存检测递归
    [self _trimRecursively];
    return self;
}

// 对象被释放后移除通知，清除缓存
- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationDidReceiveMemoryWarningNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationDidEnterBackgroundNotification object:nil];
    [_lru removeAll];
    pthread_mutex_destroy(&_lock);
}

/**
 这里是各种属性的getter方法和setter方法
 */
- (NSUInteger)totalCount {
    pthread_mutex_lock(&_lock);
    NSUInteger count = _lru->_totalCount;
    pthread_mutex_unlock(&_lock);
    return count;
}

- (NSUInteger)totalCost {
    pthread_mutex_lock(&_lock);
    NSUInteger totalCost = _lru->_totalCost;
    pthread_mutex_unlock(&_lock);
    return totalCost;
}

- (BOOL)releaseOnMainThread {
    pthread_mutex_lock(&_lock);
    BOOL releaseOnMainThread = _lru->_releaseOnMainThread;
    pthread_mutex_unlock(&_lock);
    return releaseOnMainThread;
}

- (void)setReleaseOnMainThread:(BOOL)releaseOnMainThread {
    pthread_mutex_lock(&_lock);
    _lru->_releaseOnMainThread = releaseOnMainThread;
    pthread_mutex_unlock(&_lock);
}

- (BOOL)releaseAsynchronously {
    pthread_mutex_lock(&_lock);
    BOOL releaseAsynchronously = _lru->_releaseAsynchronously;
    pthread_mutex_unlock(&_lock);
    return releaseAsynchronously;
}

- (void)setReleaseAsynchronously:(BOOL)releaseAsynchronously {
    pthread_mutex_lock(&_lock);
    _lru->_releaseAsynchronously = releaseAsynchronously;
    pthread_mutex_unlock(&_lock);
}

// 缓存中是否包含指定key的对象
- (BOOL)containsObjectForKey:(id)key {
    if (!key) return NO;
    pthread_mutex_lock(&_lock);
    BOOL contains = CFDictionaryContainsKey(_lru->_dic, (__bridge const void *)(key));
    pthread_mutex_unlock(&_lock);
    return contains;
}

// 根据key获取对象
- (id)objectForKey:(id)key {
    if (!key) return nil;
    pthread_mutex_lock(&_lock);
    _YYLinkedMapNode *node = CFDictionaryGetValue(_lru->_dic, (__bridge const void *)(key));
    if (node) {
        // CACurrentMediaTime() 从手机开机到当前经历的秒数
        node->_time = CACurrentMediaTime();
        // 每次访问一个对象把对象放到链表头部
        [_lru bringNodeToHead:node];
    }
    pthread_mutex_unlock(&_lock);
    return node ? node->_value : nil;
}

// 保存缓存对象
- (void)setObject:(id)object forKey:(id)key {
    [self setObject:object forKey:key withCost:0];
}

- (void)setObject:(id)object forKey:(id)key withCost:(NSUInteger)cost {
    // 如果key为nil直接返回
    if (!key) return;
    // 如果object为空，删除key对应的对象
    if (!object) {
        [self removeObjectForKey:key];
        return;
    }
    // 请求锁访问缓存数据
    pthread_mutex_lock(&_lock);
    // 根据key获取节点，如果已经存在节点，更新缓存数据的cost、time、value、以及totalCost，并把节点放到头部
    // 如果不存在节点，创建一个新的节点，保存缓存信息，然后放到链表头部
    _YYLinkedMapNode *node = CFDictionaryGetValue(_lru->_dic, (__bridge const void *)(key));
    NSTimeInterval now = CACurrentMediaTime();
    if (node) {
        _lru->_totalCost -= node->_cost;
        _lru->_totalCost += cost;
        node->_cost = cost;
        node->_time = now;
        node->_value = object;
        [_lru bringNodeToHead:node];
    } else {
        node = [_YYLinkedMapNode new];
        node->_cost = cost;
        node->_time = now;
        node->_key = key;
        node->_value = object;
        [_lru insertNodeAtHead:node];
    }
    // 根据是否超过花费限制，决定是否清除部分缓存
    if (_lru->_totalCost > _costLimit) {
        // 这里必须异步执行，因为trimToCost获取了锁，不然会造成死锁
        dispatch_async(_queue, ^{
            [self trimToCost:_costLimit];
        });
    }
    // 根据缓存数量限制，决定是否清除部分缓存
    if (_lru->_totalCount > _countLimit) {
        // 如果超过限制，移除最后一个node，然后将node在异步释放
        _YYLinkedMapNode *node = [_lru removeTailNode];
        if (_lru->_releaseAsynchronously) {
            dispatch_queue_t queue = _lru->_releaseOnMainThread ? dispatch_get_main_queue() : YYMemoryCacheGetReleaseQueue();
            // 确保在queue中释放
            dispatch_async(queue, ^{
                [node class]; //hold and release in queue
            });
        } else if (_lru->_releaseOnMainThread && !pthread_main_np()) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [node class]; //hold and release in queue
            });
        }
    }
    pthread_mutex_unlock(&_lock);
}

// 根据key移除缓存的对象
- (void)removeObjectForKey:(id)key {
    if (!key) return;
    pthread_mutex_lock(&_lock);
    // 根据key获取缓存节点，如果存在node节点，将节点从链表里面删除，并异步释放改节点对象
    _YYLinkedMapNode *node = CFDictionaryGetValue(_lru->_dic, (__bridge const void *)(key));
    if (node) {
        [_lru removeNode:node];
        if (_lru->_releaseAsynchronously) {
            dispatch_queue_t queue = _lru->_releaseOnMainThread ? dispatch_get_main_queue() : YYMemoryCacheGetReleaseQueue();
            dispatch_async(queue, ^{
                [node class]; //hold and release in queue
            });
        } else if (_lru->_releaseOnMainThread && !pthread_main_np()) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [node class]; //hold and release in queue
            });
        }
    }
    pthread_mutex_unlock(&_lock);
}

// 清除所有缓存
- (void)removeAllObjects {
    pthread_mutex_lock(&_lock);
    [_lru removeAll];
    pthread_mutex_unlock(&_lock);
}

// 根据指定的缓存数清理缓存
- (void)trimToCount:(NSUInteger)count {
    if (count == 0) {
        [self removeAllObjects];
        return;
    }
    [self _trimToCount:count];
}

// 根据空间消耗清理缓存
- (void)trimToCost:(NSUInteger)cost {
    [self _trimToCost:cost];
}

// 根据时间清理缓存
- (void)trimToAge:(NSTimeInterval)age {
    [self _trimToAge:age];
}

// 重写description，方便调试
- (NSString *)description {
    if (_name) return [NSString stringWithFormat:@"<%@: %p> (%@)", self.class, self, _name];
    else return [NSString stringWithFormat:@"<%@: %p>", self.class, self];
}

@end
