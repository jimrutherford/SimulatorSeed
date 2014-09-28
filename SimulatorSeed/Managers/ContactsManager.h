//
//  ContactsManager.h
//  SimulatorSeed
//
//  Created by Jim Rutherford on 2014-09-24.
//  Copyright (c) 2014 Taptonics. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface ContactsManager : NSObject

- (void) importStockContacts;
- (void) importContacts:(NSString*)seedDataPath;

@end
