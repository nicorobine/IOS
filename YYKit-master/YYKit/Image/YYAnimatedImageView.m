//
//  YYAnimatedImageView.m
//  YYKit <https://github.com/ibireme/YYKit>
//
//  Created by ibireme on 14/10/19.
//  Copyright (c) 2015 ibireme.
//
//  This source code is licensed under the MIT-style license found in the
//  LICENSE file in the root directory of this source tree.
//

#import "YYAnimatedImageView.h"
#import "YYWeakProxy.h"
#import "UIDevice+YYAdd.h"
#import "YYImageCoder.h"
#import "YYKitMacro.h"

// 缓存大小
#define BUFFER_SIZE (10 * 1024 * 1024) // 10MB (minimum memory buffer size)

#define LOCK(...) dispatch_semaphore_wait(self->_lock, DISPATCH_TIME_FOREVER); \
__VA_ARGS__; \
dispatch_semaphore_signal(self->_lock);

#define LOCK_VIEW(...) dispatch_semaphore_wait(view->_lock, DISPATCH_TIME_FOREVER); \
__VA_ARGS__; \
dispatch_semaphore_signal(view->_lock);


typedef NS_ENUM(NSUInteger, YYAnimatedImageType) {
    YYAnimatedImageTypeNone = 0,
    YYAnimatedImageTypeImage,
    YYAnimatedImageTypeHighlightedImage,
    YYAnimatedImageTypeImages,
    YYAnimatedImageTypeHighlightedImages,
};

@interface YYAnimatedImageView() {
    @package
    // 当前的image
    UIImage <YYAnimatedImage> *_curAnimatedImage;
    // 缓存锁
    dispatch_semaphore_t _lock; ///< lock for _buffer
    // 请求队列
    NSOperationQueue *_requestQueue; ///< image request queue, serial
    
    // 改变帧的频率
    CADisplayLink *_link; ///< ticker for change frame
    // 上一帧的时间
    NSTimeInterval _time; ///< time after last frame
    
    // 当前展示的帧
    UIImage *_curFrame; ///< current frame to display
    // 当前帧的索引
    NSUInteger _curIndex; ///< current frame index (from 0)
    // 总帧数
    NSUInteger _totalFrameCount; ///< total frame count
    
    // 循环是否结束
    BOOL _loopEnd; ///< whether the loop is end.
    // 当前的循环次数
    NSUInteger _curLoop; ///< current loop count (from 0)
    // 总循环次数，0代表无限循环
    NSUInteger _totalLoop; ///< total loop count, 0 means infinity
    
    // 帧缓存
    NSMutableDictionary *_buffer; ///< frame buffer
    // 是否丢帧
    BOOL _bufferMiss; ///< whether miss frame on last opportunity
    // 最大帧缓存数量
    NSUInteger _maxBufferCount; ///< maximum buffer count
    // 当前缓存的帧数
    NSInteger _incrBufferCount; ///< current allowed buffer count (will increase by step)
    
    // 当前的帧的图形大小
    CGRect _curContentsRect;
    // 是否实现了animatedImageContentsRectAtIndex:当前帧图形的大小
    BOOL _curImageHasContentsRect; ///< image has implementated "animatedImageContentsRectAtIndex:"
}

@property (nonatomic, readwrite) BOOL currentIsPlayingAnimation;
// 根据当前的内存使用情况动态的适应缓存大小
- (void)calcMaxBufferCount;
@end

/// An operation for image fetch
@interface _YYAnimatedImageViewFetchOperation : NSOperation
@property (nonatomic, weak) YYAnimatedImageView *view;
@property (nonatomic, assign) NSUInteger nextIndex;
@property (nonatomic, strong) UIImage <YYAnimatedImage> *curImage;
@end

