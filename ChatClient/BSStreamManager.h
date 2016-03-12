//
//  BSStreamManager.h
//  ChatClient
//
//  Created by Steve Baker on 3/11/16.
//  Copyright © 2016 Beepscore LLC. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface BSStreamManager : NSObject <NSStreamDelegate>

extern NSString *messageReceivedNotification;

/**
 * key used in messageReceivedNotification userInfo dictionary
 */
extern NSString *messageKey;

- (void)initNetworkCommunication;

- (void)joinChat:(NSString *)userName;

- (void)sendMessage:(NSString *)message;

@end
