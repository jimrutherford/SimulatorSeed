//
//  ImageManager.m
//  SimulatorSeed
//
//  Created by Jim Rutherford on 2014-09-24.
//  Copyright (c) 2014 Taptonics. All rights reserved.
//

#import "ImageManager.h"
#import <ImageIO/ImageIO.h>
#import <AssetsLibrary/AssetsLibrary.h>

@interface ImageManager()
{
    NSInteger numberOfPhotos;
    NSInteger numberOfPhotosProcessed;
    NSInteger numberOfErrors;
}

@property (nonatomic, strong) ALAssetsLibrary *library;

@end


@implementation ImageManager

- (id)init {
    self = [super init];
    if (!self) return nil;
    
    numberOfPhotos = 0;
    numberOfPhotosProcessed = 0;
    numberOfErrors = 0;
    
    _library = [[ALAssetsLibrary alloc] init];
    
    return self;
}


- (void) transferImagesOfType:(ImageType)type
{
    
    NSArray *images;
    NSString *albumName;
    
    // big landscape 5 port 3
    switch (type) {
        case ImageTypeBig:
            images = [self imageArrayForPrefix:@"big" landscapeCount:5 portraitCount:3];
            albumName = @"Big Images";
            break;
        case ImageTypeMedium:
            images = [self imageArrayForPrefix:@"medium" landscapeCount:4 portraitCount:4];
            albumName = @"Medium Images";
            break;
        case ImageTypeSmall:
            images = [self imageArrayForPrefix:@"small" landscapeCount:5 portraitCount:3];
            albumName = @"Small Images";
            break;
        case ImageTypeHeadshots:
            images = [self headshotImageArray];
            albumName = @"Headshots";
            break;
        default:
            break;
    }
    
    
    
    NSOperationQueue *transferQueue = [[NSOperationQueue alloc] init];
    transferQueue.name = @"Transfer Queue";
    transferQueue.maxConcurrentOperationCount = 1;
    [transferQueue waitUntilAllOperationsAreFinished];
    
    for (NSString *imageName in images)
    {
        [transferQueue addOperationWithBlock: ^ {
            [self saveImage:[UIImage imageNamed:imageName] toAlbum:albumName];
        }];
    }
    
}

                    

- (void) saveImage:(UIImage*)image toAlbum:(NSString*)album
{
    __weak ALAssetsLibrary *lib = self.library;
    
    NSLog(@"Image");
    
    [self.library addAssetsGroupAlbumWithName:album resultBlock:^(ALAssetsGroup *group) {
        
        ///checks if group previously created
        if(group == nil){
            
            //enumerate albums
            [lib enumerateGroupsWithTypes:ALAssetsGroupAlbum
                               usingBlock:^(ALAssetsGroup *assetGroup, BOOL *stop)
             {
                 //if the album is equal to our album
                 if ([[assetGroup valueForProperty:ALAssetsGroupPropertyName] isEqualToString:album]) {
                     
                     //save image
                     [lib writeImageDataToSavedPhotosAlbum:UIImageJPEGRepresentation(image, 1) metadata:nil
                                           completionBlock:^(NSURL *assetURL, NSError *error) {
                                               
                                               if (error) NSLog(@"Error:  %@", error);
                                               
                                               //then get the image asseturl
                                               [lib assetForURL:assetURL resultBlock:^(ALAsset *asset) {
                                                   //put it into our album
                                                   [assetGroup addAsset:asset];
                                                   
                                               } failureBlock:^(NSError *error) {
                                                   NSLog(@"Error:  %@", error);
                                               }];
                                           }];
                     
                 }
             }failureBlock:^(NSError *error){
                 NSLog(@"Error:  %@", error);
             }];
            
        }else{
            // save image directly to library
            [lib writeImageDataToSavedPhotosAlbum:UIImageJPEGRepresentation(image, 1) metadata:nil
                                  completionBlock:^(NSURL *assetURL, NSError *error) {
                                      
                                      [lib assetForURL:assetURL
                                           resultBlock:^(ALAsset *asset) {
                                               
                                               [group addAsset:asset];
                                               
                                           } failureBlock:^(NSError *error) {
                                               NSLog(@"Error:  %@", error);
                                           }];
                                  }];
        }
        
    } failureBlock:^(NSError *error) {
        
    }];
}

#pragma mark - Utility

-(NSArray*) imageArrayForPrefix:(NSString*)prefix landscapeCount:(NSInteger)landscapeCount portraitCount:(NSInteger)portraitCount
{
    NSMutableArray *images = [NSMutableArray array];
    
    for (NSInteger l = 1; l < landscapeCount + 1; l++)
    {
        NSString *imageName = [NSString stringWithFormat:@"%@-l-0%li.jpg", prefix, l];
        [images addObject:imageName];
    }
    
    for (NSInteger p = 1; p < portraitCount + 1; p++)
    {
        NSString *imageName = [NSString stringWithFormat:@"%@-p-0%li.jpg", prefix, p];
        [images addObject:imageName];
    }
    
    return [images copy];
}

- (NSArray*) headshotImageArray
{
    NSMutableArray *images = [NSMutableArray array];
    
    for (NSInteger m = 1; m < 7; m++)
    {
        NSString *imageName = [NSString stringWithFormat:@"%man-0%li.jpg", m];
        [images addObject:imageName];
    }
    
    for (NSInteger w = 1; w < 7; w++)
    {
        NSString *imageName = [NSString stringWithFormat:@"woman-0%li.jpg", w];
        [images addObject:imageName];
    }
    
    return [images copy];
}



/*
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
*/

@end