@implementation _YYAnimatedImageViewFetchOperation
- (void)main {
    // 使用变量获取_view，从而获取下一帧的索引，帧缓存数量，总帧数
    __strong YYAnimatedImageView *view = _view;
    if (!view) return;
    if ([self isCancelled]) return;
    view->_incrBufferCount++;
    if (view->_incrBufferCount == 0) [view calcMaxBufferCount];
    if (view->_incrBufferCount > (NSInteger)view->_maxBufferCount) {
        view->_incrBufferCount = view->_maxBufferCount;
    }
    NSUInteger idx = _nextIndex;
    NSUInteger max = view->_incrBufferCount < 1 ? 1 : view->_incrBufferCount;
    NSUInteger total = view->_totalFrameCount;
    view = nil;
    
    // 遍历所有缓存，如果缓存没有对应数据则获取图片数据放入缓存
    for (int i = 0; i < max; i++, idx++) {
        @autoreleasepool {
            // 如果下一帧大于总帧数，下一帧为第一帧
            if (idx >= total) idx = 0;
            // 是否取消了操作
            if ([self isCancelled]) break;
            __strong YYAnimatedImageView *view = _view;
            if (!view) break;
            // 判断下一帧是否加入了缓存，如果没有根据代理拿到下一帧的图片，并解压放入帧缓存
            LOCK_VIEW(BOOL miss = (view->_buffer[@(idx)] == nil));
            if (miss) {
                UIImage *img = [_curImage animatedImageFrameAtIndex:idx];
                img = img.imageByDecoded;
                if ([self isCancelled]) break;
                LOCK_VIEW(view->_buffer[@(idx)] = img ? img : [NSNull null]);
                view = nil;
            }
        }
    }
}
@end

@implementation YYAnimatedImageView

- (instancetype)init {
    self = [super init];
    _runloopMode = NSRunLoopCommonModes;
    _autoPlayAnimatedImage = YES;
    return self;
}

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    _runloopMode = NSRunLoopCommonModes;
    _autoPlayAnimatedImage = YES;
    return self;
}

- (instancetype)initWithImage:(UIImage *)image {
    self = [super init];
    _runloopMode = NSRunLoopCommonModes;
    _autoPlayAnimatedImage = YES;
    self.frame = (CGRect) {CGPointZero, image.size };
    self.image = image;
    return self;
}

- (instancetype)initWithImage:(UIImage *)image highlightedImage:(UIImage *)highlightedImage {
    self = [super init];
    _runloopMode = NSRunLoopCommonModes;
    _autoPlayAnimatedImage = YES;
    CGSize size = image ? image.size : highlightedImage.size;
    self.frame = (CGRect) {CGPointZero, size };
    self.image = image;
    self.highlightedImage = highlightedImage;
    return self;
}

// 初始化动画参数
// init the animated params.
- (void)resetAnimated {
    // 如果还没有初始化displayLink初始化
    if (!_link) {
        // 创建旗语锁
        _lock = dispatch_semaphore_create(1);
        // 创建缓存
        _buffer = [NSMutableDictionary new];
        // 创建请求队列，最大并发为1
        _requestQueue = [[NSOperationQueue alloc] init];
        _requestQueue.maxConcurrentOperationCount = 1;
        // 创建displayLink
        // 这里需要注意使用了NSProxy（weak），目的是当self释放的时候不再执行step:回调
        _link = [CADisplayLink displayLinkWithTarget:[YYWeakProxy proxyWithTarget:self] selector:@selector(step:)];
        // 如果设置了runloopMode将_link添加到runloop
        if (_runloopMode) {
            [_link addToRunLoop:[NSRunLoop mainRunLoop] forMode:_runloopMode];
        }
        // 暂时暂停link
        _link.paused = YES;
        
        // 添加内存警告和进入后台的通知
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didReceiveMemoryWarning:) name:UIApplicationDidReceiveMemoryWarningNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didEnterBackground:) name:UIApplicationDidEnterBackgroundNotification object:nil];
    }
    // 取消图片请求队列
    [_requestQueue cancelAllOperations];
    
    // 这里看是否创建了_buffer如果没有则创建_buffer
    LOCK(
         // 这里创建一个临时变量holder，然后放到后台线程释放
         if (_buffer.count) {
             NSMutableDictionary *holder = _buffer;
             _buffer = [NSMutableDictionary new];
             dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0), ^{
                 // Capture the dictionary to global queue,
                 // release these images in background to avoid blocking UI thread.
                 [holder class];
             });
         }
    );
    
    // 暂停计时
    _link.paused = YES;
    // 刷新时间清零
    _time = 0;
    // 手动KVO，当前帧指向第一帧
    if (_curIndex != 0) {
        [self willChangeValueForKey:@"currentAnimatedImageIndex"];
        _curIndex = 0;
        [self didChangeValueForKey:@"currentAnimatedImageIndex"];
    }
    
    // 清除各种缓存
    _curAnimatedImage = nil;
    _curFrame = nil;
    _curLoop = 0;
    _totalLoop = 0;
    _totalFrameCount = 1;
    _loopEnd = NO;
    _bufferMiss = NO;
    _incrBufferCount = 0;
}

