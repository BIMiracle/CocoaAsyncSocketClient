//
//  KBSocketManager.m
//  CocoaAsyncSocketClient
//
//  Created by BIMiracle on 4/18/19.
//  Copyright © 2019 BIMiracle. All rights reserved.
//

#import "KBSocketManager.h"
#import "KBWeakProxy.h"
#import <GCDAsyncSocket.h>
#import "RealReachability.h"

#define TCP_VersionCode @"1"        //当前TCP版本(服务器协商,便于服务器版本控制)
#define TCP_beatBody    @"beatID"   //心跳标识
#define TCP_AutoConnectCount    3   //自动重连次数
#define TCP_BeatDuration        10  //心跳频率
#define TCP_MaxBeatMissCount    3   //最大心跳丢失数
#define TCP_PingUrl     @"www.baidu.com"

@interface KBSocketManager () <GCDAsyncSocketDelegate>

@property (nonatomic, strong) GCDAsyncSocket *socket;
/** 发送心跳次数 */
@property (nonatomic, assign) NSInteger senBeatCount;
/** host保存 */
@property (nonatomic, strong) NSString *host;
/** 端口保存 */
@property (nonatomic, assign) uint16_t port;
/** 重连时间 */
@property (nonatomic, assign) NSTimeInterval reConnectTime;
/** 心跳定时器 */
@property (nonatomic, strong) NSTimer *heartBeat;

@end

@implementation KBSocketManager

#pragma mark - 初始化
- (instancetype)init{
    if (self = [super init]) {
        NSAssert(TCP_AutoConnectCount > 1, @"重连次数不能小于1");
        _socket = [[GCDAsyncSocket alloc] initWithDelegate:self delegateQueue:dispatch_get_main_queue()];
        //设置默认关闭读取
        [_socket setAutoDisconnectOnClosedReadStream:NO];
        //默认状态未连接
        _connectStatus = KBSocketConnectStatus_UnConnected;
    }
    return self;
}

#pragma mark - 连接服务器端口
- (void)connectServerHost:(NSString *)host port:(uint16_t)port{
    NSAssert(_socket, @"socket未初始化");
    if (_connectStatus == KBSocketConnectStatus_Connected) {
        [self disconnect];
    }
    NSError *error = nil;
    _host = host;
    _port = port;
    [_socket connectToHost:host onPort:port error:&error];
    if (error) {
        NSLog(@"----------------连接服务器失败----------------");
    }else{
        NSLog(@"----------------连接服务器成功----------------");
    }
}

#pragma mark - 连接中断
- (void)disconnect{
    //更新soceket连接状态
    _connectStatus = KBSocketConnectStatus_DisConnected;
    //断开连接
    [_socket disconnect];
    //关闭心跳定时器
    [self destoryHeartBeat];
    //未接收到服务器心跳次数,置为初始化
    _senBeatCount = 0;
    //自动重连时间 , 置为初始化
    _reConnectTime = 0;
}

#pragma mark - GCDAsyncSocketDelegate
#pragma mark 接收到消息
- (void)socket:(GCDAsyncSocket *)sock didReadData:(NSData *)data withTag:(long)tag{
    //转为明文消息
    NSString *text = [[NSString alloc]initWithData:data encoding:NSUTF8StringEncoding];
    
    //接收到服务器的心跳
    if ([text isEqualToString:TCP_beatBody]) {
        //接收到服务器心跳次数置为0
        _senBeatCount = 0;
        NSLog(@"------------------接收到服务器心跳-------------------");
    }else{
        //消息分发,将消息发送至每个注册的Object中 , 进行相应的布局等操作
        if ([self.delegate respondsToSelector:@selector(didReceiveMessage:)]) {
            [self.delegate didReceiveMessage:text];
        }
    }
    [_socket readDataWithTimeout:-1 tag:0];
}

#pragma mark TCP连接成功建立 ,配置SSL 相当于https 保证安全性 , 这里是单向验证服务器地址 , 仅仅需要验证服务器的IP即可
- (void)socket:(GCDAsyncSocket *)sock didConnectToHost:(NSString *)host port:(uint16_t)port{
//    // 配置 SSL/TLS 设置信息
//    NSMutableDictionary *settings = [NSMutableDictionary dictionaryWithCapacity:3];
//    //允许自签名证书手动验证
//    [settings setObject:@YES forKey:GCDAsyncSocketManuallyEvaluateTrust];
//    //GCDAsyncSocketSSLPeerName
//    [settings setObject:@"此处填服务器IP地址" forKey:GCDAsyncSocketSSLPeerName];
//    [_socket startTLS:settings];
    
    [_socket readDataWithTimeout:-1 tag:0];
    // 已经连接
    _connectStatus = KBSocketConnectStatus_Connected;
    // 定时发送心跳开启
    [self initHeartBeat];
    // 重新建立连接后 , 重置自动重连时间
    _reConnectTime = 0;
}

