//
//  ViewController.m
//  SimulatorSeed
//
//  Created by Jim Rutherford on 2014-09-17.
//  Copyright (c) 2014 Taptonics. All rights reserved.
//

#import "ViewController.h"
#import "SVProgressHUD.h"
#import "ContactsManager.h"
#import "ImageManager.h"


@interface ViewController () <UIAlertViewDelegate, UITextFieldDelegate, ImageManagerDelegate>


@property (weak, nonatomic) IBOutlet UITextField *pathTextField;


@end


@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    NSString *activeHomeDirectory = [@"~" stringByExpandingTildeInPath];
    NSArray *activeHomeDirectoryPathComponents = activeHomeDirectory.pathComponents;
    NSString *homeDirectory = @"";
    
    if (activeHomeDirectoryPathComponents.count > 2) {
        homeDirectory = [homeDirectory stringByAppendingPathComponent:[activeHomeDirectoryPathComponents objectAtIndex:0]];
        homeDirectory = [homeDirectory stringByAppendingPathComponent:[activeHomeDirectoryPathComponents objectAtIndex:1]];
        homeDirectory = [homeDirectory stringByAppendingPathComponent:[activeHomeDirectoryPathComponents objectAtIndex:2]];
    }
    
    homeDirectory = [homeDirectory stringByAppendingPathComponent:@"SimulatorSeedData"];
    _pathTextField.text = homeDirectory;
    
    _pathTextField.delegate = self;
}


#pragma mark - Contacts

- (IBAction)addContactsTapped:(id)sender
{
    [SVProgressHUD showWithStatus:@"Adding contacts"];
    
    ContactsManager *manager = [[ContactsManager alloc] init];
    NSString *seedDataPath = self.pathTextField.text;
    
    [manager importContacts:seedDataPath];
}


- (IBAction)installCharlesTapped:(id)sender {
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString: @"http://charlesproxy.com/charles.crt"]];
}


#pragma mark - Actions
- (IBAction)importStockImagesTapped:(id)sender
{
    ImageManager *manager = [[ImageManager alloc] init];
    manager.delegate = self;
    [manager transferStockImages];
}

- (IBAction)importCustomImagesTapped:(id)sender
{
    ImageManager *manager = [[ImageManager alloc] init];
    manager.delegate = self;
    [manager transferCustomImagesFromPath:_pathTextField.text];
}

#pragma mark - Image Manager Delegate Methods

- (void) transferProgessForCurrent:(NSInteger)current withTotal:(NSInteger)total
{
    [SVProgressHUD showWithStatus:[NSString stringWithFormat:@"%li of %li", (long)current, (long)total]];
}

- (void) didFinishTransferingImages
{
    [SVProgressHUD dismissWithSuccess:@"Success!" afterDelay:2.0f];
}




#pragma mark - Cleanup



- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}





@end