#pragma mark - overwrite

- (void)setImage:(UIImage *)image {
    if (self.image == image) return;
    [self setImage:image withType:YYAnimatedImageTypeImage];
}

- (void)setHighlightedImage:(UIImage *)highlightedImage {
    if (self.highlightedImage == highlightedImage) return;
    [self setImage:highlightedImage withType:YYAnimatedImageTypeHighlightedImage];
}

- (void)setAnimationImages:(NSArray *)animationImages {
    if (self.animationImages == animationImages) return;
    [self setImage:animationImages withType:YYAnimatedImageTypeImages];
}

- (void)setHighlightedAnimationImages:(NSArray *)highlightedAnimationImages {
    if (self.highlightedAnimationImages == highlightedAnimationImages) return;
    [self setImage:highlightedAnimationImages withType:YYAnimatedImageTypeHighlightedImages];
}

// 重写高亮状态，决定是否初始化动画
- (void)setHighlighted:(BOOL)highlighted {
    [super setHighlighted:highlighted];
    if (_link) [self resetAnimated];
    [self imageChanged];
}

// 根据类型获取相应的image
- (id)imageForType:(YYAnimatedImageType)type {
    switch (type) {
        case YYAnimatedImageTypeNone: return nil;
        case YYAnimatedImageTypeImage: return self.image;
        case YYAnimatedImageTypeHighlightedImage: return self.highlightedImage;
        case YYAnimatedImageTypeImages: return self.animationImages;
        case YYAnimatedImageTypeHighlightedImages: return self.highlightedAnimationImages;
    }
    return nil;
}

// 获取当前的image类型
- (YYAnimatedImageType)currentImageType {
    YYAnimatedImageType curType = YYAnimatedImageTypeNone;
    if (self.highlighted) {
        if (self.highlightedAnimationImages.count) curType = YYAnimatedImageTypeHighlightedImages;
        else if (self.highlightedImage) curType = YYAnimatedImageTypeHighlightedImage;
    }
    if (curType == YYAnimatedImageTypeNone) {
        if (self.animationImages.count) curType = YYAnimatedImageTypeImages;
        else if (self.image) curType = YYAnimatedImageTypeImage;
    }
    return curType;
}

// 重新设置图片
- (void)setImage:(id)image withType:(YYAnimatedImageType)type {
    // 停止动画
    [self stopAnimating];
    // 如果开始了计时，重设动画
    if (_link) [self resetAnimated];
    _curFrame = nil;
    switch (type) {
        case YYAnimatedImageTypeNone: break;
        case YYAnimatedImageTypeImage: super.image = image; break;
        case YYAnimatedImageTypeHighlightedImage: super.highlightedImage = image; break;
        case YYAnimatedImageTypeImages: super.animationImages = image; break;
        case YYAnimatedImageTypeHighlightedImages: super.highlightedAnimationImages = image; break;
    }
    [self imageChanged];
}

