//
//  MEWSharedUtility.m
//  MewApp
//
//  Created by Zheng on 10/05/2017.
//  Copyright © 2017 Zheng. All rights reserved.
//

#import "MEWSharedUtility.h"
#import "MobileGestalt.h"
#import <dlfcn.h>
#import <net/if.h>
#import <sqlite3.h>
#import <ifaddrs.h>
#import <arpa/inet.h>
#import <net/if_dl.h>
#import <netinet/in.h>
#import "MEWOpenUDID.h"
#import <objc/runtime.h>

static CFStringRef (*$MGCopyAnswer)(CFStringRef);
struct CTServerConnection {
    int a; int b;
    CFMachPortRef myport;
    int c; int d; int e;
    int f; int g; int h; int i;
};
struct CTResult {
    int flag; int a;
};

@implementation MEWSharedUtility {
    
}

+ (instancetype)sharedInstance {
    static MEWSharedUtility *util = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        util = [[self alloc] init];
        void *gestalt;
        gestalt = dlopen("/usr/lib/libMobileGestalt.dylib", RTLD_GLOBAL | RTLD_LAZY);
        if (gestalt) {
            $MGCopyAnswer = dlsym(gestalt, "MGCopyAnswer");
        }
    });
    return util;
}

- (NSString *)MGCopyAnswer:(CFStringRef)key {
    return CFBridgingRelease($MGCopyAnswer(key));
}

