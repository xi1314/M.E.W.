//
//  MEWRootViewController.m
//  MewApp
//
//  Created by Zheng on 07/05/2017.
//  Copyright © 2017 Zheng. All rights reserved.
//

#import "MobileGestalt.h"
#import "MEWRootViewController.h"
#import <Preferences/PSSpecifier.h>

typedef mach_port_t	io_object_t;
typedef io_object_t	io_registry_entry_t;
typedef char		io_name_t[128];
typedef UInt32		IOOptionBits;

static NSString * const kMewOriginalDeviceName = @"OriginalDeviceName";
static NSString * const kMewOriginalIOPlatformSerialNumber = @"OriginalIOPlatformSerialNumber";
static NSString * const kMewOriginalSystemVersion = @"OriginalSystemVersion";
static NSString * const kMewOriginalDeviceType = @"OriginalDeviceType";
static NSString * const kMewOriginalIOPlatformUUID = @"OriginalIOPlatformUUID";

@interface MEWRootViewController ()

@end

@implementation MEWRootViewController {
    NSString *_kMewDeviceSerial;
    NSString *_kMewDeviceNodename;
    NSString *_kMewDeviceMachine;
    NSString *_kMewDeviceSystem;
}

- (void)loadDeviceInfo {
    
    _kMewDeviceSerial = MEWCopyAnswer(kMewSerialNumber);
    _kMewDeviceNodename = MEWCopyAnswer(kMewDeviceName);
    _kMewDeviceMachine = [NSString stringWithFormat:@"%@ (%@)", MEWCopyAnswer(kMewSystemVersion), MEWCopyAnswer(kMewSystemBuildVersion)];
    _kMewDeviceSystem = [NSString stringWithFormat:@"%@ (%@)", MEWCopyAnswer(kMewProductType), MEWCopyAnswer(kMewProductHWModel)];
    
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.navigationController.navigationBar.translucent = NO;
    
    [self loadDeviceInfo];
}

- (NSString *)valueForSpecifier:(PSSpecifier *)spec {
    if ([[spec propertyForKey:PSKeyNameKey] isEqualToString:kMewOriginalDeviceName]) {
        return _kMewDeviceNodename;
    } else if ([[spec propertyForKey:PSKeyNameKey] isEqualToString:kMewOriginalSystemVersion]) {
        return _kMewDeviceSystem;
    } else if ([[spec propertyForKey:PSKeyNameKey] isEqualToString:kMewOriginalDeviceType]) {
        return _kMewDeviceMachine;
    } else if ([[spec propertyForKey:PSKeyNameKey] isEqualToString:kMewOriginalIOPlatformSerialNumber]) {
        return _kMewDeviceSerial;
    }
    
    return @"";
}

- (void)performButtonAction:(PSSpecifier *)spec {
    NSArray <NSString *> *kwargs = [spec propertyForKey:@"kwargs"];
    if (kwargs.count == 1) {
        NSString *action = kwargs[0];
        if ([action isEqualToString:@"clean_keychain"]) {
            NSError *error = nil;
            if ([[MEWSharedUtility sharedInstance] cleanSystemKeychainWithError:&error]) {
                UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"提示"
                                                                    message:@"Keychain 清理完成"
                                                                   delegate:nil
                                                          cancelButtonTitle:@"好"
                                                          otherButtonTitles:nil];
                [alertView show];
            } else {
                UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"错误"
                                                                    message:[error localizedDescription]
                                                                   delegate:nil
                                                          cancelButtonTitle:@"好"
                                                          otherButtonTitles:nil];
                [alertView show];
            }
        }
    }
}

@end