// 图片改变调用的方法
- (void)imageChanged {
    // 获取当前的image
    YYAnimatedImageType newType = [self currentImageType];
    id newVisibleImage = [self imageForType:newType];
    // 标记帧数（实现帧数代理）
    NSUInteger newImageFrameCount = 0;
    // 标记是否实现了content大小(是否contentsRect代理)
    BOOL hasContentsRect = NO;
    // 如果是图片类型，并且遵循了YYAnimatedImage协议，获取相应的帧数和是否实现了contentRect代理，手动设置rect
    if ([newVisibleImage isKindOfClass:[UIImage class]] &&
        [newVisibleImage conformsToProtocol:@protocol(YYAnimatedImage)]) {
        newImageFrameCount = ((UIImage<YYAnimatedImage> *) newVisibleImage).animatedImageFrameCount;
        if (newImageFrameCount > 1) {
            hasContentsRect = [((UIImage<YYAnimatedImage> *) newVisibleImage) respondsToSelector:@selector(animatedImageContentsRectAtIndex:)];
        }
    }
    // 如果没有实现contentsRect代理 && 当前image拥有contentRect，执行放射转换
    if (!hasContentsRect && _curImageHasContentsRect) {
        // 如果本视图的layerContent没有铺满，将content铺满（不使用隐式动画）
        if (!CGRectEqualToRect(self.layer.contentsRect, CGRectMake(0, 0, 1, 1)) ) {
            [CATransaction begin];
            [CATransaction setDisableActions:YES];
            self.layer.contentsRect = CGRectMake(0, 0, 1, 1);
            [CATransaction commit];
        }
    }
    _curImageHasContentsRect = hasContentsRect;
    
    // 如果设置了contentRect改变图片的contentRect为指定的rect
    if (hasContentsRect) {
        CGRect rect = [((UIImage<YYAnimatedImage> *) newVisibleImage) animatedImageContentsRectAtIndex:0];
        [self setContentsRect:rect forImage:newVisibleImage];
    }
    
    // 如果当前图片的帧数大于1，则初始化动画设置
    if (newImageFrameCount > 1) {
        [self resetAnimated];
        // 指定当前image
        _curAnimatedImage = newVisibleImage;
        // 指定当前帧
        _curFrame = newVisibleImage;
        // 指定循环数
        _totalLoop = _curAnimatedImage.animatedImageLoopCount;
        // 指定帧数
        _totalFrameCount = _curAnimatedImage.animatedImageFrameCount;
        [self calcMaxBufferCount];
    }
    // 同步绘制
    [self setNeedsDisplay];
    [self didMoved];
}

// 动态的计算缓存大小
// dynamically adjust buffer size for current memory.
- (void)calcMaxBufferCount {
    // 根据代理计算当前帧的大小
    int64_t bytes = (int64_t)_curAnimatedImage.animatedImageBytesPerFrame;
    // 默认1024
    if (bytes == 0) bytes = 1024;
    
    int64_t total = [UIDevice currentDevice].memoryTotal;
    int64_t free = [UIDevice currentDevice].memoryFree;
    int64_t max = MIN(total * 0.2, free * 0.6);
    max = MAX(max, BUFFER_SIZE);
    if (_maxBufferSize) max = max > _maxBufferSize ? _maxBufferSize : max;
    double maxBufferCount = (double)max / (double)bytes;
    maxBufferCount = YY_CLAMP(maxBufferCount, 1, 512);
    _maxBufferCount = maxBufferCount;
}

// 对象释放的时候解除监听
- (void)dealloc {
    [_requestQueue cancelAllOperations];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationDidReceiveMemoryWarningNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationDidEnterBackgroundNotification object:nil];
    [_link invalidate];
}

