//
//  BSStreamManager.m
//  ChatClient
//
//  Created by Steve Baker on 3/11/16.
//  Copyright © 2016 Beepscore LLC. All rights reserved.
//

#import "BSStreamManager.h"

@interface BSStreamManager () {
    NSInputStream *inputStream;
    NSOutputStream *outputStream;
}

// assumes server is running on same machine as simulator, i.e. both are running on the same Mac.
// may be set to @"localhost"
extern NSString *hostForSimulator;
// assumes server is running on same wifi network as simulator or device
// may be of the form of an ip address e.g. @"10.0.0.16"
extern NSString *hostForSimulatorOrDeviceOnSameWifi;

@end

@implementation BSStreamManager

NSString *hostForSimulator = @"localhost";
NSString *hostForSimulatorOrDeviceOnSameWifi = @"10.0.0.16";
NSString *host;

NSString *messageReceivedNotification = @"messageReceivedNotification";
NSString *messageKey = @"message";

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
    host = hostForSimulatorOrDeviceOnSameWifi;
    CFStreamCreatePairWithSocketToHost(NULL, (__bridge CFStringRef)host,
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

#pragma mark - send messages
- (void)joinChat:(NSString *)userName {
    NSString *joinString = [NSString stringWithFormat:@"iam:%@", userName];
    NSData *data = [[NSData alloc] initWithData:[joinString dataUsingEncoding:NSASCIIStringEncoding]];
    [outputStream write:[data bytes] maxLength:[data length]];
}

- (void)sendMessage:(NSString *)message {
    NSString *messageString = [NSString stringWithFormat:@"msg:%@", message];
    NSData *data = [[NSData alloc] initWithData:[messageString dataUsingEncoding:NSASCIIStringEncoding]];
    [outputStream write:[data bytes] maxLength:[data length]];
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
            [self handleEventEndInStream:stream];
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
    [[NSNotificationCenter defaultCenter] postNotificationName:messageReceivedNotification
                                                        object:self
                                                      userInfo:@{messageKey:message}];
}

- (void)handleEventEndInStream:(NSStream *)stream {
    [stream close];
    [stream removeFromRunLoop:[NSRunLoop currentRunLoop]
                      forMode:NSDefaultRunLoopMode];
}

@end
