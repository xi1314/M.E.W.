//
//  MEWConfiguration.h
//  MewApp
//
//  Created by Zheng on 11/05/2017.
//  Copyright © 2017 Zheng. All rights reserved.
//



#ifndef MEWConfiguration_h
#define MEWConfiguration_h

//#define TEST_FLAG 1

#include "myencrypt.h"

static NSString * const kMewEncBundleID = @"com.darwindev.MewApp";
static NSString * const kMewEncErrorDomain = @"com.darwindev.MewApp.error";
static NSString * const kMewEncConfigName = @"com.darwindev.MewApp.plist";
static NSString * const kMewEncConfigPath = @"/private/var/mobile/Library/Preferences/com.darwindev.MewApp.plist";
static NSString * const kMewEncBackupPath = @"/private/var/mobile/Media/MEWBackup";
static NSString * const kMewEncPasteboardHistoryPath = @"/private/var/mobile/Library/Preferences/com.darwindev.MewApp.pasteboard.plist";
static NSString * const kMewEncPasteboardHistoryKey = @"PasteboardHistory";

static NSString * const kMewEncApplicationIdentifierWhiteList = @"ApplicationIdentifierWhiteList";
static NSString * const kMewEncApplicationIdentifierBlackList = @"ApplicationIdentifierBlackList";
static NSString * const kMewEncEthernetIPv4Address = @"EthernetIPv4Address";
static NSString * const kMewEncSwitchFakeRandomLocation = @"SwitchFakeRandomLocation";
static NSString * const kMewEncTimezoneData = @"TimezoneData";
static NSString * const kMewEncUniqueIdentifier = @"UniqueIdentifier";
static NSString * const kMewEncStringSearchBypassList = @"StringSearchBypassList";
static NSString * const kMewEncEthernetBSSID = @"EthernetBSSID";
static NSString * const kMewEncOpenUDIDValue = @"OpenUDIDValue";
static NSString * const kMewEncNetworkInterfaces = @"NetworkInterfaces";
static NSString * const kMewEncSwitchFakeLocation = @"SwitchFakeLocation";
static NSString * const kMewEncSwitchAutoBackup = @"SwitchAutoBackup";
static NSString * const kMewEncCarrierVersionString = @"CarrierVersionString";
static NSString * const kMewEncSwitchFakeJailbreak = @"SwitchFakeJailbreak";
static NSString * const kMewEncProductType = @"ProductType";
static NSString * const kMewEncIdentifierForVendor = @"IdentifierForVendor";
static NSString * const kMewEncSwitchFakeApplicationList = @"SwitchFakeApplicationList";
static NSString * const kMewEncReplaceEnvironmentVariableList = @"ReplaceEnvironmentVariableList";
static NSString * const kMewEncDeviceName = @"DeviceName";
static NSString * const kMewEncSerialNumber = @"SerialNumber";
static NSString * const kMewEncDeviceBatteryState = @"DeviceBatteryState";
static NSString * const kMewEncTimezoneName = @"TimezoneName";
static NSString * const kMewEncProductHWModel = @"ProductHWModel";
static NSString * const kMewEncBluetoothAddress = @"BluetoothAddress";
static NSString * const kMewEncRegionInfo = @"RegionInfo";
static NSString * const kMewEncMLBSerialNumber = @"MLBSerialNumber";
static NSString * const kMewEncNetworkType = @"NetworkType";
static NSString * const kMewEncCurrentMobileId = @"CurrentMobileId";
static NSString * const kMewEncReplaceImagePathList = @"ReplaceImagePathList";
static NSString * const kMewEncRegionCode = @"RegionCode";
static NSString * const kMewEncURLSchemeCheckBypassList = @"URLSchemeCheckBypassList";
static NSString * const kMewEncCountryCode = @"CountryCode";
static NSString * const kMewEncSwitchFakeNetworkInfo = @"SwitchFakeNetworkInfo";
static NSString * const kMewEncProductModel = @"ProductModel";
static NSString * const kMewEncNetworkCode = @"NetworkCode";
static NSString * const kMewEncUniqueChipID = @"UniqueChipID";
static NSString * const kMewEncEthernetIPv6Address = @"EthernetIPv6Address";
static NSString * const kMewEncEthernetMacAddress = @"EthernetMacAddress";
static NSString * const kMewEncScreenBrightness = @"ScreenBrightness";
static NSString * const kMewEncInverseDeviceID = @"InverseDeviceID";
static NSString * const kMewEncCoordinateRegionLongitudeKey = @"CoordinateRegionLongitudeKey";
static NSString * const kMewEncServiceString = @"ServiceString";
static NSString * const kMewEncSystemVersion = @"SystemVersion";
static NSString * const kMewEncEthernetSSID = @"EthernetSSID";
static NSString * const kMewEncDeviceCategory = @"DeviceCategory";
static NSString * const kMewEncAdvertisingIdentifier = @"AdvertisingIdentifier";
static NSString * const kMewEncPathCheckBypassList = @"PathCheckBypassList";
static NSString * const kMewEncReplaceMGCopyAnswer = @"ReplaceMGCopyAnswer";
static NSString * const kMewEncISOCountryCode = @"ISOCountryCode";
static NSString * const kMewEncICCID = @"ICCID";
static NSString * const kMewEncSystemBuildVersion = @"SystemBuildVersion";
static NSString * const kMewEncSwitchMonitorPasteboard = @"SwitchMonitorPasteboard";
static NSString * const kMewEncEthernetRSSID = @"EthernetRSSID";
static NSString * const kMewEncCoordinateRegionLatitudeKey = @"CoordinateRegionLatitudeKey";
static NSString * const kMewEncReplaceApplicationIdentifierList = @"ReplaceApplicationIdentifierList";
static NSString * const kMewEncCarrierName = @"CarrierName";
static NSString * const kMewEncUniqueDeviceID = @"UniqueDeviceID";
static NSString * const kMewEncIMSI = @"IMSI";
static NSString * const kMewEncSwitchAutoCleanPasteboard = @"SwitchAutoCleanPasteboard";
static NSString * const kMewEncMEID = @"MEID";
static NSString * const kMewEncSystemName = @"SystemName";
static NSString * const kMewEncReplaceIOKitProperties = @"ReplaceIOKitProperties";
static NSString * const kMewEncDirectoryCheckBypassList = @"DirectoryCheckBypassList";
static NSString * const kMewEncEnabled = @"Enabled";
static NSString * const kMewEncCurrentSubscriberId = @"CurrentSubscriberId";
static NSString * const kMewEncInternationalMobileEquipmentIdentity = @"InternationalMobileEquipmentIdentity";
static NSString * const kMewEncSwitchFakeDeviceInfo = @"SwitchFakeDeviceInfo";
static NSString * const kMewEncVerifyKeys = @"MewVerifyKeys";