// 重写是否正在动画的方法
- (BOOL)isAnimating {
    return self.currentIsPlayingAnimation;
}

// 停止动画 overwrite
- (void)stopAnimating {
    [super stopAnimating];
    [_requestQueue cancelAllOperations];
    _link.paused = YES;
    self.currentIsPlayingAnimation = NO;
}

// 开始动画 overwrite
- (void)startAnimating {
    // 根据类型决定是否执行动画
    YYAnimatedImageType type = [self currentImageType];
    if (type == YYAnimatedImageTypeImages || type == YYAnimatedImageTypeHighlightedImages) {
        NSArray *images = [self imageForType:type];
        if (images.count > 0) {
            [super startAnimating];
            self.currentIsPlayingAnimation = YES;
        }
    } else {
        if (_curAnimatedImage && _link.paused) {
            _curLoop = 0;
            _loopEnd = NO;
            _link.paused = NO;
            self.currentIsPlayingAnimation = YES;
        }
    }
}

- (void)didReceiveMemoryWarning:(NSNotification *)notification {
    [_requestQueue cancelAllOperations];
    [_requestQueue addOperationWithBlock: ^{
        _incrBufferCount = -60 - (int)(arc4random() % 120); // about 1~3 seconds to grow back..
        NSNumber *next = @((_curIndex + 1) % _totalFrameCount);
        LOCK(
             NSArray * keys = _buffer.allKeys;
             for (NSNumber * key in keys) {
                 if (![key isEqualToNumber:next]) { // keep the next frame for smoothly animation
                     [_buffer removeObjectForKey:key];
                 }
             }
        )//LOCK
    }];
}

- (void)didEnterBackground:(NSNotification *)notification {
    [_requestQueue cancelAllOperations];
    NSNumber *next = @((_curIndex + 1) % _totalFrameCount);
    LOCK(
         NSArray * keys = _buffer.allKeys;
         for (NSNumber * key in keys) {
             if (![key isEqualToNumber:next]) { // keep the next frame for smoothly animation
                 [_buffer removeObjectForKey:key];
             }
         }
     )//LOCK
}

