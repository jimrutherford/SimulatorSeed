//
//  ViewController.m
//  SimulatorSeed
//
//  Created by Jim Rutherford on 2014-09-17.
//  Copyright (c) 2014 Taptonics. All rights reserved.
//

#import "ViewController.h"
#import <AddressBook/AddressBook.h>
#import "SVProgressHUD.h"
#import <ImageIO/ImageIO.h>
#import <AssetsLibrary/AssetsLibrary.h>


@interface ViewController () <UIAlertViewDelegate, UITextFieldDelegate>

{
    NSUInteger numberOfPhotos;
    NSUInteger numberOfPhotosProcessed;
    NSUInteger numberOfErrors;
    
    NSUInteger numberOfVideos;
    NSUInteger numberOfVideosProcessed;
    NSUInteger numberOfVideoErrors;
}

@property (weak, nonatomic) IBOutlet UITextField *pathTextField;

@property (nonatomic, strong) NSMutableArray *filePaths;
@property (nonatomic, strong) NSMutableArray *videoFilePaths;
@property (nonatomic, strong) ALAssetsLibrary *library;

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

    numberOfPhotos = 0;
    numberOfPhotosProcessed = 0;
    numberOfErrors = 0;
    
    numberOfVideos = 0;
    numberOfVideosProcessed = 0;
    numberOfVideoErrors = 0;
    _library = [[ALAssetsLibrary alloc] init];
    
}



#pragma mark - Contacts



- (IBAction)addContactsTapped:(id)sender
{
    [SVProgressHUD showWithStatus:@"Adding contacts"];
    
    [self performSelector:@selector(addContacts) withObject:nil afterDelay:0.1];
}


-(void)addContacts
{
    ABAddressBookRef addressBook = ABAddressBookCreateWithOptions(NULL, NULL);
    __block BOOL accessGranted = NO;
    
    if (ABAddressBookRequestAccessWithCompletion != NULL) { // we're on iOS 6
        dispatch_semaphore_t sema = dispatch_semaphore_create(0);
        
        ABAddressBookRequestAccessWithCompletion(addressBook, ^(bool granted, CFErrorRef error) {
            accessGranted = granted;
            dispatch_semaphore_signal(sema);
        });
        
        dispatch_semaphore_wait(sema, DISPATCH_TIME_FOREVER);

    }
    else { // we're on iOS 5 or older
        accessGranted = YES;
    }
    
    if(accessGranted)
    {
        NSString *seedDataPath = self.pathTextField.text;

        for (NSString *file in [[NSFileManager defaultManager] enumeratorAtPath:seedDataPath].allObjects)
        {
            NSString *fileExtension = [[file pathExtension] lowercaseString];
            BOOL isVcard = ([fileExtension isEqualToString:@"vcf"]);
            
            if (isVcard) {
                
                NSString *fullPath = [seedDataPath stringByAppendingPathComponent:file];
                
                NSData *myData = [NSData dataWithContentsOfFile:fullPath];
                CFDataRef vCardData = (__bridge CFDataRef)myData;
                
                ABAddressBookRef book = ABAddressBookCreateWithOptions(NULL, NULL);
                ABRecordRef defaultSource = ABAddressBookCopyDefaultSource(book);
                CFArrayRef vCardPeople = ABPersonCreatePeopleInSourceWithVCardRepresentation(defaultSource, vCardData);
                for (CFIndex index = 0; index < CFArrayGetCount(vCardPeople); index++)
                {
                    ABRecordRef person = CFArrayGetValueAtIndex(vCardPeople, index);
                    NSString *strRandomname = [NSString stringWithFormat:@"%d.jpg",(arc4random() % 10) + 1];
                    ABPersonSetImageData(person, (__bridge CFDataRef) (UIImageJPEGRepresentation([UIImage imageNamed:strRandomname], 1.0f)), nil);
                    ABAddressBookAddRecord(book, person, NULL);
                    ABAddressBookSave(book, nil);
                    CFRelease(person);
                }
                
                CFRelease(vCardPeople);
                CFRelease(defaultSource);

            }
        }
    }
    
    [SVProgressHUD dismissWithSuccess:@"Success." afterDelay:3];
}


- (IBAction)installCharlesTapped:(id)sender {
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString: @"http://charlesproxy.com/charles.crt"]];
}


#pragma mark - Actions
- (IBAction)importImagesTapped:(id)sender
{
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
    
    numberOfPhotos = _filePaths.count;
    numberOfPhotosProcessed = 0;
    numberOfErrors = 0;
    
    [self importNextImage];
}

- (IBAction)importVideosTapped:(id)sender
{
    NSString *path = self.pathTextField.text;
    _videoFilePaths = [NSMutableArray array];
    for (NSString *filePath in [[NSFileManager defaultManager] enumeratorAtPath:path].allObjects)
    {
        NSString *fileExtension = [[filePath pathExtension] lowercaseString];
        BOOL isVideo = ([fileExtension isEqualToString:@"mov"] || [fileExtension isEqualToString:@"mp4"]);
        if (isVideo) {
            [_videoFilePaths addObject:[path stringByAppendingPathComponent:filePath]];
        }
    }
    
    numberOfVideos = _videoFilePaths.count;
    numberOfVideosProcessed = 0;
    numberOfVideoErrors = 0;
    
    [self importNextVideo];
}


