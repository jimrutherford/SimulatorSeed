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

-(void)importContacts:(NSString*)seedDataPath
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
    
    //[SVProgressHUD dismissWithSuccess:@"Success." afterDelay:3];
}


@end