// Mew Checksum

static NSString * const kMewEncVersion = @"MewVersion";
static NSString * const kMewEncLastLaunchTime = @"MewLastLaunchTime";
static NSString * const kMewEncUniqueId = @"MewUniqueId";
static NSString * const kMewEncChecksum = @"MewChecksum";
static NSString * const kMewEncConfigPathVerify = @"1jP5YdD1fqhPlK3Pe/9CbZ1vUx2z4Wgjdx4h10o9uberZ3+R4KAB1449TQQQoRHyQONQFaAOQ7UnDc4bQq/cBh4ceuef4n2trNpskeedabcbfSqY+Q7UJM0454DaPbI5";

// Dictionary Key

static NSString * const kMewEncIOPlatformSerialNumber = @"IOPlatformSerialNumber";
static NSString * const kMewEncIOPlatformUUID = @"IOPlatformUUID";
static NSString * const kMewEncIOSerialNumber = @"serial-number";
static NSString * const kMewEncIOMLBSerialNumber = @"mlb-serial-number";
static NSString * const kMewEncIOBluetoothAddress = @"local-mac-address";
static NSString * const kMewEncIOInternationalMobileEquipmentIdentity = @"device-imei";
static NSString * const kMewEncIOUniqueChipId = @"unique-chip-id";

static NSString * const kMewEncCTMobileEquipmentInfoIMEI = @"kCTMobileEquipmentInfoIMEI";
static NSString * const kMewEncCTMobileEquipmentInfoCurrentMobileId = @"kCTMobileEquipmentInfoCurrentMobileId";
static NSString * const kMewEncCTMobileEquipmentInfoICCID = @"kCTMobileEquipmentInfoICCID";
static NSString * const kMewEncCTMobileEquipmentInfoMEID = @"kCTMobileEquipmentInfoMEID";
static NSString * const kMewEncCTMobileEquipmentInfoIMSI = @"kCTMobileEquipmentInfoIMSI";
static NSString * const kMewEncCTMobileEquipmentInfoCurrentSubscriberId = @"kCTMobileEquipmentInfoCurrentSubscriberId";

static NSString * const kMewEncPlistSystemVersionPlistPath = @"/System/Library/CoreServices/SystemVersion.plist";
static NSString * const kMewEncPlistSystemVersionProductVersion = @"ProductVersion";
static NSString * const kMewEncPlistSystemVersionProductBuildVersion = @"ProductBuildVersion";
static NSString * const kMewEncPlistSystemVersionProductName = @"ProductName";

static NSMutableDictionary *kMewCachedConfig = nil;
static NSTimeInterval kMewCachedTime = 0.0;

