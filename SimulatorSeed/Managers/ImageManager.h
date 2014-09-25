//
//  ImageManager.h
//  SimulatorSeed
//
//  Created by Jim Rutherford on 2014-09-24.
//  Copyright (c) 2014 Taptonics. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

typedef enum
{
    ImageTypeBig = 0,
    ImageTypeMedium,
    ImageTypeSmall,
    ImageTypeHeadshots,
    ImageTypeFilesystem
    
} ImageType;

@interface ImageManager : NSObject

- (void) transferImagesOfType:(ImageType)type;

@end
