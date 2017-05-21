//
//  MEWSharedUtility.m
//  MewApp
//
//  Created by Zheng on 10/05/2017.
//  Copyright © 2017 Zheng. All rights reserved.
//



#import "MEWSharedUtility.h"
#import "LSApplicationProxy.h"
#import "MobileGestalt.h"
#import <dlfcn.h>
#import <net/if.h>
#import <sqlite3.h>
#import <ifaddrs.h>
#import <sys/stat.h>
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
    
    if ([key isEqualToString:kMewEncDeviceName]) {
        return [self MGCopyAnswer:kMGUserAssignedDeviceName];
    }
    else if ([key isEqualToString:kMewEncDeviceCategory]) {
        return [self MGCopyAnswer:kMGDeviceName];
    }
    else if ([key isEqualToString:kMewEncProductType]) {
        return [self MGCopyAnswer:kMGProductType];
    }
    else if ([key isEqualToString:kMewEncProductHWModel]) {
        return [self MGCopyAnswer:kMGHWModel];
    }
    else if ([key isEqualToString:kMewEncProductModel]) {
        return [self MGCopyAnswer:kMGModelNumber];
    }
    else if ([key isEqualToString:kMewEncSerialNumber]) {
        return [self MGCopyAnswer:kMGSerialNumber];
    }
    else if ([key isEqualToString:kMewEncMLBSerialNumber]) {
        return [self MGCopyAnswer:kMGMLBSerialNumber];
    }
    else if ([key isEqualToString:kMewEncBluetoothAddress]) {
        return [self MGCopyAnswer:kMGBluetoothAddress];
    }
    else if ([key isEqualToString:kMewEncSystemName]) {
        return [self MGCopyAnswer:kMGProductName];
    }
    else if ([key isEqualToString:kMewEncSystemVersion]) {
        return [self MGCopyAnswer:kMGProductVersion];
    }
    else if ([key isEqualToString:kMewEncSystemBuildVersion]) {
        return [self MGCopyAnswer:kMGBuildVersion];
    }
    else if ([key isEqualToString:kMewEncUniqueIdentifier]) {
        if (XXT_SYSTEM_8) {
            return @"";
        } else {
            return [[UIDevice currentDevice] performSelector:@selector(uniqueIdentifier)];
        }
    }
    else if ([key isEqualToString:kMewEncUniqueDeviceID]) {
        return [self MGCopyAnswer:kMGUniqueDeviceID];
    }
    else if ([key isEqualToString:kMewEncUniqueChipID]) {
        return [self MGCopyAnswer:kMGUniqueChipID];
    }
    else if ([key isEqualToString:kMewEncInverseDeviceID]) {
        return [self MGCopyAnswer:kMGInverseDeviceID];
    }
    else if ([key isEqualToString:kMewEncIdentifierForVendor]) {
        return [[[UIDevice currentDevice] identifierForVendor] UUIDString];
    }
    else if ([key isEqualToString:kMewEncAdvertisingIdentifier]) {
        void *frameworkAdSupport = dlopen("/System/Library/Frameworks/AdSupport.framework/AdSupport", RTLD_NOW);
        if (frameworkAdSupport) {
            id answer = [[[objc_getClass("ASIdentifierManager") performSelector:@selector(sharedManager)] performSelector:@selector(advertisingIdentifier)] performSelector:@selector(UUIDString)];
            dlclose(frameworkAdSupport);
            return answer;
        }
    }
    else if ([key isEqualToString:kMewEncDeviceBatteryState]) {
        return @([[UIDevice currentDevice] batteryState]);
    }
    else if ([key isEqualToString:kMewEncScreenBrightness]) {
        return @([[UIScreen mainScreen] brightness]);
    }
    else if ([key isEqualToString:kMewEncEthernetMacAddress]) {
        return [self MGCopyAnswer:kMGWifiAddress];
    }
    else if ([key isEqualToString:kMewEncRegionCode]) {
        return [self MGCopyAnswer:kMGRegionCode];
    }
    else if ([key isEqualToString:kMewEncRegionInfo]) {
        return [self MGCopyAnswer:kMGRegionInfo];
    }
    else if ([key isEqualToString:kMewEncOpenUDIDValue]) {
        return [MEWOpenUDID value];
    }
    else if ([key isEqualToString:kMewEncTimezoneName]) {
        NSTimeZone *timeZone = [NSTimeZone localTimeZone];
        return [timeZone name];
    }
    else if ([key isEqualToString:kMewEncTimezoneData]) {
        NSTimeZone *timeZone = [NSTimeZone localTimeZone];
        return [timeZone data];
    }
    else if ([key isEqualToString:kMewEncLastLaunchTime]) {
        return @([[NSDate date] timeIntervalSince1970]);
    }
    if ([key isEqualToString:kMewEncEthernetIPv4Address]) {
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
    if ([key isEqualToString:kMewEncEthernetIPv6Address]) {
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
    if ([key isEqualToString:kMewEncEthernetSSID] || [key isEqualToString:kMewEncEthernetBSSID] || [key isEqualToString:kMewEncEthernetRSSID]) {
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
                if ([key isEqualToString:kMewEncEthernetSSID]) {
                    answer = networkDictionary[@"SSID"];
                }
                else if ([key isEqualToString:kMewEncEthernetBSSID]) {
                    answer = networkDictionary[@"BSSID"];
                }
                else if ([key isEqualToString:kMewEncEthernetRSSID]) {
                    answer = networkDictionary[@"RSSID"];
                }
            }
            dlclose(frameworkSystemConfiguration);
        }
        return answer;
    }
    if ([key isEqualToString:kMewEncCurrentMobileId] || [key isEqualToString:kMewEncCurrentSubscriberId] || [key isEqualToString:kMewEncICCID] ||
             [key isEqualToString:kMewEncMEID] || [key isEqualToString:kMewEncIMSI] || [key isEqualToString:kMewEncInternationalMobileEquipmentIdentity]
             ) {
        NSString *answer = nil;
        void *frameworkCoreTelephony = dlopen("/System/Library/Frameworks/CoreTelephony.framework/CoreTelephony", RTLD_LAZY);
        if (frameworkCoreTelephony) {
            struct CTServerConnection * (* _CTServerConnectionCreate)(CFAllocatorRef, void *, int *) = dlsym(frameworkCoreTelephony, "_CTServerConnectionCreate");
            int * (* _CTServerConnectionCopyMobileIdentity)(struct CTResult *, struct CTServerConnection *, CFStringRef *) = dlsym(frameworkCoreTelephony, "_CTServerConnectionCopyMobileIdentity");
#ifdef __arm64__
            int * (* _CTServerConnectionCopyMobileEquipmentInfo)(struct CTServerConnection *, CFMutableDictionaryRef *, NSInteger *) = dlsym(frameworkCoreTelephony, "_CTServerConnectionCopyMobileEquipmentInfo");
#else
            int * (* _CTServerConnectionCopyMobileEquipmentInfo)(struct CTResult *, struct CTServerConnection *, CFMutableDictionaryRef *) = dlsym(frameworkCoreTelephony, "_CTServerConnectionCopyMobileEquipmentInfo");
#endif
            
            struct CTServerConnection * sc = _CTServerConnectionCreate(kCFAllocatorDefault, nil, NULL);
            struct CTResult result;
            CFMutableDictionaryRef dict = nil;
#ifdef __arm64__
            _CTServerConnectionCopyMobileEquipmentInfo(sc, &dict, NULL);
#else
            _CTServerConnectionCopyMobileEquipmentInfo(&result, sc, &dict);
#endif
            if (dict) {
                NSDictionary *resultDictionary = CFBridgingRelease(dict);
                if ([key isEqualToString:kMewEncCurrentMobileId]) {
                    answer = resultDictionary[kMewEncCTMobileEquipmentInfoCurrentMobileId];
                } else if ([key isEqualToString:kMewEncCurrentSubscriberId]) {
                    answer = resultDictionary[kMewEncCTMobileEquipmentInfoCurrentSubscriberId];
                } else if ([key isEqualToString:kMewEncICCID]) {
                    answer = resultDictionary[kMewEncCTMobileEquipmentInfoICCID];
                } else if ([key isEqualToString:kMewEncMEID]) {
                    answer = resultDictionary[kMewEncCTMobileEquipmentInfoMEID];
                } else if ([key isEqualToString:kMewEncIMSI]) {
                    answer = resultDictionary[kMewEncCTMobileEquipmentInfoIMSI];
                } else if ([key isEqualToString:kMewEncInternationalMobileEquipmentIdentity]) {
                    CFStringRef imei = nil;
                    _CTServerConnectionCopyMobileIdentity(&result, sc, &imei);
                    if (imei) {
                        answer = CFBridgingRelease(imei);
                    } else {
                        answer = resultDictionary[kMewEncCTMobileEquipmentInfoIMEI];
                    }
                }
            }
            dlclose(frameworkCoreTelephony);
        }
        return answer;
    }
    if ([key isEqualToString:kMewEncInternationalMobileEquipmentIdentity]) {
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

- (void)cleanSafariCaches {
    mew_exec((char *[]){"MEWDo", "/usr/bin/killall", "-9", "MobileSafari", "Preferences", NULL});
    mew_exec((char *[]){"MEWDo", "/bin/rm", "-rf", "/private/var/mobile/Library/Caches/com.apple.mobilesafari", NULL});
    mew_exec((char *[]){"MEWDo", "/bin/rm", "-rf", "/private/var/mobile/Library/Caches/Safari", NULL});
    mew_exec((char *[]){"MEWDo", "/bin/rm", "-rf", "/private/var/mobile/Library/WebKit", NULL});
    mew_exec((char *[]){"MEWDo", "/bin/rm", "/private/var/mobile/Library/Cookies/Cookies.binarycookies", NULL});
    mew_exec((char *[]){"MEWDo", "/bin/rm", "/private/var/root/Library/Cookies/Cookies.binarycookies", NULL});
    mew_exec((char *[]){"MEWDo", "/bin/rm", "/private/var/mobile/Library/Safari/History.plist", NULL});
    mew_exec((char *[]){"MEWDo", "/bin/rm", "/private/var/mobile/Library/Safari/SuspendState.plist", NULL});
    mew_exec((char *[]){"MEWDo", "/bin/rm", "/private/var/mobile/Library/Safari/RecentSearches.plist", NULL});
    mew_exec((char *[]){"MEWDo", "/bin/rm", "/private/var/mobile/Library/Safari/SyncedTabsMetadata.plist", NULL});
    
    NSString *safariContainer = nil;
    Class LSApplicationWorkspace_class = objc_getClass("LSApplicationWorkspace");
    SEL selector = NSSelectorFromString(@"defaultWorkspace");
    NSObject *workspace = [LSApplicationWorkspace_class performSelector:selector];
    SEL selectorAll = NSSelectorFromString(@"allInstalledApplications");
    NSArray <LSApplicationProxy *> *allApplications = [workspace performSelector:selectorAll];
    for (LSApplicationProxy *appProxy in allApplications) {
        if ([[appProxy applicationIdentifier] isEqualToString:@"com.apple.mobilesafari"]) {
            if (XXT_SYSTEM_8) {
                safariContainer = [[appProxy dataContainerURL] path];
            } else {
                safariContainer = [[appProxy containerURL] path];
            }
            break;
        }
    }
    if (safariContainer) {
        struct stat container_s;
        stat([safariContainer UTF8String], &container_s);
        if (S_ISDIR(container_s.st_mode)) {
            mew_exec((char *[]){"MEWDo", "/bin/rm", "-rf", (char *)[[NSString stringWithFormat:@"%@/Library/Caches/com.apple.mobilesafari", safariContainer] UTF8String], NULL});
            mew_exec((char *[]){"MEWDo", "/bin/rm", "-rf", (char *)[[NSString stringWithFormat:@"%@/Library/Caches/Safari", safariContainer] UTF8String], NULL});
            mew_exec((char *[]){"MEWDo", "/bin/rm", "-rf", (char *)[[NSString stringWithFormat:@"%@/Library/WebKit", safariContainer] UTF8String], NULL});
            mew_exec((char *[]){"MEWDo", "/bin/rm", (char *)[[NSString stringWithFormat:@"%@/Library/Cookies/Cookies.binarycookies", safariContainer] UTF8String], NULL});
            mew_exec((char *[]){"MEWDo", "/bin/rm", (char *)[[NSString stringWithFormat:@"%@/Library/Safari/History.plist", safariContainer] UTF8String], NULL});
            mew_exec((char *[]){"MEWDo", "/bin/rm", (char *)[[NSString stringWithFormat:@"%@/Library/Safari/SuspendState.plist", safariContainer] UTF8String], NULL});
            mew_exec((char *[]){"MEWDo", "/bin/rm", (char *)[[NSString stringWithFormat:@"%@/Library/Safari/RecentSearches.plist", safariContainer] UTF8String], NULL});
            mew_exec((char *[]){"MEWDo", "/bin/rm", (char *)[[NSString stringWithFormat:@"%@/Library/Safari/SyncedTabsMetadata.plist", safariContainer] UTF8String], NULL});
        }
    }
}

- (void)cleanSystemKeychain {
    [self cleanSystemKeychainWithError:nil];
}

- (BOOL)cleanSystemKeychainWithError:(NSError **)error {
    struct sqlite3 *db = NULL;
    char *msgBuf = NULL;
    NSString *db_path = @"/private/var/Keychains/keychain-2.db";
    sqlite3_open([db_path UTF8String], &db);
    if (!db) {
        *error = [NSError errorWithDomain:kMewEncErrorDomain
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
                *error = [NSError errorWithDomain:kMewEncErrorDomain
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

- (void)cleanAllPasteboard {
//    mew_exec((char *[]){ "MEWDo", "/bin/launchctl", "unload", "-w", "/System/Library/LaunchDaemons/com.apple.UIKit.pasteboardd.plist", NULL });
    system("/Applications/MewApp.app/MEWDo /bin/launchctl unload -w /System/Library/LaunchDaemons/com.apple.UIKit.pasteboardd.plist");
    mew_exec((char *[]){ "MEWDo", "/bin/rm", "-rf", "/private/var/mobile/Library/Caches/com.apple.UIKit.pboard/*", NULL });
//    mew_exec((char *[]){ "MEWDo", "/bin/launchctl", "load", "-w", "/System/Library/LaunchDaemons/com.apple.UIKit.pasteboardd.plist", NULL });
    system("/Applications/MewApp.app/MEWDo /bin/launchctl load -w /System/Library/LaunchDaemons/com.apple.UIKit.pasteboardd.plist");
    UIPasteboard *pb = [UIPasteboard generalPasteboard];
    for (NSString *pasteboardType in [pb pasteboardTypes]) {
        [pb setValue:@"" forPasteboardType:pasteboardType];
    }
}

- (void)cleanUICache {
    mew_exec((char *[]){ "MEWDo", "/bin/su", "mobile", "-c", "/usr/bin/uicache", NULL });
}

- (void)respringDevice {
    mew_exec((char *[]){ "MEWDo", "/usr/bin/killall", "-9", "backboardd", "Springboard", NULL });
}

/*
 lrwxr-xr-x 1 mobile mobile  64 May  9 03:23 .GlobalPreferences.plist -> /private/var/mobile/Library/Preferences/.GlobalPreferences.plist
 lrwxr-xr-x 1 mobile mobile  68 May  9 03:23 com.apple.PeoplePicker.plist -> /private/var/mobile/Library/Preferences/com.apple.PeoplePicker.plist
 */

- (void)cleanApplicationContainer
{
    Class LSApplicationWorkspace_class = objc_getClass("LSApplicationWorkspace");
    SEL selector = NSSelectorFromString(@"defaultWorkspace");
    NSObject *workspace = [LSApplicationWorkspace_class performSelector:selector];
    SEL selectorAll = NSSelectorFromString(@"allInstalledApplications");
    NSArray <LSApplicationProxy *> *allApplications = [workspace performSelector:selectorAll];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"applicationType = 'User'"];
    NSArray <LSApplicationProxy *> *userApplications = [allApplications filteredArrayUsingPredicate:predicate];
    for (LSApplicationProxy *appProxy in userApplications)
    {
        NSString *applicationIdentifier = [appProxy applicationIdentifier];
        if (applicationIdentifier && applicationIdentifier.length != 0)
        {
            NSString *applicationContainer = nil;
            if (XXT_SYSTEM_8)
            {
                applicationContainer = [[appProxy dataContainerURL] path];
            }
            else
            {
                applicationContainer = [[appProxy containerURL] path];
            }
            if (applicationContainer)
            {
                
                NSString *documentContainer = [applicationContainer stringByAppendingPathComponent:@"Documents"];
                mew_exec((char *[]){ "MEWDo", "/bin/rm", "-rf", (char *)[documentContainer UTF8String], NULL });
                mkdir((char *)[documentContainer UTF8String], 0755);
                
                NSString *libraryContainer = [applicationContainer stringByAppendingPathComponent:@"Library"];
                mew_exec((char *[]){ "MEWDo", "/bin/rm", "-rf", (char *)[libraryContainer UTF8String], NULL });
                mkdir((char *)[libraryContainer UTF8String], 0755);
                
                NSString *storeContainer = [applicationContainer stringByAppendingPathComponent:@"StoreKit"];
                struct stat container_s;
                bzero(&container_s, sizeof(container_s));
                stat([storeContainer UTF8String], &container_s);
                if (S_ISDIR(container_s.st_mode)) {
                    mew_exec((char *[]){ "MEWDo", "/bin/rm", "-rf", (char *)[storeContainer UTF8String], NULL });
                    mkdir((char *)[storeContainer UTF8String], 0755);
                }
                
                NSString *tmpContainer = [applicationContainer stringByAppendingPathComponent:@"tmp"];
                mew_exec((char *[]){ "MEWDo", "/bin/rm", "-rf", (char *)[tmpContainer UTF8String], NULL });
                mkdir((char *)[tmpContainer UTF8String], 0755);
                
                NSString *cacheContainer = [libraryContainer stringByAppendingPathComponent:@"Caches"];
                mkdir((char *)[cacheContainer UTF8String], 0755);
                
                NSString *preferencesContainer = [libraryContainer stringByAppendingPathComponent:@"Preferences"];
                mkdir((char *)[preferencesContainer UTF8String], 0755);
                
                NSString *globalPreferences = [preferencesContainer stringByAppendingPathComponent:@".GlobalPreferences.plist"];
                symlink("/private/var/mobile/Library/Preferences/.GlobalPreferences.plist", [globalPreferences UTF8String]);
                
                NSString *peoplePicker = [preferencesContainer stringByAppendingPathComponent:@"com.apple.PeoplePicker.plist"];
                symlink("/private/var/mobile/Library/Preferences/com.apple.PeoplePicker.plist", [peoplePicker UTF8String]);
                
            }
        }
    }
}

NSString *randomIPV4Address() {
    int type = arc4random() % 2; // netmask 24, private address only
    if (type == 0) {
        return [NSString stringWithFormat:@"%d.%d.%d.%d",
                172,
                16 + (int)(arc4random() % 16),
                0 + (int)(arc4random() % 255),
                1 + (int)(arc4random() % 254)
                ];
    } else {
        return [NSString stringWithFormat:@"%d.%d.%d.%d",
                192,
                168,
                0 + (int)(arc4random() % 255),
                1 + (int)(arc4random() % 254)
                ];
    }
}

NSString *randomIPV6Address() {
    return [NSString stringWithFormat:@"%02x%02x:%02x%02x:%02x%02x:%02x%02x:%02x%02x:%02x%02x:%02x%02x:%02x%02x",
            (int)(arc4random() % 256),
            (int)(arc4random() % 256),
            (int)(arc4random() % 256),
            (int)(arc4random() % 256),
            (int)(arc4random() % 256),
            (int)(arc4random() % 256),
            (int)(arc4random() % 256),
            (int)(arc4random() % 256),
            (int)(arc4random() % 256),
            (int)(arc4random() % 256),
            (int)(arc4random() % 256),
            (int)(arc4random() % 256),
            (int)(arc4random() % 256),
            (int)(arc4random() % 256),
            (int)(arc4random() % 256),
            (int)(arc4random() % 256)
            ];
}

NSString *randomUniqueIdentifier(NSString *vendorId) {
    if (vendorId) {
        return [NSString stringWithFormat:@"FFFFFFFF%@",
                [vendorId stringByReplacingOccurrencesOfString:@"-" withString:@""]
                ];
    } else {
        return [NSString stringWithFormat:@"FFFFFFFF%08X%08X%08X%08X",
                (int)(arc4random() % INT_MAX),
                (int)(arc4random() % INT_MAX),
                (int)(arc4random() % INT_MAX),
                (int)(arc4random() % INT_MAX)
                ];
    }
}

NSArray <NSString *> *randomAddress() {
    int bytes[6] = {
        (int)(arc4random() % 256),
        (int)(arc4random() % 256),
        (int)(arc4random() % 256),
        (int)(arc4random() % 256),
        (int)(arc4random() % 256),
        (int)(arc4random() % 256)
    };
    return @[[NSString stringWithFormat:@"%02x:%02x:%02x:%02x:%02x:%02x", bytes[0], bytes[1], bytes[2], bytes[3], bytes[4], bytes[5]],
             [NSString stringWithFormat:@"%02x:%02x:%02x:%02x:%02x:%02x", bytes[0], bytes[1], bytes[2], bytes[3], bytes[4], bytes[5] + 1],
             [NSString stringWithFormat:@"%02x:%02x:%02x:%02x:%02x:%02x",
              (int)(arc4random() % 256),
              (int)(arc4random() % 256),
              (int)(arc4random() % 256),
              (int)(arc4random() % 256),
              (int)(arc4random() % 256),
              (int)(arc4random() % 256)
              ],
             ];
}

NSString *random40string() {
    return [NSString stringWithFormat:@"%08x%08x%08x%08x%08x",
            (int)(arc4random() % INT_MAX),
            (int)(arc4random() % INT_MAX),
            (int)(arc4random() % INT_MAX),
            (int)(arc4random() % INT_MAX),
            (int)(arc4random() % INT_MAX)
            ];
}

NSString *randomHexString(int count) {
    NSMutableString *string = [NSMutableString stringWithCapacity:(count * 2) + 1];
    for (int i = 0; i < count; i++) {
        [string appendFormat:@"%02X", (int)(arc4random() % 256)];
    }
    return [string copy];
}

NSArray <NSString *> *randomProduct() {
    NSArray <NSArray *> *types = @[
                       @[@"iPhone5,1", @"N41AP", @"MD642"],
                       @[@"iPhone5,2", @"N42AP", @"MD662"],
                       @[@"iPhone5,3", @"N48AP", @"MF153"],
                       @[@"iPhone5,4", @"N49AP", @"MF326"],
                       @[@"iPhone6,1", @"N51AP", @"ME311"],
                       @[@"iPhone6,2", @"N53AP", @"ME438"],
                       @[@"iPhone7,1", @"N56AP", @"MGAP2"],
                       @[@"iPhone7,2", @"N61AP", @"MG6G2"],
                       @[@"iPhone8,1", @"N71AP", @"MKQH2"],
                       @[@"iPhone8,2", @"N66AP", @"MKVJ2"],
                       @[@"iPhone8,4", @"N69AP", @"MP9E2"],
                       @[@"iPhone9,1", @"D10AP", @"MNCD2"],
                       @[@"iPhone9,2", @"D11AP", @"MNFY2"],
                       @[@"iPhone9,3", @"D101AP", @"MN9P2"],
                       @[@"iPhone9,4", @"D111AP", @"MN4W2"],
                       ];
    return types[(int)(arc4random() % types.count)];
}

NSString *randomDashString() {
    return [NSString stringWithFormat:@"%02X%02X%02X%02X-%02X%02X-%02X%02X-%02X%02X-%02X%02X%02X%02X%02X%02X",
            (int)(arc4random() % 256),
            (int)(arc4random() % 256),
            (int)(arc4random() % 256),
            (int)(arc4random() % 256),
            (int)(arc4random() % 256),
            (int)(arc4random() % 256),
            (int)(arc4random() % 256),
            (int)(arc4random() % 256),
            (int)(arc4random() % 256),
            (int)(arc4random() % 256),
            (int)(arc4random() % 256),
            (int)(arc4random() % 256),
            (int)(arc4random() % 256),
            (int)(arc4random() % 256),
            (int)(arc4random() % 256),
            (int)(arc4random() % 256)
            ];
}

NSString *randomDeviceName() {
    return [NSString stringWithFormat:@"iPhone (%d)",
            (int)(arc4random() % 256)
            ];
}

NSString *randomSerialNumber(int count, bool numeric) { // F78MJE98G07V, C7H41510PKRFM7LBG
    NSMutableString *serial = [NSMutableString stringWithCapacity:count + 1];
    for (int i = 0; i < count; i++) {
        char c;
        int alpha = (int)(arc4random() % 2);
        if (numeric) {
            alpha = 1;
        }
        if (alpha == 0) {
            c = 'A' + (int)(arc4random() % 26);
        } else {
            c = '0' + (int)(arc4random() % 10);
        }
        [serial appendFormat:@"%c", c];
    }
    return [serial copy];
}

NSArray *randomCarrier() {
    NSArray *carriers = @[
                          @[@"中国移动", @"898600", @"46000", @"00"],
                          @[@"中国联通", @"898601", @"46001", @"01"],
                          @[@"中国电信", @"898603", @"46011", @"03"]
                          ];
    return carriers[(int)(arc4random() % carriers.count)];
}

NSString *randomSSID() {
    return [NSString stringWithFormat:@"TP-Link_%02X%02X%02X",
            (int)(arc4random() % 256),
            (int)(arc4random() % 256),
            (int)(arc4random() % 256)
            ];
}

static NSArray <NSString *> *kStaticProduct = nil;
static NSString *kStaticVendorIdentifer = nil;
static NSArray <NSString *> *kStaticMacArray = nil;
static NSArray *kStaticCarrier = nil;

- (id)randomAnswerForKey:(NSString *)key {
    id answer = nil;
    if ([key isEqualToString:kMewEncEthernetIPv4Address]) {
        answer = randomIPV4Address();
    }
    else if ([key isEqualToString:kMewEncEthernetIPv6Address]) {
        answer = randomIPV6Address();
    }
    else if ([key isEqualToString:kMewEncUniqueIdentifier]) {
        answer = randomUniqueIdentifier(kStaticVendorIdentifer);
    }
    else if ([key isEqualToString:kMewEncOpenUDIDValue]) {
        answer = random40string();
    }
    else if ([key isEqualToString:kMewEncInverseDeviceID]) {
        answer = random40string();
    }
    else if ([key isEqualToString:kMewEncUniqueDeviceID]) {
        answer = random40string();
    }
    else if ([key isEqualToString:kMewEncIdentifierForVendor]) {
        answer = kStaticVendorIdentifer;
    }
    else if ([key isEqualToString:kMewEncDeviceName]) {
        answer = randomDeviceName();
    }
    else if ([key isEqualToString:kMewEncSerialNumber]) {
        answer = randomSerialNumber(12, false);
    }
    else if ([key isEqualToString:kMewEncProductType]) {
        answer = kStaticProduct[0];
    }
    else if ([key isEqualToString:kMewEncProductHWModel]) {
        answer = kStaticProduct[1];
    }
    else if ([key isEqualToString:kMewEncProductModel]) {
        answer = kStaticProduct[2];
    }
    else if ([key isEqualToString:kMewEncEthernetMacAddress]) {
        answer = kStaticMacArray[0];
    }
    else if ([key isEqualToString:kMewEncBluetoothAddress]) {
        answer = kStaticMacArray[1];
    }
    else if ([key isEqualToString:kMewEncEthernetBSSID]) {
        answer = kStaticMacArray[2];
    }
    else if ([key isEqualToString:kMewEncMLBSerialNumber]) {
        answer = randomSerialNumber(17, false);
    }
    else if ([key isEqualToString:kMewEncUniqueChipID]) {
        answer = randomSerialNumber(12, true);
    }
    else if ([key isEqualToString:kMewEncServiceString]) {
        answer = kStaticCarrier[0];
    }
    else if ([key isEqualToString:kMewEncCarrierName]) {
        answer = kStaticCarrier[0];
    }
    else if ([key isEqualToString:kMewEncICCID]) {
        answer = [kStaticCarrier[1] stringByAppendingString:randomSerialNumber(14, true)];
    }
    else if ([key isEqualToString:kMewEncIMSI]) {
        answer = [kStaticCarrier[2] stringByAppendingString:randomSerialNumber(10, true)];
    }
    else if ([key isEqualToString:kMewEncNetworkCode]) {
        answer = kStaticCarrier[3];
    }
    else if ([key isEqualToString:kMewEncCountryCode]) {
        answer = @"460";
    }
    else if ([key isEqualToString:kMewEncISOCountryCode]) {
        answer = @"156";
    }
    else if ([key isEqualToString:kMewEncRegionCode]) {
        answer = @"CH";
    }
    else if ([key isEqualToString:kMewEncRegionInfo]) {
        answer = @"CH/A";
    }
    else if ([key isEqualToString:kMewEncDeviceCategory]) {
        answer = @"iPhone";
    }
    else if ([key isEqualToString:kMewEncSystemName]) {
        answer = @"iPhone OS";
    }
    else if ([key isEqualToString:kMewEncAdvertisingIdentifier]) {
        answer = randomDashString();
    }
    else if ([key isEqualToString:kMewEncMEID]) {
        answer = randomHexString(7);
    }
    else if ([key isEqualToString:kMewEncInternationalMobileEquipmentIdentity]) {
        answer = randomSerialNumber(15, true);
    }
    else if ([key isEqualToString:kMewEncEthernetSSID]) {
        answer = randomSSID();
    }
    
    return answer;
}

- (void)randomFake {
    kStaticProduct = randomProduct();
    kStaticVendorIdentifer = randomDashString();
    kStaticMacArray = randomAddress();
    kStaticCarrier = randomCarrier();
    NSDictionary *defaultConfig = [[NSDictionary alloc] initWithContentsOfFile:[[NSBundle mainBundle] pathForResource:kMewEncBundleID ofType:@"plist"]];
    [defaultConfig enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
        id answer = [self randomAnswerForKey:key];
        if (answer) {
            S(key, answer);
        }
    }];
}

- (void)makeBackup {
    
    // [1] Backup Directory
    NSString *backupRootPath = kMewEncBackupPath;
    const char *backup_root_p = [backupRootPath UTF8String];
    mkdir(backup_root_p, 0755);
    struct stat backup_root_s;
    bzero(&backup_root_s, sizeof(struct stat));
    lstat(backup_root_p, &backup_root_s);
    assert(S_ISDIR(backup_root_s.st_mode));
    
    // [2] Unique Directory
    NSUUID *backupID = [NSUUID UUID];
    NSString *backupPath = [backupRootPath stringByAppendingPathComponent:[backupID UUIDString]];
    const char *backup_p = [backupPath UTF8String];
    mkdir(backup_p, 0755);
    struct stat backup_s;
    bzero(&backup_s, sizeof(struct stat));
    lstat(backup_p, &backup_s);
    assert(S_ISDIR(backup_s.st_mode));
    
    // [3] Create Backup Attached Info
    
    // Pasteboard
    NSString *pasteboardBackupPath = [backupPath stringByAppendingPathComponent:@"Pasteboard"];
    const char *pasteboard_p = [pasteboardBackupPath UTF8String];
    mkdir(pasteboard_p, 0755);
    struct stat pasteboard_s;
    bzero(&pasteboard_s, sizeof(struct stat));
    lstat(pasteboard_p, &pasteboard_s);
    assert(S_ISDIR(pasteboard_s.st_mode));
    mew_exec((char *[]){ "MEWDo", "/bin/cp", "-ax", "/private/var/mobile/Library/Caches/com.apple.UIKit.pboard", (char *)pasteboard_p, NULL });
    
    // Keychain
    NSString *keychainBackupPath = [backupPath stringByAppendingPathComponent:@"Keychain"];
    const char *keychain_p = [keychainBackupPath UTF8String];
    mkdir(keychain_p, 0755);
    struct stat keychain_s;
    bzero(&keychain_s, sizeof(struct stat));
    lstat(keychain_p, &keychain_s);
    assert(S_ISDIR(keychain_s.st_mode));
    mew_exec((char *[]){ "MEWDo", "/bin/cp", "-ax", "/private/var/Keychains", (char *)keychain_p, NULL });
    
    // Fake Configuration
    NSString *configPath = kMewEncConfigPath;
    const char *config_p = [configPath UTF8String];
    struct stat config_s;
    bzero(&config_s, sizeof(struct stat));
    lstat(config_p, &config_s);
    assert(S_ISREG(config_s.st_mode));
    mew_exec((char *[]){ "MEWDo", "/bin/cp", "-ax", (char *)[kMewEncConfigPath UTF8String], (char *)backup_p, NULL });
    
    // [4] Move Application Data
    NSUInteger applicationCount = 0;
    
    NSArray <NSString *> *whitelist = R(kMewEncApplicationIdentifierWhiteList);
    if (!whitelist || whitelist.count == 0)
    {
        return;
    }
    Class LSApplicationWorkspace_class = objc_getClass("LSApplicationWorkspace");
    SEL selector = NSSelectorFromString(@"defaultWorkspace");
    NSObject *workspace = [LSApplicationWorkspace_class performSelector:selector];
    SEL selectorAll = NSSelectorFromString(@"allInstalledApplications");
    NSArray <LSApplicationProxy *> *allApplications = [workspace performSelector:selectorAll];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"applicationType = 'User'"];
    NSArray <LSApplicationProxy *> *userApplications = [allApplications filteredArrayUsingPredicate:predicate];
    for (LSApplicationProxy *appProxy in userApplications)
    {
        NSString *applicationIdentifier = [appProxy applicationIdentifier];
        BOOL enabledApplication = NO;
        for (NSString *enabledApp in whitelist) {
            if ([enabledApp isKindOfClass:[NSString class]]) {
                if ([enabledApp isEqualToString:applicationIdentifier]) {
                    enabledApplication = YES;
                }
            }
        }
        if (!enabledApplication) {
            continue;
        }
        if (applicationIdentifier && applicationIdentifier.length != 0)
        {
            NSString *applicationContainer = nil;
            if (XXT_SYSTEM_8)
            {
                applicationContainer = [[appProxy dataContainerURL] path];
            }
            else
            {
                applicationContainer = [[appProxy containerURL] path];
            }
            if (applicationContainer)
            {
                NSString *applicationBackupContainer = [backupPath stringByAppendingPathComponent:applicationIdentifier];
                const char *application_p = [applicationBackupContainer UTF8String];
                mkdir(application_p, 0755);
                struct stat application_s;
                bzero(&application_s, sizeof(struct stat));
                lstat(application_p, &application_s);
                assert(S_ISDIR(application_s.st_mode));
                
                NSArray <NSString *> *backupTargets
                = @[
                    @"Documents", @"Library", @"StoreKit", @"tmp"
                    ];
                for (NSString *backupTarget in backupTargets) {
                    
                    NSString *sourcePath = [applicationContainer stringByAppendingPathComponent:backupTarget];
                    NSString *destPath = [applicationBackupContainer stringByAppendingPathComponent:backupTarget];
                    BOOL isLibrary = [backupTarget isEqualToString:@"Library"];
                    const char *source_p = [sourcePath UTF8String];
                    const char *dest_p = [destPath UTF8String];
                    
                    struct stat source_s;
                    bzero(&source_s, sizeof(struct stat));
                    lstat(source_p, &source_s);
                    
                    if (S_ISDIR(source_s.st_mode)) { // first time
                        
                        // move
                        mew_exec((char *[]){ "MEWDo", "/bin/mv", "-f", (char *)source_p, (char *)dest_p, NULL });
                        
                        // check move
                        struct stat dest_s;
                        bzero(&dest_s, sizeof(struct stat));
                        lstat(dest_p, &dest_s);
                        assert(S_ISDIR(dest_s.st_mode));
                        
                        // create
                        mkdir(source_p, 0755);
                        
                        // fill library
                        if (isLibrary) {
                            
                            NSString *libraryContainer = sourcePath;
                            
                            NSString *cacheContainer = [libraryContainer stringByAppendingPathComponent:@"Caches"];
                            const char *cache_p = [cacheContainer UTF8String];
                            mkdir(cache_p, 0755);
                            struct stat cache_s;
                            bzero(&cache_s, sizeof(struct stat));
                            lstat(cache_p, &cache_s);
                            assert(S_ISDIR(cache_s.st_mode));
                            
                            NSString *preferencesContainer = [libraryContainer stringByAppendingPathComponent:@"Preferences"];
                            const char *preferences_p = [preferencesContainer UTF8String];
                            mkdir(preferences_p, 0755);
                            struct stat preferences_s;
                            bzero(&preferences_s, sizeof(struct stat));
                            lstat(preferences_p, &preferences_s);
                            assert(S_ISDIR(preferences_s.st_mode));
                            
                            NSString *globalPreferences = [preferencesContainer stringByAppendingPathComponent:@".GlobalPreferences.plist"];
                            const char *global_p = [globalPreferences UTF8String];
                            symlink("/private/var/mobile/Library/Preferences/.GlobalPreferences.plist", global_p);
                            struct stat global_s;
                            bzero(&global_s, sizeof(struct stat));
                            lstat(global_p, &global_s);
                            assert(S_ISLNK(global_s.st_mode));
                            
                            NSString *peoplePicker = [preferencesContainer stringByAppendingPathComponent:@"com.apple.PeoplePicker.plist"];
                            const char *people_p = [peoplePicker UTF8String];
                            symlink("/private/var/mobile/Library/Preferences/com.apple.PeoplePicker.plist", people_p);
                            struct stat people_s;
                            bzero(&people_s, sizeof(struct stat));
                            lstat(people_p, &people_s);
                            assert(S_ISLNK(people_s.st_mode));
                            
                        }
                        
                        // check create
                        struct stat source_s;
                        bzero(&source_s, sizeof(struct stat));
                        lstat(source_p, &source_s);
                        assert(S_ISDIR(source_s.st_mode));
                        
                    }
                }
                
                applicationCount++;
            }
        }
    }
}

// 0.1-3, allowed version: 0.1-3
- (void)recoverFromBackupPath:(NSString *)backupPath withError:(NSError **)error {
    assert(backupPath != nil);
    NSArray <NSString *> *allowedVersionList = @[@"0.1-3"];
    
    // check meta
    NSString *configPath = [backupPath stringByAppendingPathComponent:kMewEncConfigName];
    NSDictionary *configDict = [[NSDictionary alloc] initWithContentsOfFile:configPath];
    if (configDict && configDict[kMewEncVersion] && [configDict[kMewEncVersion] isKindOfClass:[NSString class]]) {
        BOOL allowed = NO;
        for (NSString *allowedVersion in allowedVersionList) {
            if ([allowedVersion isEqualToString:configDict[kMewEncVersion]]) {
                allowed = YES;
            }
        }
        if (!allowed) {
            if (error) {
                *error = [NSError errorWithDomain:kMewEncErrorDomain code:0 userInfo:@{NSLocalizedDescriptionKey: [NSString stringWithFormat:@"MEW 备份版本不匹配: 不支持 %@ 备份版本。", configDict[kMewEncVersion]]}];
            }
            return;
        }
    } else {
        if (error) {
            *error = [NSError errorWithDomain:kMewEncErrorDomain code:0 userInfo:@{NSLocalizedDescriptionKey: [NSString stringWithFormat:@"无效的备份: %@", backupPath]}];
        }
        return;
    }
    
    // Pasteboard
    NSString *pasteboardBackupPath = [[backupPath stringByAppendingPathComponent:@"Pasteboard"] stringByAppendingPathComponent:@"com.apple.UIKit.pboard"];
    const char *pasteboard_p = [pasteboardBackupPath UTF8String];
    const char *pasteboard_t = "/private/var/mobile/Library/Caches/com.apple.UIKit.pboard";
    struct stat pasteboard_s;
    bzero(&pasteboard_s, sizeof(struct stat));
    lstat(pasteboard_p, &pasteboard_s);
    assert(S_ISDIR(pasteboard_s.st_mode));
    mew_exec((char *[]){ "MEWDo", "/bin/rm", "-rf", (char *)pasteboard_t, NULL });
    mew_exec((char *[]){ "MEWDo", "/bin/cp", "-ax", (char *)pasteboard_p, (char *)pasteboard_t, NULL });
    
    // Check Pasteboard
    struct stat pasteboard_t_s;
    bzero(&pasteboard_t_s, sizeof(struct stat));
    lstat(pasteboard_t, &pasteboard_t_s);
    assert(S_ISDIR(pasteboard_t_s.st_mode));
    
    // Keychain
    NSString *keychainBackupPath = [[backupPath stringByAppendingPathComponent:@"Keychain"] stringByAppendingPathComponent:@"Keychains"];
    const char *keychain_p = [keychainBackupPath UTF8String];
    const char *keychain_t = "/private/var/Keychains";
    struct stat keychain_s;
    bzero(&keychain_s, sizeof(struct stat));
    lstat(keychain_p, &keychain_s);
    assert(S_ISDIR(keychain_s.st_mode));
    mew_exec((char *[]){ "MEWDo", "/bin/rm", "-rf", (char *)keychain_t, NULL });
    mew_exec((char *[]){ "MEWDo", "/bin/cp", "-ax", (char *)keychain_p, (char *)keychain_t, NULL });
    
    // Check Keychain
    struct stat keychain_t_s;
    bzero(&keychain_t_s, sizeof(struct stat));
    lstat(keychain_t, &keychain_t_s);
    assert(S_ISDIR(keychain_t_s.st_mode));
    
    // Fake Configuration
    NSString *configBackupPath = [backupPath stringByAppendingPathComponent:kMewEncConfigName];
    const char *config_p = [configBackupPath UTF8String];
    const char *config_t = [kMewEncConfigPath UTF8String];
    struct stat config_s;
    bzero(&config_s, sizeof(struct stat));
    lstat(config_p, &config_s);
    assert(S_ISREG(config_s.st_mode));
    mew_exec((char *[]){ "MEWDo", "/bin/cp", "-ax", (char *)[configBackupPath UTF8String], (char *)config_t, NULL });
    
    // Check Configuration
    struct stat config_t_s;
    bzero(&config_t_s, sizeof(struct stat));
    lstat(config_t, &config_t_s);
    assert(S_ISREG(config_t_s.st_mode));
    
    // Application Recover
    NSUInteger applicationCount = 0;
    NSArray <NSString *> *whitelist = R(kMewEncApplicationIdentifierWhiteList);
    if (!whitelist || whitelist.count == 0)
    {
        return;
    }
    Class LSApplicationWorkspace_class = objc_getClass("LSApplicationWorkspace");
    SEL selector = NSSelectorFromString(@"defaultWorkspace");
    NSObject *workspace = [LSApplicationWorkspace_class performSelector:selector];
    SEL selectorAll = NSSelectorFromString(@"allInstalledApplications");
    NSArray <LSApplicationProxy *> *allApplications = [workspace performSelector:selectorAll];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"applicationType = 'User'"];
    NSArray <LSApplicationProxy *> *userApplications = [allApplications filteredArrayUsingPredicate:predicate];
    for (LSApplicationProxy *appProxy in userApplications)
    {
        NSString *applicationIdentifier = [appProxy applicationIdentifier];
        BOOL enabledApplication = NO;
        for (NSString *enabledApp in whitelist) {
            if ([enabledApp isKindOfClass:[NSString class]]) {
                if ([enabledApp isEqualToString:applicationIdentifier]) {
                    enabledApplication = YES;
                }
            }
        }
        if (!enabledApplication) {
            continue;
        }
        if (applicationIdentifier && applicationIdentifier.length != 0)
        {
            NSString *applicationContainer = nil;
            if (XXT_SYSTEM_8)
            {
                applicationContainer = [[appProxy dataContainerURL] path];
            }
            else
            {
                applicationContainer = [[appProxy containerURL] path];
            }
            if (applicationContainer)
            {
                NSString *applicationBackupContainer = [backupPath stringByAppendingPathComponent:applicationIdentifier];
                const char *application_p = [applicationBackupContainer UTF8String];
                struct stat application_s;
                bzero(&application_s, sizeof(struct stat));
                lstat(application_p, &application_s);
                if (!S_ISDIR(application_s.st_mode)) {
                    continue;
                }
                
                NSArray <NSString *> *backupTargets
                = @[
                    @"Documents", @"Library", @"StoreKit", @"tmp"
                    ];
                for (NSString *backupTarget in backupTargets) {
                    
                    NSString *sourcePath = [applicationBackupContainer stringByAppendingPathComponent:backupTarget];
                    NSString *destPath = [applicationContainer stringByAppendingPathComponent:backupTarget];
                    const char *source_p = [sourcePath UTF8String];
                    const char *dest_p = [destPath UTF8String];
                    
                    struct stat source_s;
                    bzero(&source_s, sizeof(struct stat));
                    lstat(source_p, &source_s);
                    
                    if (S_ISDIR(source_s.st_mode)) {
                        
                        struct stat dest_s;
                        bzero(&dest_s, sizeof(struct stat));
                        lstat(dest_p, &dest_s);
                        
                        if (S_ISDIR(dest_s.st_mode)) {
                            mew_exec((char *[]){ "MEWDo", "/bin/rm", "-rf", (char *)dest_p, NULL });
                        }
                        
                        // move
                        mew_exec((char *[]){ "MEWDo", "/bin/mv", "-f", (char *)source_p, (char *)dest_p, NULL });
                        
                        // check move
                        bzero(&dest_s, sizeof(struct stat));
                        lstat(dest_p, &dest_s);
                        assert(S_ISDIR(dest_s.st_mode));
                        
                    }
                }
                
                applicationCount++;
            }
        }
    }
    
    // remove backup
    mew_exec((char *[]){"MEWDo", "/bin/rm", "-rf", (char *)[backupPath UTF8String], NULL});
    
}

- (void)removeBackup:(NSString *)backupPath withError:(NSError **)error {
    NSString *backupPathCheck = [backupPath stringByAppendingPathComponent:kMewEncConfigName];
    if ([[NSFileManager defaultManager] fileExistsAtPath:backupPathCheck]) {
        mew_exec((char *[]){"MEWDo", "/bin/rm", "-rf", (char *)[backupPath UTF8String], NULL});
    } else {
        if (error != nil) {
            *error = [NSError errorWithDomain:kMewEncErrorDomain code:0 userInfo:@{NSLocalizedDescriptionKey: [NSString stringWithFormat:@"Invalid Backup: %@", backupPath]}];
        }
    }
}

CFArrayRef SBSCopyApplicationDisplayIdentifiers(bool, bool);
void SBSProcessIDForDisplayIdentifier(CFStringRef, pid_t *);
- (void)killallApplications {
//    void *sbservice = dlopen("/System/Library/PrivateFrameworks/SpringBoardServices.framework", RTLD_LAZY | RTLD_GLOBAL);
//    if (sbservice) {
        NSArray *activeApps = (__bridge NSArray *)(SBSCopyApplicationDisplayIdentifiers(true, false));
        for (NSString *activeId in activeApps) {
            if ([activeId isEqualToString:kMewEncBundleID]) {
                continue;
            }
            pid_t pid;
            SBSProcessIDForDisplayIdentifier((__bridge CFStringRef)(activeId), &pid);
            if (pid) {
                kill(pid, SIGKILL);
            }
        }
//        dlclose(sbservice);
//    }
}

- (void)bootstrapDevice {
    
    // [0] Killall
    [self killallApplications];
    // [1] Make Backup
    if (
        [R(kMewEncSwitchAutoBackup) boolValue] == YES
        )
    {
        [self makeBackup];
    }
    // [2] Clean Application
    [self cleanApplicationContainer];
    // [2-1] Clean Safari
    [self cleanSafariCaches];
    // [3] Clean Pasteboard
    [self cleanAllPasteboard];
    // [4] Clean Keychain
    [self cleanSystemKeychain];
    // [5] Generate New Device
    [self randomFake];
    
}

@end


