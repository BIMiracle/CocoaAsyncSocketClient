//
//  KBSocketController.m
//  CocoaAsyncSocketClient
//
//  Created by BIMiracle on 4/18/19.
//  Copyright © 2019 BIMiracle. All rights reserved.
//

#import "KBSocketController.h"
#import "KBSocketManager.h"

@interface KBSocketController () <KBSocketDelegate>

@property (weak, nonatomic) IBOutlet UITextField *addressField;
@property (weak, nonatomic) IBOutlet UITextField *portField;
@property (weak, nonatomic) IBOutlet UITextField *sendMessageField;
@property (weak, nonatomic) IBOutlet UITextView *showMessageTextView;

@property (nonatomic, strong) KBSocketManager *socket;

@end

@implementation KBSocketController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    _socket = KBSocketManager.new;
    _socket.delegate = self;
}

- (IBAction)connect:(id)sender {
    [_socket connectServerHost:self.addressField.text port:[self.portField.text integerValue]];
}

- (IBAction)disconnect:(id)sender {
    [_socket disconnect];
}

- (IBAction)send:(id)sender {
    [_socket sendMessage:self.sendMessageField.text timeOut:-1 tag:0];
}

#pragma mark - KBSocketDelegate
- (void)didReceiveMessage:(NSString *)message{
    self.showMessageTextView.text = message;
}

- (void)dealloc{
    [_socket disconnect];
    _socket.delegate = nil;
}


@end