- (id)MEWCopyAnswer:(NSString *)key {
    
    if ([key isEqualToString:kMewDeviceName]) {
        return [self MGCopyAnswer:kMGUserAssignedDeviceName];
    }
    else if ([key isEqualToString:kMewDeviceCategory]) {
        return [self MGCopyAnswer:kMGDeviceName];
    }
    else if ([key isEqualToString:kMewProductType]) {
        return [self MGCopyAnswer:kMGProductType];
    }
    else if ([key isEqualToString:kMewProductHWModel]) {
        return [self MGCopyAnswer:kMGHWModel];
    }
    else if ([key isEqualToString:kMewSerialNumber]) {
        return [self MGCopyAnswer:kMGSerialNumber];
    }
    else if ([key isEqualToString:kMewMLBSerialNumber]) {
        return [self MGCopyAnswer:kMGMLBSerialNumber];
    }
    else if ([key isEqualToString:kMewBluetoothAddress]) {
        return [self MGCopyAnswer:kMGBluetoothAddress];
    }
    else if ([key isEqualToString:kMewSystemName]) {
        return [self MGCopyAnswer:kMGProductName];
    }
    else if ([key isEqualToString:kMewSystemVersion]) {
        return [self MGCopyAnswer:kMGProductVersion];
    }
    else if ([key isEqualToString:kMewSystemBuildVersion]) {
        return [self MGCopyAnswer:kMGBuildVersion];
    }
    else if ([key isEqualToString:kMewUniqueIdentifier]) {
        return [[UIDevice currentDevice] performSelector:@selector(uniqueIdentifier)];
    }
    else if ([key isEqualToString:kMewUniqueDeviceID]) {
        return [self MGCopyAnswer:kMGUniqueDeviceID];
    }
    else if ([key isEqualToString:kMewUniqueChipID]) {
        return [self MGCopyAnswer:kMGUniqueChipID];
    }
    else if ([key isEqualToString:kMewIdentifierForVendor]) {
        return [[[UIDevice currentDevice] identifierForVendor] UUIDString];
    }
    else if ([key isEqualToString:kMewAdvertisingIdentifier]) {
        void *frameworkAdSupport = dlopen("/System/Library/Frameworks/AdSupport.framework/AdSupport", RTLD_NOW);
        if (frameworkAdSupport) {
            id answer = [[[objc_getClass("ASIdentifierManager") performSelector:@selector(sharedManager)] performSelector:@selector(advertisingIdentifier)] performSelector:@selector(UUIDString)];
            dlclose(frameworkAdSupport);
            return answer;
        }
    }
    else if ([key isEqualToString:kMewDeviceBatteryState]) {
        return @([[UIDevice currentDevice] batteryState]);
    }
    else if ([key isEqualToString:kMewScreenBrightness]) {
        return @([[UIScreen mainScreen] brightness]);
    }
    else if ([key isEqualToString:kMewEthernetMacAddress]) {
        return [self MGCopyAnswer:kMGWifiAddress];
    }
    else if ([key isEqualToString:kMewOpenUDID]) {
        return [MEWOpenUDID value];
    }
    else if ([key isEqualToString:kMewTimezoneName]) {
        NSTimeZone *timeZone = [NSTimeZone localTimeZone];
        return [timeZone name];
    }
    else if ([key isEqualToString:kMewTimezoneData]) {
        NSTimeZone *timeZone = [NSTimeZone localTimeZone];
        return [timeZone data];
    }
    if ([key isEqualToString:kMewEthernetIPv4Address]) {
        NSString *ipv4Address = nil;
        struct ifaddrs *interfaces;
        if(!getifaddrs(&interfaces)) {
            struct ifaddrs *interface;
            for (interface = interfaces; interface; interface = interface->ifa_next) {
                if(!(interface->ifa_flags & IFF_UP) /* || (interface->ifa_flags & IFF_LOOPBACK) */ ) {
                    continue;
                }
                const struct sockaddr_in *addr = (const struct sockaddr_in*)interface->ifa_addr;
                char addrBuf[ MAX(INET_ADDRSTRLEN, INET6_ADDRSTRLEN) ];
                if (strstr(interface->ifa_name, "en")) {
                    if (addr && (addr->sin_family == AF_INET || addr->sin_family == AF_INET6)) {
                        if (addr->sin_family == AF_INET) {
                            if (inet_ntop(AF_INET, &addr->sin_addr, addrBuf, INET_ADDRSTRLEN)) {
                                ipv4Address = [NSString stringWithUTF8String:addrBuf];
                            }
                        } else {
                            const struct sockaddr_in6 *addr6 = (const struct sockaddr_in6*)interface->ifa_addr;
                            if (inet_ntop(AF_INET6, &addr6->sin6_addr, addrBuf, INET6_ADDRSTRLEN)) {
                                
                            }
                        }
                    }
                }
            }
            freeifaddrs(interfaces);
        }
        return ipv4Address;
    }
    if ([key isEqualToString:kMewEthernetIPv6Address]) {
        NSString *ipv6Address = nil;
        struct ifaddrs *interfaces;
        if(!getifaddrs(&interfaces)) {
            struct ifaddrs *interface;
            for (interface = interfaces; interface; interface = interface->ifa_next) {
                if(!(interface->ifa_flags & IFF_UP) /* || (interface->ifa_flags & IFF_LOOPBACK) */ ) {
                    continue;
                }
                const struct sockaddr_in *addr = (const struct sockaddr_in*)interface->ifa_addr;
                char addrBuf[ MAX(INET_ADDRSTRLEN, INET6_ADDRSTRLEN) ];
                if (strstr(interface->ifa_name, "en")) {
                    if (addr && (addr->sin_family == AF_INET || addr->sin_family == AF_INET6)) {
                        if (addr->sin_family == AF_INET) {
                            if (inet_ntop(AF_INET, &addr->sin_addr, addrBuf, INET_ADDRSTRLEN)) {
                                
                            }
                        } else {
                            const struct sockaddr_in6 *addr6 = (const struct sockaddr_in6*)interface->ifa_addr;
                            if (inet_ntop(AF_INET6, &addr6->sin6_addr, addrBuf, INET6_ADDRSTRLEN)) {
                                ipv6Address = [NSString stringWithUTF8String:addrBuf];
                            }
                        }
                    }
                }
            }
            freeifaddrs(interfaces);
        }
        return ipv6Address;
    }
    if ([key isEqualToString:kMewEthernetSSID] || [key isEqualToString:kMewEthernetBSSID]) {
        NSString *answer = nil;
        void *frameworkSystemConfiguration = dlopen("/System/Library/Frameworks/SystemConfiguration.framework/SystemConfiguration", RTLD_LAZY);
        if (frameworkSystemConfiguration) {
            CFArrayRef (* CNCopySupportedInterfaces)(void) = dlsym(frameworkSystemConfiguration, "CNCopySupportedInterfaces");
            CFDictionaryRef (* CNCopyCurrentNetworkInfo) (CFStringRef interfaceName) = dlsym(frameworkSystemConfiguration, "CNCopyCurrentNetworkInfo");
            NSDictionary *networkDictionary = nil;
            NSArray *ifs = (__bridge id)CNCopySupportedInterfaces();
            for (NSString *ifname in ifs) {
                if ([ifname rangeOfString:@"en"].location != NSNotFound) {
                    networkDictionary = (__bridge id)CNCopyCurrentNetworkInfo((__bridge CFStringRef)ifname);
                }
            }
            if (networkDictionary) {
                if ([key isEqualToString:kMewEthernetSSID]) {
                    answer = networkDictionary[@"SSID"];
                }
                else {
                    answer = networkDictionary[@"BSSID"];
                }
            }
            dlclose(frameworkSystemConfiguration);
        }
        return answer;
    }
    if ([key isEqualToString:kMewCurrentMobileId] || [key isEqualToString:kMewCurrentSubscriberId] || [key isEqualToString:kMewICCID] ||
             [key isEqualToString:kMewMEID] || [key isEqualToString:kMewIMSI] || [key isEqualToString:kMewInternationalMobileEquipmentIdentity]
             ) {
        NSString *answer = nil;
        void *frameworkCoreTelephony = dlopen("/System/Library/Frameworks/CoreTelephony.framework/CoreTelephony", RTLD_LAZY);
        if (frameworkCoreTelephony) {
            struct CTServerConnection * (* _CTServerConnectionCreate)(CFAllocatorRef, void *, int *) = dlsym(frameworkCoreTelephony, "_CTServerConnectionCreate");
            int * (* _CTServerConnectionCopyMobileIdentity)(struct CTResult *, struct CTServerConnection *, CFStringRef *) = dlsym(frameworkCoreTelephony, "_CTServerConnectionCopyMobileIdentity");
            int * (* _CTServerConnectionCopyMobileEquipmentInfo)(struct CTResult *, struct CTServerConnection *, CFMutableDictionaryRef *) = dlsym(frameworkCoreTelephony, "_CTServerConnectionCopyMobileEquipmentInfo");
            struct CTServerConnection * sc = _CTServerConnectionCreate(kCFAllocatorDefault, nil, NULL);
            struct CTResult result;
            CFMutableDictionaryRef dict = nil;
            _CTServerConnectionCopyMobileEquipmentInfo(&result, sc, &dict);
            if (dict) {
                NSDictionary *resultDictionary = CFBridgingRelease(dict);
                if ([key isEqualToString:kMewCurrentMobileId]) {
                    answer = resultDictionary[kCTMobileEquipmentInfoCurrentMobileId];
                } else if ([key isEqualToString:kMewCurrentSubscriberId]) {
                    answer = resultDictionary[kCTMobileEquipmentInfoCurrentSubscriberId];
                } else if ([key isEqualToString:kMewICCID]) {
                    answer = resultDictionary[kCTMobileEquipmentInfoICCID];
                } else if ([key isEqualToString:kMewMEID]) {
                    answer = resultDictionary[kCTMobileEquipmentInfoMEID];
                } else if ([key isEqualToString:kMewIMSI]) {
                    answer = resultDictionary[kCTMobileEquipmentInfoIMSI];
                } else if ([key isEqualToString:kMewInternationalMobileEquipmentIdentity]) {
                    CFStringRef imei = nil;
                    _CTServerConnectionCopyMobileIdentity(&result, sc, &imei);
                    if (imei) {
                        answer = CFBridgingRelease(imei);
                    } else {
                        answer = resultDictionary[kCTMobileEquipmentInfoIMEI];
                    }
                }
            }
            dlclose(frameworkCoreTelephony);
        }
        return answer;
    }
    if ([key isEqualToString:kMewInternationalMobileEquipmentIdentity]) {
        NSString *imeiString = nil;
        if (!imeiString) {
            void *IOKit = dlopen("/System/Library/Frameworks/IOKit.framework/IOKit", RTLD_GLOBAL | RTLD_LAZY);
            if (IOKit) {
                mach_port_t *kIOMasterPortDefault = dlsym(IOKit, "kIOMasterPortDefault");
                CFMutableDictionaryRef (*IOServiceMatching)(const char *name) = dlsym(IOKit, "IOServiceMatching");
                mach_port_t (*IOServiceGetMatchingService)(mach_port_t masterPort, CFDictionaryRef matching) = dlsym(IOKit, "IOServiceGetMatchingService");
                CFTypeRef (*IORegistryEntryCreateCFProperty)(mach_port_t entry, CFStringRef key, CFAllocatorRef allocator, uint32_t options) = dlsym(IOKit, "IORegistryEntryCreateCFProperty");
                kern_return_t (*IOObjectRelease)(mach_port_t object) = dlsym(IOKit, "IOObjectRelease");
                if (kIOMasterPortDefault && IOServiceGetMatchingService && IORegistryEntryCreateCFProperty && IOObjectRelease)
                {
                    mach_port_t platformExpertDevice = IOServiceGetMatchingService(*kIOMasterPortDefault, IOServiceMatching("IOPlatformExpertDevice"));
                    if (platformExpertDevice)
                    {
                        CFTypeRef imei = IORegistryEntryCreateCFProperty(platformExpertDevice, CFSTR("device-imei"), kCFAllocatorDefault, 0);
                        if (imei && CFGetTypeID(imei) == CFStringGetTypeID())
                        {
                            imeiString = CFBridgingRelease(imei);
                        }
                        IOObjectRelease(platformExpertDevice);
                    }
                }
                dlclose(IOKit);
            }
        }
        return imeiString;
    }
    
    
    return nil;
}

