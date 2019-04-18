//
//  KBSocketManager.h
//  CocoaAsyncSocketClient
//
//  Created by BIMiracle on 4/18/19.
//  Copyright © 2019 BIMiracle. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSInteger,KBSocketConnectStatus) {
    KBSocketConnectStatus_UnConnected,   //未连接状态
    KBSocketConnectStatus_Connected,     //连接状态
    KBSocketConnectStatus_DisConnected,   //手动断开状态
    KBSocketConnectStatus_Unknow,        //未知
};

@protocol KBSocketDelegate <NSObject>
@required
//接收消息代理
- (void)didReceiveMessage:(NSString *)message;
@optional
//发送消息超时代理
- (void)sendMessageTimeOutWithTag:(long)tag;
@end


@interface KBSocketManager : NSObject

//socket连接状态
@property (nonatomic, assign) KBSocketConnectStatus connectStatus;

@property (nonatomic, weak) id<KBSocketDelegate> delegate;

//连接服务器端口
- (void)connectServerHost:(NSString *)host port:(uint16_t)port;
//主动断开连接
- (void)disconnect;
//发送消息
- (void)sendMessage:(NSString *)message timeOut:(NSUInteger)timeOut tag:(long)tag;

@end