/*
- (void) groupThing
{
    __weak ALAssetsLibrary *lib = self.library;
    
    [self.library addAssetsGroupAlbumWithName:@"My Photo Album" resultBlock:^(ALAssetsGroup *group) {
        
        ///checks if group previously created
        if(group == nil){
            
            //enumerate albums
            [lib enumerateGroupsWithTypes:ALAssetsGroupAlbum
                               usingBlock:^(ALAssetsGroup *g, BOOL *stop)
             {
                 //if the album is equal to our album
                 if ([[g valueForProperty:ALAssetsGroupPropertyName] isEqualToString:@"My Photo Album"]) {
                     
                     //save image
                     [lib writeImageDataToSavedPhotosAlbum:UIImagePNGRepresentation(image) metadata:nil
                                           completionBlock:^(NSURL *assetURL, NSError *error) {
                                               
                                               //then get the image asseturl
                                               [lib assetForURL:assetURL
                                                    resultBlock:^(ALAsset *asset) {
                                                        //put it into our album
                                                        [g addAsset:asset];
                                                    } failureBlock:^(NSError *error) {
                                                        
                                                    }];
                                           }];
                     
                 }
             }failureBlock:^(NSError *error){
                 
             }];
            
        }else{
            // save image directly to library
            [lib writeImageDataToSavedPhotosAlbum:UIImagePNGRepresentation(image) metadata:nil
                                  completionBlock:^(NSURL *assetURL, NSError *error) {
                                      
                                      [lib assetForURL:assetURL
                                           resultBlock:^(ALAsset *asset) {
                                               
                                               [group addAsset:asset];
                                               
                                           } failureBlock:^(NSError *error) {
                                               
                                           }];
                                  }];
        }
        
    } failureBlock:^(NSError *error) {
        
    }];
}
*/

- (void)saveImageWithMetadata:(NSString *)filePath
{
    UIImage *image = [UIImage imageWithContentsOfFile:filePath];
    
    NSURL *imageFileURL = [NSURL fileURLWithPath:filePath];
    CGImageSourceRef source = CGImageSourceCreateWithURL((CFURLRef)imageFileURL, NULL);
    NSDictionary *metadata = (NSDictionary *) CFBridgingRelease(CGImageSourceCopyPropertiesAtIndex(source, 0, NULL));
    
    [self.library writeImageToSavedPhotosAlbum:[image CGImage]
                                      metadata:metadata
                               completionBlock:^(NSURL *newURL, NSError *error) {
                                   [self image:image didFinishSavingWithError:error contextInfo:nil];
                               }];
}

- (void)importNextImage
{
    [self saveImageWithMetadata:[self.filePaths lastObject]];
    [self.filePaths removeLastObject];
}

- (void)importNextVideo
{
    if (UIVideoAtPathIsCompatibleWithSavedPhotosAlbum([self.videoFilePaths lastObject])) {
        UISaveVideoAtPathToSavedPhotosAlbum([self.videoFilePaths lastObject], self, @selector(video:didFinishSavingWithError:contextInfo:), nil);
    }
    
    [self.videoFilePaths removeLastObject];
}

- (void)image:(UIImage *)image didFinishSavingWithError:(NSError *)error contextInfo:(void *)contextInfo
{
    numberOfPhotosProcessed++;
    
    if (error)
    {
        numberOfErrors++;
        
        [SVProgressHUD dismissWithError:error.localizedDescription];
        return;
    }
    
    if (numberOfPhotosProcessed == numberOfPhotos) {
        if (numberOfErrors == 0)
            [SVProgressHUD dismissWithSuccess:@"Success." afterDelay:3];
        else
            [SVProgressHUD dismissWithError:[NSString stringWithFormat:@"%lu of %lu have failed.", (unsigned long)numberOfErrors, (unsigned long)numberOfPhotos] afterDelay:3];
    }
    else
        [SVProgressHUD showWithStatus:[NSString stringWithFormat:@"%lu of %lu", (unsigned long)numberOfPhotosProcessed, (unsigned long)numberOfPhotos]];
    
    // Continue importing
    if (numberOfPhotosProcessed < numberOfPhotos)
        [self importNextImage];
}

- (void)video:(NSString *)videoPath didFinishSavingWithError:(NSError *)error contextInfo:(void *)contextInfo {
    numberOfVideosProcessed++;
    
    if (error)
    {
        numberOfVideoErrors++;
        
        [SVProgressHUD dismissWithError:error.localizedDescription];
        return;
    }
    
    if (numberOfVideosProcessed == numberOfVideos) {
        if (numberOfVideoErrors == 0)
            [SVProgressHUD dismissWithSuccess:@"Success." afterDelay:3];
        else
            [SVProgressHUD dismissWithError:[NSString stringWithFormat:@"%lu of %lu have failed.", numberOfVideoErrors, numberOfVideos] afterDelay:3];
    }
    else
        [SVProgressHUD showWithStatus:[NSString stringWithFormat:@"%lu of %lu", numberOfVideosProcessed, numberOfVideos]];
    
    // Continue importing
    if (numberOfVideosProcessed < numberOfVideos)
        [self importNextVideo];
}






#pragma mark - Cleanup



- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}





@end
