//
//  ViewController.m
//  ChatClient
//
//  Created by Steve Baker on 3/10/16.
//  Copyright © 2016 Beepscore LLC. All rights reserved.
//

#import "ViewController.h"
#import "BSStreamManager.h"

@interface ViewController ()

@property (strong, nonatomic) BSStreamManager *streamManager;

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

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(handleMessageReceivedNotification:)
                                                 name:messageReceivedNotification
                                               object:nil];

    self.streamManager = [[BSStreamManager alloc] init];
    [self.streamManager initNetworkCommunication];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)dealloc {
    // is this unnecessary in iOS 9?
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:messageReceivedNotification
                                                  object:nil];
}

#pragma mark - send messages

- (IBAction)joinChat:(id)sender {
    [self.streamManager joinChat:self.inputNameField.text];
    [self.view bringSubviewToFront:self.chatView];
}

- (IBAction)sendMessage:(id)sender {
    [self.streamManager sendMessage:self.inputMessageField.text];
    self.inputMessageField.text = @"";
}

#pragma mark - receive messages
- (void)handleMessageReceivedNotification:(NSNotification *)notification {
    NSString *message = notification.userInfo[messageKey];
    [self.messages addObject:message];
    [self.tableView reloadData];
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
    cell.textLabel.numberOfLines = 0;
    cell.textLabel.text = [self.messages objectAtIndex:indexPath.row];
    return cell;
}

#pragma mark - UITableViewDelegate

@end