- (void)step:(CADisplayLink *)link {
    // 获取当前image
    UIImage <YYAnimatedImage> *image = _curAnimatedImage;
    NSMutableDictionary *buffer = _buffer;
    UIImage *bufferedImage = nil;
    NSUInteger nextIndex = (_curIndex + 1) % _totalFrameCount;
    BOOL bufferIsFull = NO;
    
    if (!image) return;
    if (_loopEnd) { // view will keep in last frame
        [self stopAnimating];
        return;
    }
    
    NSTimeInterval delay = 0;
    if (!_bufferMiss) {
        // 增加一次帧时间
        _time += link.duration;
        delay = [image animatedImageDurationAtIndex:_curIndex];
        // 判断是否超过这一帧的持续时间，如果没有超过这次不处理，留到下次计时处理
        if (_time < delay) return;
        _time -= delay;
        
        // 如果一次循环完成，根据是否超过循环次数判断是否结束动画
        if (nextIndex == 0) {
            _curLoop++;
            if (_curLoop >= _totalLoop && _totalLoop != 0) {
                _loopEnd = YES;
                [self stopAnimating];
                [self.layer setNeedsDisplay]; // let system call `displayLayer:` before runloop sleep
                return; // stop at last frame
            }
        }
        // 判断下一帧的持续时间
        delay = [image animatedImageDurationAtIndex:nextIndex];
        // 如果这一帧剩余的时间大于下一帧的持续时间，则将_time设置为持续时间，不跳帧
        if (_time > delay) _time = delay; // do not jump over frame
    }
    
    LOCK(
         // 获取下一帧
         bufferedImage = buffer[@(nextIndex)];
         
         if (bufferedImage) {
             // 如果存在缓存的帧，而且缓存数量小于总帧数，从缓存中删除这一帧，🤔️
             if ((int)_incrBufferCount < _totalFrameCount) {
                 [buffer removeObjectForKey:@(nextIndex)];
             }
             // 当前帧指向下一帧
             [self willChangeValueForKey:@"currentAnimatedImageIndex"];
             _curIndex = nextIndex;
             [self didChangeValueForKey:@"currentAnimatedImageIndex"];
             
             // 当前帧指向缓存帧
             _curFrame = bufferedImage == (id)[NSNull null] ? nil : bufferedImage;
             // 如果制定了帧大小设置帧大小
             if (_curImageHasContentsRect) {
                 _curContentsRect = [image animatedImageContentsRectAtIndex:_curIndex];
                 [self setContentsRect:_curContentsRect forImage:_curFrame];
             }
             // 下一帧的索引指向下下一帧
             nextIndex = (_curIndex + 1) % _totalFrameCount;
             // 这一帧没有丢失
             _bufferMiss = NO;
             // 如果缓存数量等于最大帧数代表缓存已满
             if (buffer.count == _totalFrameCount) {
                 bufferIsFull = YES;
             }
         } else {
             // 如果没有这一帧则丢弃这一帧
             _bufferMiss = YES;
         }
    )//LOCK
    
    // 如果丢帧了，重新绘制
    if (!_bufferMiss) {
        [self.layer setNeedsDisplay]; // let system call `displayLayer:` before runloop sleep
    }
    
    // 如果缓存没有满，而且没有请求队列，创建请求operation
    if (!bufferIsFull && _requestQueue.operationCount == 0) { // if some work not finished, wait for next opportunity
        _YYAnimatedImageViewFetchOperation *operation = [_YYAnimatedImageViewFetchOperation new];
        operation.view = self;
        operation.nextIndex = nextIndex;
        operation.curImage = image;
        [_requestQueue addOperation:operation];
    }
}

// 重写display
- (void)displayLayer:(CALayer *)layer {
    if (_curFrame) {
        layer.contents = (__bridge id)_curFrame.CGImage;
    }
}

// 设置image的contentRect为指定的rect
- (void)setContentsRect:(CGRect)rect forImage:(UIImage *)image{
    CGRect layerRect = CGRectMake(0, 0, 1, 1);
    if (image) {
        CGSize imageSize = image.size;
        if (imageSize.width > 0.01 && imageSize.height > 0.01) {
            layerRect.origin.x = rect.origin.x / imageSize.width;
            layerRect.origin.y = rect.origin.y / imageSize.height;
            layerRect.size.width = rect.size.width / imageSize.width;
            layerRect.size.height = rect.size.height / imageSize.height;
            layerRect = CGRectIntersection(layerRect, CGRectMake(0, 0, 1, 1));
            if (CGRectIsNull(layerRect) || CGRectIsEmpty(layerRect)) {
                layerRect = CGRectMake(0, 0, 1, 1);
            }
        }
    }
    [CATransaction begin];
    [CATransaction setDisableActions:YES];
    self.layer.contentsRect = layerRect;
    [CATransaction commit];
}

- (void)didMoved {
    if (self.autoPlayAnimatedImage) {
        if(self.superview && self.window) {
            [self startAnimating];
        } else {
            [self stopAnimating];
        }
    }
}

// overwrite 当添加或者转移到视图的时候是否执行动画
- (void)didMoveToWindow {
    [super didMoveToWindow];
    [self didMoved];
}

- (void)didMoveToSuperview {
    [super didMoveToSuperview];
    [self didMoved];
}

