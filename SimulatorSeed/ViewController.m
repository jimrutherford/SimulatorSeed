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


@interface ViewController () <UIAlertViewDelegate, UITextFieldDelegate>


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
- (IBAction)importImagesTapped:(id)sender
{
 
    ImageManager *manager = [[ImageManager alloc] init];
    
    //[manager transferImagesOfType:ImageTypeBig];
    
    //[manager transferImagesOfType:ImageTypeMedium];
    
    //[manager transferImagesOfType:ImageTypeSmall];
    
    [manager transferImagesOfType:ImageTypeHeadshots];
    
    
    /*
    NSString *path = self.pathTextField.text;
    _filePaths = [NSMutableArray array];
    _videoFilePaths = [NSMutableArray array];
    for (NSString *filePath in [[NSFileManager defaultManager] enumeratorAtPath:path].allObjects)
    {
        NSString *fileExtension = [[filePath pathExtension] lowercaseString];
        BOOL isPhoto = ([fileExtension isEqualToString:@"jpg"] || [fileExtension isEqualToString:@"png"]);
        
        if (isPhoto) {
            [_filePaths addObject:[path stringByAppendingPathComponent:filePath]];
        }
    }
    
    
    [self importNextImage];
    */
}


#pragma mark - Cleanup



- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}





@end
