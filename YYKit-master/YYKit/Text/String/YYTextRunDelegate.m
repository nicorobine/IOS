//
//  YYTextRunDelegate.m
//  YYKit <https://github.com/ibireme/YYKit>
//
//  Created by ibireme on 14/10/14.
//  Copyright (c) 2015 ibireme.
//
//  This source code is licensed under the MIT-style license found in the
//  LICENSE file in the root directory of this source tree.
//

#import "YYTextRunDelegate.h"

// 释放对象的回调
static void DeallocCallback(void *ref) {
    YYTextRunDelegate *self = (__bridge_transfer YYTextRunDelegate *)(ref);
    self = nil; // release
}

// 获取字形的上行高度
static CGFloat GetAscentCallback(void *ref) {
    YYTextRunDelegate *self = (__bridge YYTextRunDelegate *)(ref);
    return self.ascent;
}

// 获取字形的下行高度
static CGFloat GetDecentCallback(void *ref) {
    YYTextRunDelegate *self = (__bridge YYTextRunDelegate *)(ref);
    return self.descent;
}

// 获取字形的宽度
static CGFloat GetWidthCallback(void *ref) {
    YYTextRunDelegate *self = (__bridge YYTextRunDelegate *)(ref);
    return self.width;
}

@implementation YYTextRunDelegate

// 获取CTRunDelegate
- (CTRunDelegateRef)CTRunDelegate CF_RETURNS_RETAINED {
    // 设置CallBacks结构体
    CTRunDelegateCallbacks callbacks;
    callbacks.version = kCTRunDelegateCurrentVersion;
    callbacks.dealloc = DeallocCallback;
    callbacks.getAscent = GetAscentCallback;
    callbacks.getDescent = GetDecentCallback;
    callbacks.getWidth = GetWidthCallback;
    // 这只代理为自己
    return CTRunDelegateCreate(&callbacks, (__bridge_retained void *)(self.copy));
}


// 实现NSCoding协议
- (void)encodeWithCoder:(NSCoder *)aCoder {
    [aCoder encodeObject:@(_ascent) forKey:@"ascent"];
    [aCoder encodeObject:@(_descent) forKey:@"descent"];
    [aCoder encodeObject:@(_width) forKey:@"width"];
    [aCoder encodeObject:_userInfo forKey:@"userInfo"];
}

// 使用coder初始化
- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super init];
    _ascent = ((NSNumber *)[aDecoder decodeObjectForKey:@"ascent"]).floatValue;
    _descent = ((NSNumber *)[aDecoder decodeObjectForKey:@"descent"]).floatValue;
    _width = ((NSNumber *)[aDecoder decodeObjectForKey:@"width"]).floatValue;
    _userInfo = [aDecoder decodeObjectForKey:@"userInfo"];
    return self;
}

// 实现NSCopying协议
- (id)copyWithZone:(NSZone *)zone {
    typeof(self) one = [self.class new];
    one.ascent = self.ascent;
    one.descent = self.descent;
    one.width = self.width;
    one.userInfo = self.userInfo;
    return one;
}

@end