__attribute((obfuscate))
static inline id R(NSString* key) {
    if (!kMewCachedConfig) {
        kMewCachedConfig = [[NSMutableDictionary alloc] initWithContentsOfFile:kMewEncConfigPath];
        if (kMewCachedConfig) {
            kMewCachedTime = [[NSDate date] timeIntervalSince1970];
        }
    }
    if (!kMewCachedConfig[key]) {
        return nil;
    }
    
    // random check hash
    NSTimeInterval nowTime = [[NSDate date] timeIntervalSince1970];
    if ((int)(arc4random() % 100) < (int)((nowTime - kMewCachedTime) / 7200 * 100)) {
        kMewCachedTime = nowTime;
        
        NSArray <NSString *> *allowedKeys = kMewCachedConfig[kMewEncVerifyKeys];
        assert(allowedKeys);
        NSMutableArray <NSDictionary *> *entries = [[NSMutableArray alloc] initWithCapacity:allowedKeys.count];
        for (NSString *allowedKey in allowedKeys) {
            if (allowedKey && kMewCachedConfig[allowedKey]) {
                [entries addObject:@{allowedKey: kMewCachedConfig[allowedKey]}];
            }
        }
        NSMutableData *entryJSONData = [[NSJSONSerialization dataWithJSONObject:entries options:0 error:nil] mutableCopy];
        if (entryJSONData) {
            NSString *entrySalt = D(kMewEncConfigPathVerify);
            if (entrySalt) {
                [entryJSONData appendData:[entrySalt dataUsingEncoding:NSUTF8StringEncoding]];
                unsigned char hashBuffer[20] = "";
                _T(entryJSONData.bytes, (unsigned int)entryJSONData.length, hashBuffer);
//                CC_SHA1(entryJSONData.bytes, (unsigned int)entryJSONData.length, hashBuffer);
                NSMutableString *outputHash = [NSMutableString stringWithCapacity:40];
                for (int i = 0; i < 20; i++)
                    [outputHash appendFormat:@"%02x", hashBuffer[i]];
#ifdef TEST_FLAG
                NSLog(@"======== CHECKSUM %@ ========", outputHash);
#endif
                NSString *recordedHash = kMewCachedConfig[kMewEncChecksum];
                assert([outputHash isEqualToString:recordedHash]);
            }
        }
        
    }
    
    return kMewCachedConfig[key];
}

__attribute((obfuscate))
static inline void S(NSString* key, id value) {
    if (!kMewCachedConfig) {
        kMewCachedConfig = [[NSMutableDictionary alloc] initWithContentsOfFile:kMewEncConfigPath];
    }
    if (!kMewCachedConfig) {
        kMewCachedConfig = [[NSMutableDictionary alloc] init];
    }
    [kMewCachedConfig setObject:value forKey:key];
    
    // write to file with hash and salt
    NSArray <NSString *> *allowedKeys = kMewCachedConfig[kMewEncVerifyKeys];
    if (allowedKeys) {
        NSMutableArray <NSDictionary *> *entries = [[NSMutableArray alloc] initWithCapacity:allowedKeys.count];
        for (NSString *allowedKey in allowedKeys) {
            if (allowedKey && kMewCachedConfig[allowedKey]) {
                [entries addObject:@{allowedKey: kMewCachedConfig[allowedKey]}];
            }
        }
        NSMutableData *entryJSONData = [[NSJSONSerialization dataWithJSONObject:entries options:0 error:nil] mutableCopy];
        if (entryJSONData) {
            NSString *entrySalt = D(kMewEncConfigPathVerify);
            if (entrySalt) {
                [entryJSONData appendData:[entrySalt dataUsingEncoding:NSUTF8StringEncoding]];
                unsigned char hashBuffer[20] = "";
                _T(entryJSONData.bytes, (unsigned int)entryJSONData.length, hashBuffer);
//                CC_SHA1(entryJSONData.bytes, (unsigned int)entryJSONData.length, hashBuffer);
                NSMutableString *outputHash = [NSMutableString stringWithCapacity:40];
                for (int i = 0; i < 20; i++)
                    [outputHash appendFormat:@"%02x", hashBuffer[i]];
                [kMewCachedConfig setObject:outputHash forKey:kMewEncChecksum];
#ifdef TEST_FLAG
                NSLog(@"======== HASH %@ ========", outputHash);
#endif
                [kMewCachedConfig writeToFile:kMewEncConfigPath atomically:YES];
            }
        }
    }
    
}

__attribute((obfuscate))
static inline void M() {
    remove([kMewEncPasteboardHistoryPath UTF8String]);
    remove([kMewEncConfigPath UTF8String]);
}

#endif /* MEWConfiguration_h */