//#pragma mark TCP成功获取安全验证
//- (void)socketDidSecure:(GCDAsyncSocket *)sock{
//    //登录服务器
//    ChatModel *loginModel  = [[ChatModel alloc]init];
//    //此版本号需和后台协商 , 便于后台进行版本控制
//    loginModel.versionCode = TCP_VersionCode;
//    //当前用户ID
//    loginModel.fromUserID  = [Account account].myUserID;
//    //设备类型
//    loginModel.deviceType  = DeviceType;
//    //发送登录验证
//    [self sendMessage:loginModel timeOut:-1 tag:0];
//}

#pragma mark TCP已经断开连接
- (void)socketDidDisconnect:(GCDAsyncSocket *)sock withError:(NSError *)err{
    if (_connectStatus != KBSocketConnectStatus_DisConnected) {
        [self reConnect];
    }
}

#pragma mark 发送消息超时
- (NSTimeInterval)socket:(GCDAsyncSocket *)sock shouldTimeoutWriteWithTag:(long)tag elapsed:(NSTimeInterval)elapsed bytesDone:(NSUInteger)length{
    //发送超时消息分发
    if ([self.delegate respondsToSelector:@selector(sendMessageTimeOutWithTag:)]) {
        [self.delegate sendMessageTimeOutWithTag:tag];
    }
    return -1;
}

#pragma mark - 网络监听
- (void)networkChanged:(NSNotification *)notification {
    //网络中断 , 断开连接
    if ([GLobalRealReachability currentReachabilityStatus] == RealStatusNotReachable||_connectStatus == KBSocketConnectStatus_UnConnected) {
        [self disconnect];//断开连接,默认还会重连3次 ,还未连接自动断开
    }
    
    //如果网络监测有网 , 但是socket处于未连接状态 , 进行重连
    if ([GLobalRealReachability currentReachabilityStatus] == RealStatusViaWWAN || [GLobalRealReachability currentReachabilityStatus] == RealStatusViaWiFi) {
        if (_connectStatus == KBSocketConnectStatus_UnConnected) {
            [self reConnect]; //连接服务器
        }
    }
}

#pragma mark - 重连机制
- (void)reConnect{
    [self disconnect];
    
    NSLog(@"自动重连中");
    
    //超过一分钟就不再重连 所以只会重连5次 2^5 = 64
    if (_reConnectTime > pow(2,TCP_AutoConnectCount - 1)) {
        return;
    }
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(_reConnectTime * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self connectServerHost:self.host port:self.port];
    });
    
    //重连时间2的指数级增长
    if (_reConnectTime == 0) {
        _reConnectTime = 2;
    }else{
        _reConnectTime *= 2;
    }
}


#pragma mark - 发送消息
- (void)sendMessage:(NSString *)message timeOut:(NSUInteger)timeOut tag:(long)tag{
    NSData  *messageData  = [message dataUsingEncoding:NSUTF8StringEncoding];
    //写入数据
    [_socket writeData:messageData withTimeout:timeOut tag:tag];
}

#pragma mark - 初始化心跳
- (void)initHeartBeat{
    [self destoryHeartBeat];
    
    _heartBeat = [NSTimer timerWithTimeInterval:TCP_BeatDuration target:[KBWeakProxy proxyWithTarget:self] selector:@selector(sendHeartBeat) userInfo:nil repeats:YES];
    [[NSRunLoop mainRunLoop] addTimer:_heartBeat forMode:NSRunLoopCommonModes];
}

#pragma mark - 发送心跳
- (void)sendHeartBeat{
    self.senBeatCount ++ ;
    if (self.senBeatCount>TCP_MaxBeatMissCount) {
        //更新连接状态
        self.connectStatus = KBSocketConnectStatus_UnConnected;
        [self reConnect];
    }else{
        //发送心跳
        NSData *beatData = [TCP_beatBody dataUsingEncoding:NSUTF8StringEncoding];
        [_socket writeData:beatData withTimeout:-1 tag:0];
        NSLog(@"------------------发送了心跳------------------");
    }
}

#pragma mark - 取消心跳
- (void)destoryHeartBeat{
    if (_heartBeat) {
        [_heartBeat invalidate];
        _heartBeat = nil;
    }
}


@end
