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
    
    _library = [[ALAssetsLibrary alloc] init];
    
    return self;
}


- (void) transferCustomImagesFromPath:(NSString*)path
{
    NSMutableArray *images = [NSMutableArray array];
    
    path = [path stringByAppendingPathComponent:@"images"];
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSDirectoryEnumerator *dirEnumerator = [fileManager enumeratorAtURL:[NSURL URLWithString:path]
                                    includingPropertiesForKeys:@[NSURLNameKey, NSURLIsDirectoryKey]
                                                       options:NSDirectoryEnumerationSkipsHiddenFiles
                                                  errorHandler:nil];
    
    for (NSURL *url in dirEnumerator) {
        NSNumber *isDirectory;
        [url getResourceValue:&isDirectory forKey:NSURLIsDirectoryKey error:NULL];
        if ([isDirectory boolValue]) {
            // This is a file - remove it
            NSLog(@"Folder > %@", url.path);
            NSLog(@"Folder name > %@", [url.pathComponents lastObject]);
            
            [images addObjectsFromArray:[self imageArrayForPath:url.path albumName:[url.pathComponents lastObject]]];
        }
    }

    [self processImageQueue:[images copy]];

}

- (void) transferStockImages
{
    
    NSMutableArray *images = [NSMutableArray array];
    
    [images addObjectsFromArray: [self imageArrayForPrefix:@"big" albumName:@"Big Images" landscapeCount:5 portraitCount:3]];
    [images addObjectsFromArray: [self imageArrayForPrefix:@"medium" albumName:@"Medium Images" landscapeCount:4 portraitCount:4]];
    [images addObjectsFromArray: [self imageArrayForPrefix:@"small" albumName:@"Small Images" landscapeCount:5 portraitCount:3]];
    [images addObjectsFromArray: [self headshotImageArray]];

    [self processImageQueue:[images copy]];
}

- (void) processImageQueue:(NSArray*)images
{
    numberOfPhotos = [images count];
    numberOfPhotosProcessed = 0;
    
    NSOperationQueue *transferQueue = [[NSOperationQueue alloc] init];
    transferQueue.name = @"Transfer Queue";
    transferQueue.maxConcurrentOperationCount = 1;
    [transferQueue waitUntilAllOperationsAreFinished];
    
    for (NSDictionary *imageData in images)
    {
        [transferQueue addOperationWithBlock: ^ {
            [self saveImage:imageData[@"image"] toAlbum:imageData[@"albumName"]];
        }];
    }
    
    [transferQueue addOperationWithBlock:^{
        
        if ([self.delegate respondsToSelector:@selector(didFinishTransferingImages)])
        {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.delegate didFinishTransferingImages];
            });
        }
        
    }];

}


- (void) saveImage:(UIImage*)image toAlbum:(NSString*)album
{
    dispatch_semaphore_t sema = dispatch_semaphore_create(0);
    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT,0);
    
    __weak ALAssetsLibrary *lib = self.library;
    
    NSLog(@"Image");
    
    dispatch_async(queue, ^{
        
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
                                                       dispatch_semaphore_signal(sema);
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
                                                   dispatch_semaphore_signal(sema);
                                               } failureBlock:^(NSError *error) {
                                                   NSLog(@"Error:  %@", error);
                                               }];
                                      }];
            }
            
        } failureBlock:^(NSError *error) {
            
        }];
        
    });
    
    
    dispatch_semaphore_wait(sema, DISPATCH_TIME_FOREVER);
    
    numberOfPhotosProcessed++;
    
    if ([self.delegate respondsToSelector:@selector(transferProgessForCurrent:withTotal:)])
    {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.delegate transferProgessForCurrent:numberOfPhotosProcessed withTotal:numberOfPhotos];
        });
    }
    
}

#pragma mark - Utility


-(NSArray*) imageArrayForPath:(NSString*)path albumName:(NSString*)albumName
{
    NSMutableArray *images = [NSMutableArray array];
    
    for (NSString *filePath in [[NSFileManager defaultManager] enumeratorAtPath:path].allObjects)
    {
        NSString *fileExtension = [[filePath pathExtension] lowercaseString];
        
        BOOL isPhoto = ([fileExtension isEqualToString:@"jpg"] || [fileExtension isEqualToString:@"png"]);
        
        if (isPhoto) {
            UIImage *image = [UIImage imageWithContentsOfFile:[path stringByAppendingPathComponent:filePath]];
            [images addObject:@{@"albumName":albumName,  @"image":image}];
        }
    }
    
    return [images copy];
}

-(NSArray*) imageArrayForPrefix:(NSString*)prefix albumName:(NSString*)albumName landscapeCount:(NSInteger)landscapeCount portraitCount:(NSInteger)portraitCount
{
    NSMutableArray *images = [NSMutableArray array];
    
    for (NSInteger l = 1; l < landscapeCount + 1; l++)
    {
        NSString *imageName = [NSString stringWithFormat:@"%@-l-0%li.jpg", prefix, (long)l];
        UIImage *image = [UIImage imageNamed:imageName];
        [images addObject:@{@"albumName":albumName, @"image":image}];
    }
    
    for (NSInteger p = 1; p < portraitCount + 1; p++)
    {
        NSString *imageName = [NSString stringWithFormat:@"%@-p-0%li.jpg", prefix, (long)p];
        UIImage *image = [UIImage imageNamed:imageName];
        [images addObject:@{@"albumName":albumName, @"image":image}];
    }
    
    return [images copy];
}

- (NSArray*) headshotImageArray
{
    NSMutableArray *images = [NSMutableArray array];
    
    for (NSInteger m = 1; m < 7; m++)
    {
        NSString *imageName = [NSString stringWithFormat:@"%man-0%li.jpg", (long)m];
        UIImage *image = [UIImage imageNamed:imageName];
        [images addObject:@{@"albumName":@"Headshots", @"image":image}];
    }
    
    for (NSInteger w = 1; w < 7; w++)
    {
        NSString *imageName = [NSString stringWithFormat:@"woman-0%li.jpg", (long)w];
        UIImage *image = [UIImage imageNamed:imageName];
        [images addObject:@{@"albumName":@"Headshots", @"image":image}];
    }
    
    return [images copy];
}

@end
