//
//  ViewController.m
//  ChatClient
//
//  Created by Steve Baker on 3/10/16.
//  Copyright © 2016 Beepscore LLC. All rights reserved.
//

#import "ViewController.h"

@interface ViewController ()

@property (weak, nonatomic) IBOutlet UIStackView *joinView;

@property (weak, nonatomic) IBOutlet UITextField *inputNameField;

- (IBAction)joinChat:(id)sender;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)joinChat:(id)sender {
}
@end
