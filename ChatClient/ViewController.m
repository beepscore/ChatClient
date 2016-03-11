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

@property (weak, nonatomic) IBOutlet UIStackView *joinView;

@property (weak, nonatomic) IBOutlet UITextField *inputNameField;

- (IBAction)joinChat:(id)sender;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.

    [self initNetworkCommunication];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)joinChat:(id)sender {
}

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

@end
