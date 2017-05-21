//
//  MEWMergedGlobalController.m
//  MewApp
//
//  Created by Zheng on 18/05/2017.
//  Copyright © 2017 Zheng. All rights reserved.
//

#import "MEWMergedGlobalController.h"
#import <Preferences/PSSpecifier.h>

static NSString * const kMewEncOriginalDeviceName = @"OriginalDeviceName";
static NSString * const kMewEncOriginalIOPlatformSerialNumber = @"OriginalIOPlatformSerialNumber";
static NSString * const kMewEncOriginalSystemVersion = @"OriginalSystemVersion";
static NSString * const kMewEncOriginalDeviceType = @"OriginalDeviceType";
static NSString * const kMewEncOriginalIOPlatformUUID = @"OriginalIOPlatformUUID";

@interface MEWMergedGlobalController ()

@end

@implementation MEWMergedGlobalController {
    NSString *_kMewDeviceSerial;
    NSString *_kMewDeviceNodename;
    NSString *_kMewDeviceMachine;
    NSString *_kMewDeviceSystem;
}

- (void)loadDeviceInfo {
    
    _kMewDeviceSerial = MEWCopyAnswer(kMewEncSerialNumber);
    _kMewDeviceNodename = MEWCopyAnswer(kMewEncDeviceName);
    _kMewDeviceMachine = [NSString stringWithFormat:@"%@ (%@)", MEWCopyAnswer(kMewEncSystemVersion), MEWCopyAnswer(kMewEncSystemBuildVersion)];
    _kMewDeviceSystem = [NSString stringWithFormat:@"%@ (%@)", MEWCopyAnswer(kMewEncProductType), MEWCopyAnswer(kMewEncProductHWModel)];
    
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.navigationController.navigationBar.translucent = NO;
    
    [self loadDeviceInfo];
}

- (NSString *)valueForSpecifier:(PSSpecifier *)spec {
    if ([[spec propertyForKey:PSKeyNameKey] isEqualToString:kMewEncOriginalDeviceName]) {
        return _kMewDeviceNodename;
    } else if ([[spec propertyForKey:PSKeyNameKey] isEqualToString:kMewEncOriginalSystemVersion]) {
        return _kMewDeviceSystem;
    } else if ([[spec propertyForKey:PSKeyNameKey] isEqualToString:kMewEncOriginalDeviceType]) {
        return _kMewDeviceMachine;
    } else if ([[spec propertyForKey:PSKeyNameKey] isEqualToString:kMewEncOriginalIOPlatformSerialNumber]) {
        return _kMewDeviceSerial;
    }
    
    return @"";
}

@end
