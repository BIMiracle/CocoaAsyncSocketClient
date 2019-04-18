//
//  KBWeakProxy.h
//  CocoaAsyncSocketTest
//
//  Created by BIMiracle on 4/17/19.
//  Copyright © 2019 BIMiracle. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface KBWeakProxy : NSProxy

@property (nonatomic, weak, readonly) id target;

+ (instancetype)proxyWithTarget:(id)target;

@end