- (BOOL)cleanSystemKeychainWithError:(NSError **)error {
    struct sqlite3 *db = NULL;
    char *msgBuf = NULL;
    NSString *db_path = @"/var/Keychains/keychain-2.db";
    sqlite3_open([db_path UTF8String], &db);
    if (!db) {
        *error = [NSError errorWithDomain:@"com.darwindev.MewApp.error"
                                     code:0
                                 userInfo:@{
                                            NSLocalizedDescriptionKey: [NSString stringWithFormat:@"Cannot open %@", db_path]
                                            }];
        return NO;
    }
    for (NSUInteger step = 0; step < 5; step++) {
        switch (step) {
            case 0:
                sqlite3_exec(db, "DELETE FROM genp WHERE agrp<>'apple'", NULL, NULL, &msgBuf);
                break;
            case 1:
                sqlite3_exec(db, "DELETE FROM cert WHERE agrp<>'lockdown-identities'", NULL, NULL, &msgBuf);
                break;
            case 2:
                sqlite3_exec(db, "DELETE FROM keys WHERE agrp<>'lockdown-identities'", NULL, NULL, &msgBuf);
                break;
            case 3:
                sqlite3_exec(db, "DELETE FROM inet", NULL, NULL, &msgBuf);
                break;
            case 4:
                sqlite3_exec(db, "DELETE FROM sqlite_sequence", NULL, NULL, &msgBuf);
                break;
            default:
                break;
        }
        if (msgBuf) {
            break;
        }
    }
    sqlite3_close(db);
    if (msgBuf) {
        if (error) {
            NSString *reason = [[NSString alloc] initWithUTF8String:msgBuf];
            if (reason) {
                *error = [NSError errorWithDomain:@"com.darwindev.MewApp.error"
                                             code:0
                                         userInfo:@{
                                                    NSLocalizedDescriptionKey: reason
                                                        }];
            }
        }
        return NO;
    } else {
        return YES;
    }
}

@end
