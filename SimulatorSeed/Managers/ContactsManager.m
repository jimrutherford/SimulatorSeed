//
//  ContactsManager.m
//  SimulatorSeed
//
//  Created by Jim Rutherford on 2014-09-24.
//  Copyright (c) 2014 Taptonics. All rights reserved.
//

#import "ContactsManager.h"
#import <AddressBook/AddressBook.h>

@implementation ContactsManager

- (id)init {
    self = [super init];
    if (!self) return nil;
    
    return self;
}

- (void) importStockContacts
{

    NSDictionary *usersDict = [self dictionaryWithContentsOfJSONString:@"users.json"];
    
    if (usersDict)
    {
        [self importContactsFromJSONDictionary:usersDict[@"results"]];
        
    }
    
    
}

- (NSDictionary*) dictionaryWithContentsOfJSONString:(NSString*)fileLocation
{
    NSString *filePath = [[NSBundle mainBundle] pathForResource:[fileLocation stringByDeletingPathExtension] ofType:[fileLocation pathExtension]];
    NSData* data = [NSData dataWithContentsOfFile:filePath];
    __autoreleasing NSError* error = nil;
    id result = [NSJSONSerialization JSONObjectWithData:data
                                                options:kNilOptions error:&error];
    // Be careful here. You add this as a category to NSDictionary
    // but you get an id back, which means that result
    // might be an NSArray as well!
    if (error != nil) return nil;
    return result;
}

- (void) importContactsFromJSONDictionary:(NSDictionary*)usersDict
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

        ABAddressBookRef addressBook = ABAddressBookCreateWithOptions(NULL, NULL);
        
        for (NSDictionary *userDict in usersDict) {
            NSLog(@"Users %@", userDict);
            
            NSString *firstName = userDict[@"user"][@"name"][@"first"];
            NSString *lastName = userDict[@"user"][@"name"][@"last"];
            NSString *prefix = userDict[@"user"][@"name"][@"title"];
            NSString *profilePicture = userDict[@"user"][@"profilePicture"];
            
            ABRecordRef person = ABPersonCreate();
            
            // name
            ABRecordSetValue(person, kABPersonFirstNameProperty, (__bridge CFTypeRef)(firstName), nil);
            ABRecordSetValue(person, kABPersonLastNameProperty, (__bridge CFTypeRef)(lastName), nil);
            ABRecordSetValue(person, kABPersonPrefixProperty, (__bridge CFTypeRef)(prefix), nil);
            
            
            // phone
            
            NSString *phone = userDict[@"user"][@"phone"][@"home"];
            ABMutableMultiValueRef phoneNumberMultiValue = ABMultiValueCreateMutable(kABPersonPhoneProperty);
            CFStringRef phoneType = (arc4random() % 2 == 0 ? kABPersonPhoneMainLabel : kABPersonPhoneMobileLabel);
            ABMultiValueAddValueAndLabel(phoneNumberMultiValue, (__bridge CFTypeRef)(phone), phoneType, NULL);
            ABRecordSetValue(person, kABPersonPhoneProperty, phoneNumberMultiValue, nil);
            
            // address
            NSString *street = userDict[@"user"][@"location"][@"street"];
            NSString *city = userDict[@"user"][@"location"][@"city"];
            NSString *state = userDict[@"user"][@"location"][@"state"];
            NSString *zip = userDict[@"user"][@"location"][@"zip"];
            
            CFStringRef label = [self labelForKey:@"homer" orDefault:kABWorkLabel];
            
            ABMutableMultiValueRef multiHome = ABMultiValueCreateMutable(kABMultiDictionaryPropertyType);
            NSMutableDictionary *addressDictionary = [[NSMutableDictionary alloc] init];
            [addressDictionary setObject:street forKey:(NSString *)kABPersonAddressStreetKey];
            [addressDictionary setObject:city forKey:(NSString *)kABPersonAddressCityKey];
            [addressDictionary setObject:state forKey:(NSString *)kABPersonAddressStateKey];
            [addressDictionary setObject:zip forKey:(NSString *)kABPersonAddressZIPKey];
            ABMultiValueAddValueAndLabel(multiHome, (__bridge CFTypeRef)(addressDictionary), label, NULL);
            ABRecordSetValue(person, kABPersonAddressProperty, multiHome, NULL);
            
            
            /*
             kABPersonEmailProperty
             
             kABPersonOrganizationProperty
             kABPersonJobTitleProperty
            kABPersonDepartmentProperty
             
            kABPersonBirthdayProperty
            
            */
            
            UIImage *img = [UIImage imageNamed:profilePicture];
            NSData *dataRef = UIImagePNGRepresentation(img);
            ABPersonSetImageData(person, (__bridge CFDataRef)dataRef, nil);
            
            ABAddressBookAddRecord(addressBook, person, nil);
            ABAddressBookSave(addressBook, nil);

            CFRelease(phoneNumberMultiValue);
            CFRelease(person);
        }
        
        CFRelease(addressBook);
        
        
    }
}

-(CFStringRef) labelForKey:(NSString*)key orDefault:(CFStringRef)defaultLabel
{
    NSString *cleanedKey = [key lowercaseString];
    
    if ([cleanedKey isEqualToString:@"home"])
    {
        return kABHomeLabel;
    }
    
    return defaultLabel;
}


@end
