//
//  MEWConfiguration.h
//  MewApp
//
//  Created by Zheng on 11/05/2017.
//  Copyright © 2017 Zheng. All rights reserved.
//

#ifndef MEWConfiguration_h
#define MEWConfiguration_h

static NSString * const kMewConfigPath = @"/private/var/mobile/Library/Preferences/com.darwindev.MewApp.plist";
static NSString * const kMewPasteboardHistoryPath = @"/private/var/mobile/Library/Preferences/com.darwindev.MewApp.pasteboard.plist";
static NSString * const kMewPasteboardHistoryKey = @"PasteboardHistory";

static NSString * const kMewApplicationIdentifierWhiteList = @"ApplicationIdentifierWhiteList";
static NSString * const kMewApplicationIdentifierBlackList = @"ApplicationIdentifierBlackList";
static NSString * const kMewEthernetIPv4Address = @"EthernetIPv4Address";
static NSString * const kMewSwitchFakeRandomLocation = @"SwitchFakeRandomLocation";
static NSString * const kMewUniqueIdentifier = @"UniqueIdentifier";
static NSString * const kMewStringSearchBypassList = @"StringSearchBypassList";
static NSString * const kMewEthernetBSSID = @"EthernetBSSID";
static NSString * const kMewNetworkInterfaces = @"NetworkInterfaces";
static NSString * const kMewSwitchFakeLocation = @"SwitchFakeLocation";
static NSString * const kMewSwitchAutoBackup = @"SwitchAutoBackup";
static NSString * const kMewCarrierVersionString = @"CarrierVersionString";
static NSString * const kMewSwitchFakeJailbreak = @"SwitchFakeJailbreak";
static NSString * const kMewProductType = @"ProductType";
static NSString * const kMewIdentifierForVendor = @"IdentifierForVendor";
static NSString * const kMewSwitchFakeApplicationList = @"SwitchFakeApplicationList";
static NSString * const kMewReplaceEnvironmentVariableList = @"ReplaceEnvironmentVariableList";
static NSString * const kMewDeviceName = @"DeviceName";
static NSString * const kMewSerialNumber = @"SerialNumber";
static NSString * const kMewDeviceBatteryState = @"DeviceBatteryState";
static NSString * const kMewProductHWModel = @"ProductHWModel";
static NSString * const kMewBluetoothAddress = @"BluetoothAddress";
static NSString * const kMewMLBSerialNumber = @"MLBSerialNumber";
static NSString * const kMewNetworkType = @"NetworkType";
static NSString * const kMewCurrentMobileId = @"CurrentMobileId";
static NSString * const kMewReplaceImagePathList = @"ReplaceImagePathList";
static NSString * const kMewURLSchemeCheckBypassList = @"URLSchemeCheckBypassList";
static NSString * const kMewCountryCode = @"CountryCode";
static NSString * const kMewSwitchFakeNetworkInfo = @"SwitchFakeNetworkInfo";
static NSString * const kMewNetworkCode = @"NetworkCode";
static NSString * const kMewUniqueChipID = @"UniqueChipID";
static NSString * const kMewEthernetIPv6Address = @"EthernetIPv6Address";
static NSString * const kMewEthernetMacAddress = @"EthernetMacAddress";
static NSString * const kMewScreenBrightness = @"ScreenBrightness";
static NSString * const kMewCoordinateRegionLongitudeKey = @"CoordinateRegionLongitudeKey";
static NSString * const kMewServiceString = @"ServiceString";
static NSString * const kMewSystemVersion = @"SystemVersion";
static NSString * const kMewEthernetSSID = @"EthernetSSID";
static NSString * const kMewDeviceCategory = @"DeviceCategory";
static NSString * const kMewAdvertisingIdentifier = @"AdvertisingIdentifier";
static NSString * const kMewPathCheckBypassList = @"PathCheckBypassList";
static NSString * const kMewReplaceMGCopyAnswer = @"ReplaceMGCopyAnswer";
static NSString * const kMewISOCountryCode = @"ISOCountryCode";
static NSString * const kMewICCID = @"ICCID";
static NSString * const kMewSystemBuildVersion = @"SystemBuildVersion";
static NSString * const kMewSwitchMonitorPasteboard = @"SwitchMonitorPasteboard";
static NSString * const kMewCoordinateRegionLatitudeKey = @"CoordinateRegionLatitudeKey";
static NSString * const kMewReplaceApplicationIdentifierList = @"ReplaceApplicationIdentifierList";
static NSString * const kMewCarrierName = @"CarrierName";
static NSString * const kMewUniqueDeviceID = @"UniqueDeviceID";
static NSString * const kMewIMSI = @"IMSI";
static NSString * const kMewSwitchAutoCleanPasteboard = @"SwitchAutoCleanPasteboard";
static NSString * const kMewMEID = @"MEID";
static NSString * const kMewSystemName = @"SystemName";
static NSString * const kMewReplaceIOKitProperties = @"ReplaceIOKitProperties";
static NSString * const kMewDirectoryCheckBypassList = @"DirectoryCheckBypassList";
static NSString * const kMewEnabled = @"Enabled";
static NSString * const kMewCurrentSubscriberId = @"CurrentSubscriberId";
static NSString * const kMewInternationalMobileEquipmentIdentity = @"InternationalMobileEquipmentIdentity";
static NSString * const kMewSwitchFakeDeviceInfo = @"SwitchFakeDeviceInfo";
static NSString * const kMewOpenUDID = @"OpenUDID";
static NSString * const kMewTimezoneName = @"TimezoneName";
static NSString * const kMewTimezoneData = @"TimezoneData";
// Dictionary Key

static NSString * const kMewIOPlatformSerialNumber = @"IOPlatformSerialNumber";
static NSString * const kMewIOPlatformUUID = @"IOPlatformUUID";
static NSString * const kMewIOSerialNumber = @"serial-number";
static NSString * const kMewIOMLBSerialNumber = @"mlb-serial-number";
static NSString * const kMewIOBluetoothAddress = @"local-mac-address";
static NSString * const kMewIOInternationalMobileEquipmentIdentity = @"device-imei";
static NSString * const kMewIOUniqueChipId = @"unique-chip-id";

static NSString * const kCTMobileEquipmentInfoIMEI = @"kCTMobileEquipmentInfoIMEI";
static NSString * const kCTMobileEquipmentInfoCurrentMobileId = @"kCTMobileEquipmentInfoCurrentMobileId";
static NSString * const kCTMobileEquipmentInfoICCID = @"kCTMobileEquipmentInfoICCID";
static NSString * const kCTMobileEquipmentInfoMEID = @"kCTMobileEquipmentInfoMEID";
static NSString * const kCTMobileEquipmentInfoIMSI = @"kCTMobileEquipmentInfoIMSI";
static NSString * const kCTMobileEquipmentInfoCurrentSubscriberId = @"kCTMobileEquipmentInfoCurrentSubscriberId";

static NSString * const kMewPlistSystemVersionPlistPath = @"/System/Library/CoreServices/SystemVersion.plist";
static NSString * const kMewPlistSystemVersionProductVersion = @"ProductVersion";
static NSString * const kMewPlistSystemVersionProductBuildVersion = @"ProductBuildVersion";
static NSString * const kMewPlistSystemVersionProductName = @"ProductName";

#endif /* MEWConfiguration_h */