// 设置当前动画图片的索引
- (void)setCurrentAnimatedImageIndex:(NSUInteger)currentAnimatedImageIndex {
    // 当前帧不存在、超出范围或者等于当前帧，不做处理
    if (!_curAnimatedImage) return;
    if (currentAnimatedImageIndex >= _curAnimatedImage.animatedImageFrameCount) return;
    if (_curIndex == currentAnimatedImageIndex) return;
    
    // UI只能在主线程更新
    dispatch_async_on_main_queue(^{
        LOCK(
             [_requestQueue cancelAllOperations];
             [_buffer removeAllObjects];
             [self willChangeValueForKey:@"currentAnimatedImageIndex"];
             _curIndex = currentAnimatedImageIndex;
             [self didChangeValueForKey:@"currentAnimatedImageIndex"];
             _curFrame = [_curAnimatedImage animatedImageFrameAtIndex:_curIndex];
             if (_curImageHasContentsRect) {
                 _curContentsRect = [_curAnimatedImage animatedImageContentsRectAtIndex:_curIndex];
             }
             _time = 0;
             _loopEnd = NO;
             _bufferMiss = NO;
             [self.layer setNeedsDisplay];
         )//LOCK
    });
}

// 当前帧的索引
- (NSUInteger)currentAnimatedImageIndex {
    return _curIndex;
}

// 设置runloop的mode
- (void)setRunloopMode:(NSString *)runloopMode {
    if ([_runloopMode isEqual:runloopMode]) return;
    if (_link) {
        if (_runloopMode) {
            [_link removeFromRunLoop:[NSRunLoop mainRunLoop] forMode:_runloopMode];
        }
        if (runloopMode.length) {
            [_link addToRunLoop:[NSRunLoop mainRunLoop] forMode:runloopMode];
        }
    }
    _runloopMode = runloopMode.copy;
}

#pragma mark - Overrice NSObject(NSKeyValueObservingCustomization)
// 手动管理currentAnimatedImageIndex的kvo
+ (BOOL)automaticallyNotifiesObserversForKey:(NSString *)key {
    if ([key isEqualToString:@"currentAnimatedImageIndex"]) {
        return NO;
    }
    return [super automaticallyNotifiesObserversForKey:key];
}

#pragma mark - NSCoding

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    _runloopMode = [aDecoder decodeObjectForKey:@"runloopMode"];
    if (_runloopMode.length == 0) _runloopMode = NSRunLoopCommonModes;
    if ([aDecoder containsValueForKey:@"autoPlayAnimatedImage"]) {
        _autoPlayAnimatedImage = [aDecoder decodeBoolForKey:@"autoPlayAnimatedImage"];
    } else {
        _autoPlayAnimatedImage = YES;
    }
    
    UIImage *image = [aDecoder decodeObjectForKey:@"YYAnimatedImage"];
    UIImage *highlightedImage = [aDecoder decodeObjectForKey:@"YYHighlightedAnimatedImage"];
    if (image) {
        self.image = image;
        [self setImage:image withType:YYAnimatedImageTypeImage];
    }
    if (highlightedImage) {
        self.highlightedImage = highlightedImage;
        [self setImage:highlightedImage withType:YYAnimatedImageTypeHighlightedImage];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [super encodeWithCoder:aCoder];
    [aCoder encodeObject:_runloopMode forKey:@"runloopMode"];
    [aCoder encodeBool:_autoPlayAnimatedImage forKey:@"autoPlayAnimatedImage"];
    
    BOOL ani, multi;
    ani = [self.image conformsToProtocol:@protocol(YYAnimatedImage)];
    multi = (ani && ((UIImage <YYAnimatedImage> *)self.image).animatedImageFrameCount > 1);
    if (multi) [aCoder encodeObject:self.image forKey:@"YYAnimatedImage"];
    
    ani = [self.highlightedImage conformsToProtocol:@protocol(YYAnimatedImage)];
    multi = (ani && ((UIImage <YYAnimatedImage> *)self.highlightedImage).animatedImageFrameCount > 1);
    if (multi) [aCoder encodeObject:self.highlightedImage forKey:@"YYHighlightedAnimatedImage"];
}

@end
