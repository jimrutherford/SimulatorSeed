//
//  ImageManager.h
//  SimulatorSeed
//
//  Created by Jim Rutherford on 2014-09-24.
//  Copyright (c) 2014 Taptonics. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@protocol ImageManagerDelegate <NSObject>

- (void) transferProgessForCurrent:(NSInteger)current withTotal:(NSInteger)total;
- (void) didFinishTransferingImages;

@end

@interface ImageManager : NSObject

@property (nonatomic, assign) id<ImageManagerDelegate> delegate;

- (void) transferStockImages;
- (void) transferCustomImagesFromPath:(NSString*)path;

@end
