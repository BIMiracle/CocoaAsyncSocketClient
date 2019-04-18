//
//  Macro.h
//  CocoaAsyncSocketTest
//
//  Created by BIMiracle on 4/17/19.
//  Copyright © 2019 BIMiracle. All rights reserved.
//

#ifndef Macro_h
#define Macro_h


#pragma mark - 单例宏
/**
 快速创建单例文件 .h文件
 */
#define KBSingletonH \
+ (instancetype)sharedInstance;\
+ (instancetype)new         __attribute__((unavailable("use 'sharedInstance' instead")));\
+ (instancetype)alloc       __attribute__((unavailable("use 'sharedInstance' instead")));\
- (instancetype)copy        __attribute__((unavailable("use 'sharedInstance' instead")));\
- (instancetype)mutableCopy __attribute__((unavailable("use 'sharedInstance' instead")));
// .m文件
#define KBSingletonM \
static id _instance;\
+ (instancetype)sharedInstance{\
    static dispatch_once_t onceToken;\
    dispatch_once(&onceToken, ^{\
        _instance = [[super alloc] init];\
    });\
    return _instance;\
}

/**
 快速创建单例文件 (带名字 如: sharedManager) .h文件
 */
#define KBSingletonHWithName(name) \
+ (instancetype)shared##name;\
+ (instancetype)new         __attribute__((unavailable("use 'sharedInstance' instead")));\
+ (instancetype)alloc       __attribute__((unavailable("use 'sharedInstance' instead")));\
- (instancetype)copy        __attribute__((unavailable("use 'sharedInstance' instead")));\
- (instancetype)mutableCopy __attribute__((unavailable("use 'sharedInstance' instead")));

// .m文件
#define KBSingletonMWithName(name) \
static id _instance;\
+ (instancetype)shared##name{\
static dispatch_once_t onceToken;\
dispatch_once(&onceToken, ^{\
_instance = [[super alloc] init];\
});\
return _instance;\
}

#endif /* Macro_h */
