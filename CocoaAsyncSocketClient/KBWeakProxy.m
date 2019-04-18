//
//  KBWeakProxy.m
//  CocoaAsyncSocketTest
//
//  Created by BIMiracle on 4/17/19.
//  Copyright © 2019 BIMiracle. All rights reserved.
//

#import "KBWeakProxy.h"

@implementation KBWeakProxy

+ (instancetype)proxyWithTarget:(id)target {
    return [[KBWeakProxy alloc] initWithTarget:target];
}

- (instancetype)initWithTarget:(id)target {
    _target = target;
    return self;
}

- (id)forwardingTargetForSelector:(SEL)aSelector {
    if ([_target respondsToSelector:aSelector]) {
        return _target;
    }
    return self;
}

- (NSMethodSignature *)methodSignatureForSelector:(SEL)sel{
    return [NSMethodSignature signatureWithObjCTypes:"v"];
}

- (void)forwardInvocation:(NSInvocation *)invocation{
    // 防止线上找不到方法而崩溃
    NSAssert(NO, @"Method Not Found");
    NSLog(@"Method Not Found");
}

@end
