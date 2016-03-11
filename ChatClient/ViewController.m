//
//  ViewController.m
//  ChatClient
//
//  Created by Steve Baker on 3/10/16.
//  Copyright © 2016 Beepscore LLC. All rights reserved.
//

#import "ViewController.h"

@interface ViewController () {
    NSInputStream *inputStream;
    NSOutputStream *outputStream;
}

@property (strong, nonatomic) NSMutableArray *messages;

@property (weak, nonatomic) IBOutlet UIStackView *joinView;
@property (weak, nonatomic) IBOutlet UITextField *inputNameField;

- (IBAction)joinChat:(id)sender;

@property (weak, nonatomic) IBOutlet UIView *chatView;
@property (weak, nonatomic) IBOutlet UITextField *inputMessageField;
@property (weak, nonatomic) IBOutlet UITableView *tableView;

- (IBAction)sendMessage:(id)sender;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.

    self.messages = [NSMutableArray arrayWithArray:@[]];
    [self initNetworkCommunication];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)joinChat:(id)sender {
    // send message to server
    NSString *response = [NSString stringWithFormat:@"iam:%@", self.inputNameField.text];
    NSData *data = [[NSData alloc] initWithData:[response dataUsingEncoding:NSASCIIStringEncoding]];
    [outputStream write:[data bytes] maxLength:[data length]];
    [self.view bringSubviewToFront:self.chatView];
}

- (IBAction)sendMessage:(id)sender {
    NSString *response = [NSString stringWithFormat:@"msg:%@", self.inputMessageField.text];
    NSData *data = [[NSData alloc] initWithData:[response dataUsingEncoding:NSASCIIStringEncoding]];
    [outputStream write:[data bytes] maxLength:[data length]];
}

#pragma mark - UITableViewDataSource
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.messages.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {

    static NSString *cellIdentifier = @"ChatCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier
                                                            forIndexPath:indexPath];
    cell.textLabel.numberOfLines = 2;
    cell.textLabel.text = [self.messages objectAtIndex:indexPath.row];
    return cell;
}

#pragma mark - UITableViewDelegate

#pragma mark - stream methods

/**
 * Use toll free bridge between NSStream and CFStream
 * Technical Q&A QA1652
 * Using NSStreams For A TCP Connection Without NSHost
 * shows using CFBridgingRelease
 * https://developer.apple.com/library/ios/qa/qa1652/_index.html
 */
- (void)initNetworkCommunication {
    // bind CFStreams to a host and a port
    CFReadStreamRef readStream;
    CFWriteStreamRef writeStream;
    UInt32 port = 80;
    CFStreamCreatePairWithSocketToHost(NULL, (CFStringRef)@"localhost",
                                       port,
                                       &readStream, &writeStream);
    
    // Now bridged cast the CFStreams to NSStreams
    // Xcode fixit said needed to bridge, offered 2 solutions
    // use __bridge instead of CFBridgingRelease
    // Not sure which choice is more correct
    // http://stackoverflow.com/questions/18067108/when-should-you-use-bridge-vs-cfbridgingrelease-cfbridgingretain
    inputStream = (__bridge NSInputStream *)readStream;
    outputStream = (__bridge NSOutputStream *)writeStream;

    inputStream.delegate = self;
    outputStream.delegate = self;

    // use run loop to allow other code to run and ensure get stream event notifications
    [inputStream scheduleInRunLoop:[NSRunLoop currentRunLoop]
                           forMode:NSDefaultRunLoopMode];
    [outputStream scheduleInRunLoop:[NSRunLoop currentRunLoop]
                           forMode:NSDefaultRunLoopMode];

    [inputStream open];
    [outputStream open];
}

#pragma mark - NSStreamDelegate
- (void)stream:(NSStream *)stream handleEvent:(NSStreamEvent)eventCode {
    
    switch (eventCode) {
            
        case NSStreamEventOpenCompleted: {
            NSLog(@"Stream opened");
            break;
        }
        case NSStreamEventHasBytesAvailable: {
            [self handleBytesAvailableInStream:stream];
            break;
        }
        case NSStreamEventErrorOccurred: {
            NSLog(@"Can not connect to the host!");
            break;
        }
        case NSStreamEventEndEncountered: {
            break;
        }
        default: {
            NSLog(@"Unknown event");
            break;
        }
    }
}

- (void)handleBytesAvailableInStream:(NSStream *)stream {
    if (stream != inputStream) {
        return;
    }

    uint8_t buffer[1024];
    NSInteger len;

    while ([inputStream hasBytesAvailable]) {
        len = [inputStream read:buffer maxLength:sizeof(buffer)];
        if (len > 0) {
            NSString *output = [[NSString alloc] initWithBytes:buffer
                                                        length:len
                                                      encoding:NSASCIIStringEncoding];

            if (nil != output) {
                NSLog(@"server said %@", output);
                [self messageReceived:output];
            }
        }
    }
}

- (void)messageReceived:(NSString *)message {
    [self.messages addObject:message];
    [self.tableView reloadData];
}

@end
