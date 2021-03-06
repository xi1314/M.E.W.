//
//  MEWMain.c
//  MEW
//
//  Created by Zheng on 05/05/2017.
//



#import <dlfcn.h>
#import <dirent.h>
#import <net/if.h>
#import <ifaddrs.h>
#import <sys/stat.h>
#import <net/if_dl.h>
#import <substrate.h>
#import <arpa/inet.h>
#import <sys/sysctl.h>
#import <sys/utsname.h>
#import <mach-o/dyld.h>
#import <UIKit/UIKit.h>
#import "CaptainHook.h"
#import "MobileGestalt.h"
#import "MEWConfiguration.h"
#import "LSApplicationProxy.h"
#import <SystemConfiguration/CaptiveNetwork.h>
#import <CoreTelephony/CTTelephonyNetworkInfo.h>
#import <SystemConfiguration/SCNetworkReachability.h>

_Pragma("clang diagnostic push")
_Pragma("clang diagnostic ignored \"-Wmissing-prototypes\"")

#pragma mark - Config

static CFAbsoluteTime mewStartTime = 0.f;

#pragma mark - Dynamic Image Check

int (*original_dladdr)(void *addr, Dl_info *info);
static int replaced_dladdr(void *addr, Dl_info *info) {
    NSArray <NSString *> *replaceList = R(kMewEncReplaceImagePathList);
    if (!replaceList) {
        return original_dladdr(addr, info);
    }
    const char *replaceImagePath = [replaceList[arc4random() % replaceList.count] UTF8String];
    char *newPath = (char *) malloc(strlen(replaceImagePath) + 1);
    strcpy(newPath, replaceImagePath);
    int result = original_dladdr(addr, info);
    if ((result != 0) && (info != NULL) && (info->dli_fname != NULL)) {
        if (strstr(info->dli_fname, "MobileSubstrate") ||
            strstr(info->dli_fname, "CydiaSubstrate")
            ) {
            
            Dl_info *dlInfo = info;
            dlInfo->dli_fname = newPath;
            dlInfo->dli_sname = NULL;
            dlInfo->dli_saddr = NULL;
        }
    }
    return result;
}

char *(* original_dyld_get_image_name)(int index);
static char *replaced_dyld_get_image_name(int index) {
    NSArray <NSString *> *replaceList = R(kMewEncReplaceImagePathList);
    if (!replaceList) {
        return original_dyld_get_image_name(index);
    }
    const char *replaceImagePath = [replaceList[arc4random() % replaceList.count] UTF8String];
    char *newPath = (char *) malloc(strlen(replaceImagePath) + 1);
    strcpy(newPath, replaceImagePath);
    char *result = original_dyld_get_image_name(index);
    if (result &&
        (strstr(result, "MobileSubstrate") ||
         strstr(result, "CydiaSubstrate")
         ))
    {
        return newPath;
    }
    return result;
}

#pragma mark - Environment Variables Check

char *(* original_getenv)(const char* name);
static char *replaced_getenv(const char* name) {
    NSArray <NSString *> *bypassList = R(kMewEncReplaceEnvironmentVariableList);
    for (NSString *bypassName in bypassList) {
        if (strcmp(name, bypassName.UTF8String) == 0) {
            return NULL;
        }
    }
    return original_getenv(name);
}

#pragma mark - File System Check
// There are so many system calls that check path, here we only hook part of them.

int (*original_stat)(const char *path, struct stat *info);
static int replaced_stat(const char *path, struct stat *info) {
    NSArray <NSString *> *bypassList = R(kMewEncPathCheckBypassList);
    for (NSString *bypassPath in bypassList) {
        if (strcmp([bypassPath UTF8String], path) == 0) {
            errno = ENOENT;
            return -1;
        }
    }
    return original_stat(path, info);
}

int (*original_access)(const char *path, int mode);
static int replaced_access(const char *path, int mode) {
    NSArray <NSString *> *bypassList = R(kMewEncPathCheckBypassList);
    for (NSString *bypassPath in bypassList) {
        if (strcmp([bypassPath UTF8String], path) == 0) {
            errno = ENOENT;
            return -1;
        }
    }
    return original_access(path, mode);
}

DIR *(*original_opendir)(const char *path);
static DIR *replaced_opendir(const char *path) {
    NSArray <NSString *> *bypassList = R(kMewEncPathCheckBypassList);
    for (NSString *bypassPath in bypassList) {
        if (strcmp([bypassPath UTF8String], path) == 0) {
            errno = ENOENT;
            return NULL;
        }
    }
    return original_opendir(path);
}

FILE *(*original_fopen)(const char *filename, const char *mode);
static FILE *replaced_fopen(const char *filename, const char *mode) {
    NSArray <NSString *> *bypassList = R(kMewEncPathCheckBypassList);
    for (NSString *bypassPath in bypassList) {
        if (strcmp([bypassPath UTF8String], filename) == 0) {
            errno = ENOENT;
            return NULL;
        }
    }
    return original_fopen(filename, mode);
}

static BOOL (* _orig_NSFileManager_fileExistsAtPath)(id _self, SEL _cmd1, NSString *path);
BOOL NSFileManager_fileExistsAtPath(id _self, SEL _cmd1, NSString *path) {
    NSArray <NSString *> *bypassList = R(kMewEncPathCheckBypassList);
    for (NSString *bypassPath in bypassList) {
        if ([bypassPath isEqualToString:path]) {
            return NO;
        }
    }
    return _orig_NSFileManager_fileExistsAtPath(_self, _cmd1, path);
}

static BOOL (* _orig_NSFileManager_fileExistsAtPath_isDirectory)(id _self, SEL _cmd1, NSString *path, BOOL *isDirectory);
BOOL NSFileManager_fileExistsAtPath_isDirectory(id _self, SEL _cmd1, NSString *path, BOOL *isDirectory) {
    NSArray <NSString *> *bypassList = R(kMewEncPathCheckBypassList);
    for (NSString *bypassPath in bypassList) {
        if ([bypassPath isEqualToString:path]) {
            return NO;
        }
    }
    return _orig_NSFileManager_fileExistsAtPath_isDirectory(_self, _cmd1, path, isDirectory);
}

static IMP _orig_NSFileManager_contentsOfDirectoryAtPath_error;
NSArray *NSFileManager_contentsOfDirectoryAtPath_error(id _self, SEL _cmd1, NSString *path, NSError **error) {
    NSArray <NSString *> *directoryList = R(kMewEncDirectoryCheckBypassList);
    for (NSString *directoryPath in directoryList) {
        if ([directoryPath isEqualToString:path]) {
            return @[];
        }
    }
    return _orig_NSFileManager_contentsOfDirectoryAtPath_error(_self, _cmd1, path, error);
}

#pragma mark - URL Scheme Check

static BOOL (* _orig_UIApplication_canOpenURL)(id _self, SEL _cmd1, NSURL *url);
BOOL UIApplication_canOpenURL(id _self, SEL _cmd1, NSURL *url) {
    NSArray <NSString *> *bypassList = R(kMewEncURLSchemeCheckBypassList);
    for (NSString *bypassPath in bypassList) {
        NSRange pathRange = [[url path] rangeOfString:bypassPath];
        if (pathRange.location != NSNotFound) {
            return NO;
        }
    }
    return _orig_UIApplication_canOpenURL(_self, _cmd1, url);
}

#pragma mark - Private APIs Check

static IMP _orig_LSApplicationWorkspace_allApplications;
NSArray <LSApplicationProxy *> *LSApplicationWorkspace_allApplications(id _self, SEL _cmd1) {
    NSArray <NSString *> *filteredApplications = R(kMewEncReplaceApplicationIdentifierList);
    NSArray <LSApplicationProxy *> *result = (NSArray<LSApplicationProxy *> *) [_orig_LSApplicationWorkspace_allApplications(_self, _cmd1) retain];
    if (!filteredApplications || filteredApplications.count == 0) {
        return result;
    }
    NSMutableArray <LSApplicationProxy *> *mutableResult = [[[NSMutableArray alloc] initWithArray:result] autorelease];
    NSMutableArray <LSApplicationProxy *> *removeApplications = [[NSMutableArray alloc] init];
    for (LSApplicationProxy *appProxy in result) {
        for (NSString *appIdentifier in filteredApplications) {
            if ([appIdentifier isEqualToString:appProxy.applicationIdentifier]) {
                [removeApplications addObject:appProxy];
            }
        }
    }
    [result release];
    for (LSApplicationProxy *appProxy in removeApplications) {
        [mutableResult removeObject:appProxy];
    }
    [removeApplications release];
    return mutableResult;
}

static IMP _orig_LSApplicationWorkspace_allInstalledApplications;
NSArray <LSApplicationProxy *> *LSApplicationWorkspace_allInstalledApplications(id _self, SEL _cmd1) {
    NSArray <NSString *> *filteredApplications = R(kMewEncReplaceApplicationIdentifierList);
    NSArray <LSApplicationProxy *> *result = (NSArray<LSApplicationProxy *> *) [_orig_LSApplicationWorkspace_allInstalledApplications(_self, _cmd1) retain];
    if (!filteredApplications || filteredApplications.count == 0) {
        return result;
    }
    NSMutableArray <LSApplicationProxy *> *mutableResult = (NSMutableArray<LSApplicationProxy *> *) [[result mutableCopy] autorelease];
    NSMutableArray <LSApplicationProxy *> *removeApplications = [[NSMutableArray alloc] init];
    for (LSApplicationProxy *appProxy in result) {
        for (NSString *appIdentifier in filteredApplications) {
            if ([appIdentifier isEqualToString:appProxy.applicationIdentifier]) {
                [removeApplications addObject:appProxy];
            }
        }
    }
    [result release];
    for (LSApplicationProxy *appProxy in removeApplications) {
        [mutableResult removeObject:appProxy];
    }
    [removeApplications release];
    return mutableResult;
}

static IMP _orig_LSApplicationWorkspace_deviceIdentifierForAdvertising;
NSString *LSApplicationWorkspace_deviceIdentifierForAdvertising(id _self, SEL _cmd1) {
    NSString *result = _orig_LSApplicationWorkspace_deviceIdentifierForAdvertising(_self, _cmd1);
    if (!R(kMewEncAdvertisingIdentifier)) {
        return result;
    }
    return R(kMewEncAdvertisingIdentifier);
}

static IMP _orig_LSApplicationWorkspace_deviceIdentifierForVendor;
NSString *LSApplicationWorkspace_deviceIdentifierForVendor(id _self, SEL _cmd1) {
    NSString *result = _orig_LSApplicationWorkspace_deviceIdentifierForVendor(_self, _cmd1);
    if (!R(kMewEncIdentifierForVendor)) {
        return result;
    }
    return R(kMewEncIdentifierForVendor);
}

static IMP _orig_LSApplicationProxy_deviceIdentifierForAdvertising;
NSString *LSApplicationProxy_deviceIdentifierForAdvertising(id _self, SEL _cmd1) {
    NSString *result = _orig_LSApplicationProxy_deviceIdentifierForAdvertising(_self, _cmd1);
    if (!R(kMewEncAdvertisingIdentifier)) {
        return result;
    }
    return R(kMewEncAdvertisingIdentifier);
}

static IMP _orig_LSApplicationProxy_deviceIdentifierForVendor;
NSString *LSApplicationProxy_deviceIdentifierForVendor(id _self, SEL _cmd1) {
    NSString *result = _orig_LSApplicationProxy_deviceIdentifierForVendor(_self, _cmd1);
    if (!R(kMewEncIdentifierForVendor)) {
        return result;
    }
    return R(kMewEncIdentifierForVendor);
}

#pragma mark - Device Info Check

static IMP _orig_UIDevice_name;
NSString *UIDevice_name(id _self, SEL _cmd1) {
    NSString *fakeName = R(kMewEncDeviceName);
    if (!fakeName) {
        return _orig_UIDevice_name(_self, _cmd1);
    }
    return fakeName;
}

int (*original_uname)(struct utsname *uts);
static int replace_uname(struct utsname *uts) {
    NSString *fakeName = R(kMewEncDeviceName);
    NSString *fakeType = R(kMewEncProductType);
    int result = original_uname(uts);
    if (fakeName && fakeType && fakeName.length != 0 && fakeType.length != 0) {
        strncpy(uts->nodename, [fakeName UTF8String], fakeName.length);
        strncpy(uts->machine, [fakeType UTF8String], fakeType.length);
    }
    return result;
}

static IMP _orig_UIDevice_model;
NSString *UIDevice_model(id _self, SEL _cmd1) {
    NSString *fakeModel = R(kMewEncDeviceCategory);
    if (!fakeModel) {
        return _orig_UIDevice_model(_self, _cmd1);
    }
    return fakeModel;
}
static IMP _orig_UIDevice_localizedModel;
NSString *UIDevice_localizedModel(id _self, SEL _cmd1) {
    NSString *fakeModel = R(kMewEncDeviceCategory);
    if (!fakeModel) {
        return _orig_UIDevice_localizedModel(_self, _cmd1);
    }
    return fakeModel;
}

static IMP _orig_UIDevice_systemName;
NSString *UIDevice_systemName(id _self, SEL _cmd1) {
    NSString *fakeName = R(kMewEncSystemName);
    if (!fakeName) {
        return _orig_UIDevice_systemName(_self, _cmd1);
    }
    return fakeName;
}

static IMP _orig_UIDevice_systemVersion;
NSString *UIDevice_systemVersion(id _self, SEL _cmd1) {
    NSString *fakeVersion = R(kMewEncSystemVersion);
    if (!fakeVersion) {
        return _orig_UIDevice_systemVersion(_self, _cmd1);
    }
    return fakeVersion;
}

static IMP _orig_UIDevice_uniqueIdentifier;
NSString *UIDevice_uniqueIdentifier(id _self, SEL _cmd1) {
    NSString *fakeIdentifier = R(kMewEncUniqueIdentifier);
    if (!fakeIdentifier) {
        return _orig_UIDevice_uniqueIdentifier(_self, _cmd1);
    }
    return fakeIdentifier;
}

static IMP _orig_UIDevice_identifierForVendor;
NSUUID *UIDevice_identifierForVendor(id _self, SEL _cmd1) {
    NSString *fakeIdentifier = R(kMewEncIdentifierForVendor);
    if (!fakeIdentifier) {
        return _orig_UIDevice_identifierForVendor(_self, _cmd1);
    }
    return [[[NSUUID alloc] initWithUUIDString:fakeIdentifier] autorelease];
}

static NSUInteger (*_orig_UIDevice_batteryState)(id _self, SEL _cmd1);
NSUInteger UIDevice_batteryState(id _self, SEL _cmd1) {
    NSNumber *fakeState = R(kMewEncDeviceBatteryState);
    if (!fakeState) {
        return _orig_UIDevice_batteryState(_self, _cmd1);
    }
    return [fakeState unsignedIntegerValue];
}

static float (* _orig_UIDevice_batteryLevel)(id _self, SEL _cmd1);
float UIDevice_batteryLevel(id _self, SEL _cmd1) {
    float fakeLevel;
    CFAbsoluteTime timePassed = CFAbsoluteTimeGetCurrent() - mewStartTime;
    fakeLevel = (float) (.98f - (timePassed / (3600.f * 6)));
    if (fakeLevel <= 0.f) {
        mewStartTime = CFAbsoluteTimeGetCurrent();
        fakeLevel = .98f;
    }
    return fakeLevel;
}

static IMP _orig_UIStatusBarDataNetworkItemView_valueForKeyPath;
id UIStatusBarDataNetworkItemView_valueForKeyPath(id _self, SEL _cmd1, NSString *keyPath) {
    if ([keyPath isEqualToString:@"dataNetworkType"]) {
        NSNumber *fakeType = R(kMewEncNetworkType);
        if (fakeType) {
            return fakeType;
        }
    }
    return _orig_UIStatusBarDataNetworkItemView_valueForKeyPath(_self, _cmd1, keyPath);
}

static IMP _orig_UIStatusBarServiceItemView_valueForKey;
id UIStatusBarServiceItemView_valueForKey(id _self, SEL _cmd1, NSString *keyPath) {
    if ([keyPath isEqualToString:@"serviceString"]) {
        NSString *fakeSerivceString = R(kMewEncServiceString);
        if (fakeSerivceString) {
            return fakeSerivceString;
        }
    }
    return _orig_UIStatusBarServiceItemView_valueForKey(_self, _cmd1, keyPath);
}

static float (*_orig_UIScreen_brightness)(id _self, SEL _cmd1);
float UIScreen_brightness(id _self, SEL _cmd1) {
    NSNumber *fakeBrightness = R(kMewEncScreenBrightness);
    if (!fakeBrightness) {
        return _orig_UIScreen_brightness(_self, _cmd1);
    }
    return [fakeBrightness floatValue];
}

static BOOL (*_orig_ASIdentifierManager_isAdvertisingTrackingEnabled)(id _self, SEL _cmd1);
BOOL ASIdentifierManager_isAdvertisingTrackingEnabled(id _self, SEL _cmd1) {
    return YES;
}

static IMP _orig_ASIdentifierManager_advertisingIdentifier;
NSUUID *ASIdentifierManager_advertisingIdentifier(id _self, SEL _cmd1) {
    NSString *fakeIdentifier = R(kMewEncAdvertisingIdentifier);
    if (!fakeIdentifier) {
        return _orig_ASIdentifierManager_advertisingIdentifier(_self, _cmd1);
    }
    return [[[NSUUID alloc] initWithUUIDString:fakeIdentifier] autorelease];
}

#pragma mark - Carrier Info Check

static IMP _orig_CTCarrier_carrierName;
NSString *CTCarrier_carrierName(id _self, SEL _cmd1) {
    NSString *fakeCarrierName = R(kMewEncCarrierName);
    if (!fakeCarrierName) {
        return _orig_CTCarrier_carrierName(_self, _cmd1);
    }
    return fakeCarrierName;
}

static IMP _orig_CTCarrier_mobileCountryCode;
NSString *CTCarrier_mobileCountryCode(id _self, SEL _cmd1) {
    NSString *fakeCountryCode = R(kMewEncCountryCode);
    if (!fakeCountryCode) {
        return _orig_CTCarrier_mobileCountryCode(_self, _cmd1);
    }
    return fakeCountryCode;
}

static IMP _orig_CTCarrier_mobileNetworkCode;
NSString *CTCarrier_mobileNetworkCode(id _self, SEL _cmd1) {
    NSString *fakeNetworkCode = R(kMewEncNetworkCode);
    if (!fakeNetworkCode) {
        return _orig_CTCarrier_mobileNetworkCode(_self, _cmd1);
    }
    return fakeNetworkCode;
}

static IMP _orig_CTCarrier_isoCountryCode;
NSString *CTCarrier_isoCountryCode(id _self, SEL _cmd1) {
    NSString *fakeCountryCode = R(kMewEncISOCountryCode);
    if (!fakeCountryCode) {
        return _orig_CTCarrier_isoCountryCode(_self, _cmd1);
    }
    return fakeCountryCode;
}

static BOOL (*_orig_CTCarrier_allowsVOIP)(id _self, SEL _cmd1);
BOOL CTCarrier_allowsVOIP(id _self, SEL _cmd1) {
    return YES;
}

CFStringRef (*original_CNCopyCurrentNetworkInfo)(NSString *ifname);
static CFStringRef replaced_CNCopyCurrentNetworkInfo(NSString *ifname) {
    NSNumber *networkType = R(kMewEncNetworkType);
    int nType = [networkType intValue];
    if (nType != 5 && R(kMewEncEthernetBSSID) && R(kMewEncEthernetSSID)) {
        NSDictionary *networkInfo = @{
                                      @"BSSID": R(kMewEncEthernetBSSID),
                                      @"SSID": R(kMewEncEthernetSSID),
                                      @"SSIDDATA": [R(kMewEncEthernetSSID) dataUsingEncoding:NSUTF8StringEncoding]
                                      };
        return CFBridgingRetain(networkInfo);
    }
    return original_CNCopyCurrentNetworkInfo(ifname);
}

Boolean (*original_SCNetworkReachabilityGetFlags)(SCNetworkReachabilityRef target, SCNetworkReachabilityFlags *flags);
static Boolean replaced_SCNetworkReachabilityGetFlags(SCNetworkReachabilityRef target, SCNetworkReachabilityFlags *flags) {
    if (flags != NULL) {
        NSNumber *networkType = R(kMewEncNetworkType);
        original_SCNetworkReachabilityGetFlags(target, flags);
        
        int nType = [networkType intValue];
        if (nType == 5) {
            *flags = (SCNetworkReachabilityFlags) 65538;
        } else if (nType == 1) {
            *flags = (SCNetworkReachabilityFlags) 262147;
        } else if (nType == 2) {
            *flags = (SCNetworkReachabilityFlags) 262147;
        } else if (nType == 3) {
            *flags = (SCNetworkReachabilityFlags) 262147;
        } else {
            *flags = (SCNetworkReachabilityFlags) 0;
        }
    }
    return true;
}

int (*original_getifaddrs)(struct ifaddrs **interfaces);
static int replaced_getifaddrs(struct ifaddrs **interfaces) {
    NSDictionary *ifaddrs = R(kMewEncNetworkInterfaces);
    int result = original_getifaddrs(interfaces);
    if (!ifaddrs) {
        return result;
    }
    struct ifaddrs *interface;
    for (interface = *interfaces; interface; interface = interface->ifa_next) {
        if (!(interface->ifa_flags & IFF_UP) /* || (interface->ifa_flags & IFF_LOOPBACK) */ ) {
            continue; // deeply nested code harder to read
        }
        if (!(interface->ifa_name)) {
            continue;
        }
        char addrBuf[ MAX(INET_ADDRSTRLEN, INET6_ADDRSTRLEN) ];
        NSString *name = [[NSString alloc] initWithUTF8String:interface->ifa_name];
        if (interface->ifa_addr && (((const struct sockaddr_in*)interface->ifa_addr)->sin_family == AF_INET || ((const struct sockaddr_in*)interface->ifa_addr)->sin_family == AF_INET6)) {
            if (((const struct sockaddr_in*)interface->ifa_addr)->sin_family == AF_INET) {
                const struct sockaddr_in *addr = (const struct sockaddr_in*)interface->ifa_addr;
                if (inet_ntop(AF_INET, &addr->sin_addr, addrBuf, INET_ADDRSTRLEN)) {
                    const char *ipAddress = "127.0.0.1";
                    if (name && ifaddrs[name] && ifaddrs[name][@"ipv4"]) {
                        ipAddress = [ifaddrs[name][@"ipv4"] UTF8String];
                        
                    } else if (strstr(interface->ifa_name, "en") && R(kMewEncEthernetIPv4Address)) {
                        ipAddress = [R(kMewEncEthernetIPv4Address) UTF8String];
                    }
                    inet_pton(AF_INET, ipAddress, (void *)&addr->sin_addr);
                }
            } else if (((const struct sockaddr_in*)interface->ifa_addr)->sin_family == AF_INET6) {
                const struct sockaddr_in6 *addr6 = (const struct sockaddr_in6*)interface->ifa_addr;
                if (inet_ntop(AF_INET6, &addr6->sin6_addr, addrBuf, INET6_ADDRSTRLEN)) {
                    const char *ipAddress = "::1";
                    if (name && ifaddrs[name] && ifaddrs[name][@"ipv6"]) {
                        ipAddress = [ifaddrs[name][@"ipv6"] UTF8String];
                    } else if (strstr(interface->ifa_name, "en") && R(kMewEncEthernetIPv6Address)) {
                        ipAddress = [R(kMewEncEthernetIPv6Address) UTF8String];
                    }
                    inet_pton(AF_INET6, ipAddress, (void *)&addr6->sin6_addr);
                }
            }
        } else if (
                   (interface->ifa_addr->sa_family == AF_LINK)
                   && (((const struct sockaddr_dl *) interface->ifa_addr)->sdl_type == 0x6)
                   ) {
            const struct sockaddr_dl *dlAddr = (const struct sockaddr_dl *) interface->ifa_addr;
            //                const unsigned char *base = (const unsigned char*) &dlAddr->sdl_data[dlAddr->sdl_nlen];
            if (name && ifaddrs[name] && ifaddrs[name][@"mac"]) {
                NSData *ipData = ifaddrs[name][@"mac"];
                const char *macAddress = [ipData bytes];
                memcpy((void *)&dlAddr->sdl_data[dlAddr->sdl_nlen], (void *)macAddress, [ipData length]);
            } else if (strstr(interface->ifa_name, "en") && R(kMewEncEthernetMacAddress)) {
                const char *mac = [[R(kMewEncEthernetMacAddress) dataUsingEncoding:NSUTF8StringEncoding] bytes];
                if (mac) {
                    char macValue[7] = "";
                    sscanf(mac, "%02hhx:%02hhx:%02hhx:%02hhx:%02hhx:%02hhx", &macValue[0], &macValue[1], &macValue[2], &macValue[3], &macValue[4], &macValue[5]);
                    memcpy((void *)&dlAddr->sdl_data[dlAddr->sdl_nlen], (void *)mac, 6);
                }
            }
        }
        [name release];
    }
    return result;
}

typedef mach_port_t io_object_t;
typedef io_object_t io_registry_entry_t;
typedef char  io_name_t[128];
typedef UInt32  IOOptionBits;

CFTypeRef (*original_IORegistryEntryCreateCFProperty)(mach_port_t entry, CFStringRef key, CFAllocatorRef allocator, uint32_t options);
static CFTypeRef replaced_IORegistryEntryCreateCFProperty(mach_port_t entry, CFStringRef key, CFAllocatorRef allocator, uint32_t options) {
    CFTypeRef result = original_IORegistryEntryCreateCFProperty(entry, key, allocator, options);
    NSString *keyString = (__bridge NSString *)key;
    if (!keyString || !result) {
        return result;
    }
    id replace = R(kMewEncReplaceIOKitProperties)[keyString];
    if (!replace) {
        if ([keyString isEqualToString:kMewEncIOPlatformSerialNumber]) {
            replace = R(kMewEncSerialNumber);
        }
        else if ([keyString isEqualToString:kMewEncIOPlatformUUID]) {
            replace = R(kMewEncUniqueIdentifier);
        }
        else if ([keyString isEqualToString:kMewEncIOSerialNumber]) {
            replace = [R(kMewEncSerialNumber) dataUsingEncoding:NSUTF8StringEncoding];
        }
        else if ([keyString isEqualToString:kMewEncIOMLBSerialNumber]) {
            replace = [R(kMewEncMLBSerialNumber) dataUsingEncoding:NSUTF8StringEncoding];
        }
        else if ([keyString isEqualToString:kMewEncIOBluetoothAddress]) {
            if (R(kMewEncBluetoothAddress)) {
                const char *mac = [[R(kMewEncBluetoothAddress) dataUsingEncoding:NSUTF8StringEncoding] bytes];
                if (mac) {
                    char macValue[7] = "";
                    sscanf(mac, "%02hhx:%02hhx:%02hhx:%02hhx:%02hhx:%02hhx", &macValue[0], &macValue[1], &macValue[2], &macValue[3], &macValue[4], &macValue[5]);
                    replace = [NSData dataWithBytes:macValue length:6];
                }
            }
        }
        else if ([keyString isEqualToString:kMewEncIOInternationalMobileEquipmentIdentity]) {
            replace = [R(kMewEncInternationalMobileEquipmentIdentity) dataUsingEncoding:NSUTF8StringEncoding];
        }
        else if ([keyString isEqualToString:kMewEncIOUniqueChipId]) {
            replace = [R(kMewEncUniqueChipID) dataUsingEncoding:NSUTF8StringEncoding];
        }
    }
    if (!replace) {
        return result;
    }
    CFRelease(result);
    return CFBridgingRetain(replace);
}

kern_return_t (* original_IORegistryEntryCreateCFProperties)(io_registry_entry_t entry,
                                                             CFMutableDictionaryRef *properties,
                                                             CFAllocatorRef allocator,
                                                             IOOptionBits options);
static kern_return_t replaced_IORegistryEntryCreateCFProperties(io_registry_entry_t entry,
                                                                CFMutableDictionaryRef *properties,
                                                                CFAllocatorRef allocator,
                                                                IOOptionBits options) {
    NSDictionary *replaceProperties = R(kMewEncReplaceIOKitProperties);
    kern_return_t result = original_IORegistryEntryCreateCFProperties(entry, properties, allocator, options);
    NSMutableDictionary *propertiesObj = (__bridge NSMutableDictionary *)*properties;
    NSMutableDictionary *replaceObj = [[NSMutableDictionary alloc] init];
    for (NSString *keyString in propertiesObj) {
        id replace = nil;
        if ([keyString isEqualToString:kMewEncIOPlatformSerialNumber]) {
            replace = R(kMewEncSerialNumber);
        }
        else if ([keyString isEqualToString:kMewEncIOPlatformUUID]) {
            replace = R(kMewEncUniqueIdentifier);
        }
        else if ([keyString isEqualToString:kMewEncIOSerialNumber]) {
            replace = [R(kMewEncSerialNumber) dataUsingEncoding:NSUTF8StringEncoding];
        }
        else if ([keyString isEqualToString:kMewEncIOMLBSerialNumber]) {
            replace = [R(kMewEncMLBSerialNumber) dataUsingEncoding:NSUTF8StringEncoding];
        }
        else if ([keyString isEqualToString:kMewEncIOBluetoothAddress]) {
            if (R(kMewEncBluetoothAddress)) {
                const char *mac = [[R(kMewEncBluetoothAddress) dataUsingEncoding:NSUTF8StringEncoding] bytes];
                if (mac) {
                    char macValue[7] = "";
                    sscanf(mac, "%02hhx:%02hhx:%02hhx:%02hhx:%02hhx:%02hhx", &macValue[0], &macValue[1], &macValue[2], &macValue[3], &macValue[4], &macValue[5]);
                    replace = [NSData dataWithBytes:macValue length:6];
                }
            }
        }
        else if ([keyString isEqualToString:kMewEncIOInternationalMobileEquipmentIdentity]) {
            replace = [R(kMewEncInternationalMobileEquipmentIdentity) dataUsingEncoding:NSUTF8StringEncoding];
        }
        else if ([keyString isEqualToString:kMewEncIOUniqueChipId]) {
            replace = [R(kMewEncUniqueChipID) dataUsingEncoding:NSUTF8StringEncoding];
        }
        if (replace != nil) {
            replaceObj[keyString] = replace;
        }
    }
    for (NSString *keyString in replaceObj) {
        propertiesObj[keyString] = CFBridgingRetain(replaceObj[keyString]);
    }
    [replaceObj release];
    for (NSString *replaceKey in replaceProperties) {
        if (propertiesObj && propertiesObj[replaceKey]) {
            propertiesObj[replaceKey] = CFBridgingRetain(replaceProperties[replaceKey]);
        }
    }
    return result;
}


CFTypeRef
(* original_IORegistryEntrySearchCFProperty)(
                                             io_registry_entry_t entry,
                                             const io_name_t  plane,
                                             CFStringRef  key,
                                             CFAllocatorRef allocator,
                                             IOOptionBits options );
static CFTypeRef replaced_IORegistryEntrySearchCFProperty(io_registry_entry_t entry, const io_name_t plane, CFStringRef key, CFAllocatorRef allocator, IOOptionBits options ) {
    CFTypeRef result = original_IORegistryEntrySearchCFProperty(entry, plane, key, allocator, options);
    NSString *keyString = (__bridge NSString *)key;
    if (!keyString || !result) {
        return result;
    }
    id replace = R(kMewEncReplaceIOKitProperties)[keyString];
    if (!replace) {
        if ([keyString isEqualToString:kMewEncIOPlatformSerialNumber]) {
            replace = R(kMewEncSerialNumber);
        }
        else if ([keyString isEqualToString:kMewEncIOPlatformUUID]) {
            replace = R(kMewEncUniqueIdentifier);
        }
        else if ([keyString isEqualToString:kMewEncIOSerialNumber]) {
            replace = [R(kMewEncSerialNumber) dataUsingEncoding:NSUTF8StringEncoding];
        }
        else if ([keyString isEqualToString:kMewEncIOMLBSerialNumber]) {
            replace = [R(kMewEncMLBSerialNumber) dataUsingEncoding:NSUTF8StringEncoding];
        }
        else if ([keyString isEqualToString:kMewEncIOBluetoothAddress]) {
            if (R(kMewEncBluetoothAddress)) {
                const char *mac = [[R(kMewEncBluetoothAddress) dataUsingEncoding:NSUTF8StringEncoding] bytes];
                if (mac) {
                    char macValue[7] = "";
                    sscanf(mac, "%02hhx:%02hhx:%02hhx:%02hhx:%02hhx:%02hhx", &macValue[0], &macValue[1], &macValue[2], &macValue[3], &macValue[4], &macValue[5]);
                    replace = [NSData dataWithBytes:macValue length:6];
                }
            }
        }
        else if ([keyString isEqualToString:kMewEncIOInternationalMobileEquipmentIdentity]) {
            replace = [R(kMewEncInternationalMobileEquipmentIdentity) dataUsingEncoding:NSUTF8StringEncoding];
        }
        else if ([keyString isEqualToString:kMewEncIOUniqueChipId]) {
            replace = [R(kMewEncUniqueChipID) dataUsingEncoding:NSUTF8StringEncoding];
        }
    }
    if (!replace) {
        return result;
    }
    CFRelease(result);
    return CFBridgingRetain(replace);
}

int (* original_sysctlbyname)(const char *, void *, size_t *, const void *, size_t);
static int replaced_sysctlbyname(const char *name, void *oldp, size_t *oldlenp, const void *newp, size_t newlen) {
    int result = original_sysctlbyname(name, oldp, oldlenp, newp, newlen);
    NSString *replaceName = nil;
    if (strcmp(name, "kern.hostname") == 0) {
        replaceName = R(kMewEncDeviceName);
    } else if (strcmp(name, "hw.machine") == 0) {
        replaceName = R(kMewEncProductType);
    } else if (strcmp(name, "hw.model") == 0) {
        replaceName = R(kMewEncProductHWModel);
    } else if (strcmp(name, "kern.osversion") == 0) {
        replaceName = R(kMewEncSystemBuildVersion);
    }
    if (replaceName) {
        const char *replaceStr = [replaceName UTF8String];
        *oldlenp = strlen(replaceStr) + 1;
        if (oldp != NULL) {
            strcpy(oldp, replaceStr);
        } else {
            return result;
        }
    }
    return result;
}

int (* original_sysctl)(const int *name, u_int namelen, void *oldp, size_t *oldlenp, const void *newp, size_t newlen);
static int replaced_sysctl(const int *name, u_int namelen, void *oldp, size_t *oldlenp, const void *newp, size_t newlen) {
    int result = original_sysctl(name, namelen, oldp, oldlenp, newp, newlen);
    if (oldp == NULL) {
        return result;
    }
    
//    if (namelen == 2) {
//        if (name[0] == CTL_KERN &&
//            name[1] == KERN_HOSTNAME
//            ) {
//            return result;
//        }
//    }
//    NSData *nameData = [[NSData alloc] initWithBytes:name length:namelen];
//    NSData *data = [[NSData alloc] initWithBytes:oldp length:*oldlenp];
//    NSLog(@"sysctl: %@, %@", nameData, data);
//    [nameData release];
//    [data release];
//    return result;
    
    if (namelen == 6) {
        if (name[0] == CTL_NET &&
            name[1] == AF_ROUTE &&
            name[2] == 0 &&
            name[3] == AF_LINK &&
            name[4] == NET_RT_IFLIST
            ) {
            struct sockaddr *socketStruct = (struct sockaddr *)((struct if_msghdr *)oldp + 1);
            if (socketStruct->sa_family == AF_LINK && ((struct sockaddr_dl *)socketStruct)->sdl_type == 0x6) {
                char if_name[IFNAMSIZ] = "";
                if_indextoname((unsigned int) name[5], if_name);
                NSString *ifNameString = [[NSString alloc] initWithUTF8String:if_name];
                NSDictionary *ifaddrs = R(kMewEncNetworkInterfaces);
                if (!ifaddrs) {
                    return result;
                }
                struct sockaddr_dl *dlAddr = (struct sockaddr_dl *)socketStruct;
                if (ifNameString &&
                    ifaddrs[ifNameString] &&
                    ifaddrs[ifNameString][@"mac"]
                    ) {
                    const char *macAddress = [ifaddrs[ifNameString][@"mac"] bytes];
                    memcpy((void *)&dlAddr->sdl_data[dlAddr->sdl_nlen], (void *)macAddress, 6);
                } else if (strstr(if_name, "en") && R(kMewEncEthernetMacAddress)) {
                    const char *mac = [[R(kMewEncEthernetMacAddress) dataUsingEncoding:NSUTF8StringEncoding] bytes];
                    if (mac) {
                        char macValue[7] = "";
                        sscanf(mac, "%02hhx:%02hhx:%02hhx:%02hhx:%02hhx:%02hhx", &macValue[0], &macValue[1], &macValue[2], &macValue[3], &macValue[4], &macValue[5]);
                        memcpy((void *)&dlAddr->sdl_data[dlAddr->sdl_nlen], (void *)macValue, 6);
                    }
                }
                [ifNameString release];
            }
        }
    }
    return result;
}

static CFPropertyListRef (*orig_MGCopyAnswer_internal)(CFStringRef prop, uint32_t* outTypeCode);
CFPropertyListRef new_MGCopyAnswer_internal(CFStringRef prop, uint32_t* outTypeCode) {
    NSDictionary *answers = R(kMewEncReplaceMGCopyAnswer);
    NSString *answerKey = (__bridge NSString *)prop;
    if (answers && answers[answerKey]) {
        return CFBridgingRetain(answers[answerKey]);
    }
    NSString *anotherKey = nil;
    if ([answerKey isEqualToString:(__bridge NSString *)kMGProductType]) {
        anotherKey = kMewEncProductType;
    }
    else if ([answerKey isEqualToString:(__bridge NSString *)kMGSerialNumber]) {
        anotherKey = kMewEncSerialNumber;
    }
    else if ([answerKey isEqualToString:(__bridge NSString *)kMGUniqueDeviceID]) {
        anotherKey = kMewEncUniqueDeviceID;
    }
    else if ([answerKey isEqualToString:(__bridge NSString *)kMGUniqueDeviceID]) {
        anotherKey = kMewEncUniqueDeviceID;
    }
    else if ([answerKey isEqualToString:(__bridge NSString *)kMGUserAssignedDeviceName]) {
        anotherKey = kMewEncDeviceName;
    }
    else if ([answerKey isEqualToString:(__bridge NSString *)kMGHWModel]) {
        anotherKey = kMewEncProductHWModel;
    }
    else if ([answerKey isEqualToString:(__bridge NSString *)kMGComputerName]) {
        anotherKey = kMewEncDeviceName;
    }
    else if ([answerKey isEqualToString:(__bridge NSString *)kMGInternationalMobileEquipmentIdentity]) {
        anotherKey = kMewEncInternationalMobileEquipmentIdentity;
    }
    else if ([answerKey isEqualToString:(__bridge NSString *)kMGUniqueChipID]) {
        anotherKey = kMewEncUniqueChipID;
    }
    else if ([answerKey isEqualToString:(__bridge NSString *)kMGBluetoothAddress]) {
        anotherKey = kMewEncBluetoothAddress;
    }
    else if ([answerKey isEqualToString:(__bridge NSString *)kMGProductVersion]) {
        anotherKey = kMewEncSystemVersion;
    }
    else if ([answerKey isEqualToString:(__bridge NSString *)kMGBuildVersion]) {
        anotherKey = kMewEncSystemBuildVersion;
    }
    else if ([answerKey isEqualToString:(__bridge NSString *)kMGMLBSerialNumber]) {
        anotherKey = kMewEncMLBSerialNumber;
    }
    else if ([answerKey isEqualToString:(__bridge NSString *)kMGWifiAddress]) {
        anotherKey = kMewEncEthernetMacAddress;
    }
    else if ([answerKey isEqualToString:(__bridge NSString *)kMGModelNumber]) {
        anotherKey = kMewEncProductModel;
    }
    else if ([answerKey isEqualToString:(__bridge NSString *)kMGRegionCode]) {
        anotherKey = kMewEncRegionCode;
    }
    else if ([answerKey isEqualToString:(__bridge NSString *)kMGRegionInfo]) {
        anotherKey = kMewEncRegionInfo;
    }
    if (anotherKey && R(anotherKey)) {
        return CFBridgingRetain(R(anotherKey));
    }
    return orig_MGCopyAnswer_internal(prop, outTypeCode);
}

static CFPropertyListRef (*orig_MGCopyAnswer)(CFStringRef prop);
CFPropertyListRef new_MGCopyAnswer(CFStringRef prop) {
    NSDictionary *answers = R(kMewEncReplaceMGCopyAnswer);
    NSString *answerKey = (__bridge NSString *)prop;
    if (answers && answers[answerKey]) {
        return CFBridgingRetain(answers[answerKey]);
    }
    NSString *anotherKey = nil;
    if ([answerKey isEqualToString:(__bridge NSString *)kMGProductType]) {
        anotherKey = kMewEncProductType;
    }
    else if ([answerKey isEqualToString:(__bridge NSString *)kMGSerialNumber]) {
        anotherKey = kMewEncSerialNumber;
    }
    else if ([answerKey isEqualToString:(__bridge NSString *)kMGUniqueDeviceID]) {
        anotherKey = kMewEncUniqueDeviceID;
    }
    else if ([answerKey isEqualToString:(__bridge NSString *)kMGUniqueDeviceID]) {
        anotherKey = kMewEncUniqueDeviceID;
    }
    else if ([answerKey isEqualToString:(__bridge NSString *)kMGUserAssignedDeviceName]) {
        anotherKey = kMewEncDeviceName;
    }
    else if ([answerKey isEqualToString:(__bridge NSString *)kMGHWModel]) {
        anotherKey = kMewEncProductHWModel;
    }
    else if ([answerKey isEqualToString:(__bridge NSString *)kMGComputerName]) {
        anotherKey = kMewEncDeviceName;
    }
    else if ([answerKey isEqualToString:(__bridge NSString *)kMGInternationalMobileEquipmentIdentity]) {
        anotherKey = kMewEncInternationalMobileEquipmentIdentity;
    }
    else if ([answerKey isEqualToString:(__bridge NSString *)kMGUniqueChipID]) {
        anotherKey = kMewEncUniqueChipID;
    }
    else if ([answerKey isEqualToString:(__bridge NSString *)kMGBluetoothAddress]) {
        anotherKey = kMewEncBluetoothAddress;
    }
    else if ([answerKey isEqualToString:(__bridge NSString *)kMGProductVersion]) {
        anotherKey = kMewEncSystemVersion;
    }
    else if ([answerKey isEqualToString:(__bridge NSString *)kMGBuildVersion]) {
        anotherKey = kMewEncSystemBuildVersion;
    }
    else if ([answerKey isEqualToString:(__bridge NSString *)kMGMLBSerialNumber]) {
        anotherKey = kMewEncMLBSerialNumber;
    }
    else if ([answerKey isEqualToString:(__bridge NSString *)kMGWifiAddress]) {
        anotherKey = kMewEncEthernetMacAddress;
    }
    else if ([answerKey isEqualToString:(__bridge NSString *)kMGModelNumber]) {
        anotherKey = kMewEncProductModel;
    }
    else if ([answerKey isEqualToString:(__bridge NSString *)kMGRegionCode]) {
        anotherKey = kMewEncRegionCode;
    }
    else if ([answerKey isEqualToString:(__bridge NSString *)kMGRegionInfo]) {
        anotherKey = kMewEncRegionInfo;
    }
    if (anotherKey && R(anotherKey)) {
        return CFBridgingRetain(R(anotherKey));
    }
    return orig_MGCopyAnswer(prop);
}

static BOOL (* _orig_NSArray_containsObject)(id _self, SEL _cmd1, id obj);
BOOL NSArray_containsObject(NSArray *_self, SEL _cmd1, id obj) {
    if (_self.count != 0) {
        if ([obj isKindOfClass:[NSString class]]) {
            NSArray <NSString *> *bypassList = R(kMewEncStringSearchBypassList);
            for (NSString *bypassSubstr in bypassList) {
                if ([bypassSubstr isEqualToString:obj]) {
                    return NO;
                }
            }
        }
    }
    return _orig_NSArray_containsObject(_self, _cmd1, obj);
}

static NSRange (* _orig_NSString_rangeOfString)(id _self, SEL _cmd1, id sub);
NSRange NSString_rangeOfString(NSString *_self, SEL _cmd1, NSString *sub) {
    if (_self.length != 0) {
        NSArray <NSString *> *bypassList = R(kMewEncStringSearchBypassList);
        for (NSString *bypassSubstr in bypassList) {
            if ([bypassSubstr isEqualToString:sub]) {
                return NSMakeRange(NSNotFound, NSNotFound);
            }
        }
    }
    return _orig_NSString_rangeOfString(_self, _cmd1, sub);
}

static IMP _orig_NSDictionary_newWithContentsOf_immutable;
NSDictionary *NSDictionary_newWithContentsOf_immutable(id _self, SEL _cmd1, NSString *path, BOOL immutable) {
    NSDictionary *result = _orig_NSDictionary_newWithContentsOf_immutable(_self, _cmd1, path, immutable);
    if ([path isEqualToString:kMewEncPlistSystemVersionPlistPath]) {
        NSMutableDictionary *mutableResult = [result mutableCopy];
        if (R(kMewEncSystemVersion)) {
            [mutableResult setObject:R(kMewEncSystemVersion) forKey:kMewEncPlistSystemVersionProductVersion];
        }
        if (R(kMewEncSystemBuildVersion)) {
            [mutableResult setObject:R(kMewEncSystemBuildVersion) forKey:kMewEncPlistSystemVersionProductBuildVersion];
        }
        if (R(kMewEncSystemName)) {
            [mutableResult setObject:R(kMewEncSystemName) forKey:kMewEncPlistSystemVersionProductName];
        }
        NSDictionary *newResult = [[NSDictionary alloc] initWithDictionary:mutableResult];
        [mutableResult release];
        return newResult;
    }
    return result;
}

struct CLLocationCoordinate2D {
    double latitude;
    double longitude;
};
typedef struct CLLocationCoordinate2D CLLocationCoordinate2D;
static BOOL useRandomLocation = NO;
static CLLocationCoordinate2D randomLocation;
static CLLocationCoordinate2D (* _orig_CLLocation_coordinate)(id _self, SEL _cmd1);
CLLocationCoordinate2D CLLocation_coordinate(id _self, SEL _cmd1) {
    if (useRandomLocation) {
        return randomLocation;
    }
    NSString *fakeLatitude = R(kMewEncCoordinateRegionLatitudeKey);
    NSString *fakeLongitude = R(kMewEncCoordinateRegionLongitudeKey);
    if (!fakeLatitude || !fakeLongitude) {
        return _orig_CLLocation_coordinate(_self, _cmd1);
    }
    CLLocationCoordinate2D coordinate;
    coordinate.latitude = [fakeLatitude doubleValue];
    coordinate.longitude = [fakeLongitude doubleValue];
    return coordinate;
}

@interface CLLocation : NSObject
@property(readonly, nonatomic) CLLocationCoordinate2D coordinate;
@property(readonly, nonatomic) double altitude;
@property(readonly, nonatomic) double horizontalAccuracy;
@property(readonly, nonatomic) double verticalAccuracy;
@property(readonly, nonatomic) double course;
@property(readonly, nonatomic) double speed;
@property(readonly, nonatomic, copy) NSDate *timestamp;
- (instancetype)initWithCoordinate:(CLLocationCoordinate2D)coordinate
                          altitude:(double)altitude
                horizontalAccuracy:(double)hAccuracy
                  verticalAccuracy:(double)vAccuracy
                            course:(double)course
                             speed:(double)speed
                         timestamp:(NSDate *)timestamp;
@end
static CLLocation *(* _orig_CLLocationManager_location)(id _self, SEL _cmd1);
static CLLocation *CLLocationManager_location(id _self, SEL _cmd1) {
    CLLocationCoordinate2D coordinate;
    CLLocation *location = _orig_CLLocationManager_location(_self, _cmd1);
    if (useRandomLocation) {
        coordinate.latitude = randomLocation.latitude;
        coordinate.longitude = randomLocation.longitude;
    } else {
        NSString *fakeLatitude = R(kMewEncCoordinateRegionLatitudeKey);
        NSString *fakeLongitude = R(kMewEncCoordinateRegionLongitudeKey);
        if (!fakeLatitude || !fakeLongitude) {
            return location;
        }
        coordinate.latitude = [fakeLatitude doubleValue];
        coordinate.longitude = [fakeLongitude doubleValue];
    }
    CLLocation *newLocation = [(CLLocation *)[objc_getClass("CLLocation") alloc] initWithCoordinate:coordinate
                                                                                           altitude:location.altitude
                                                                                 horizontalAccuracy:location.horizontalAccuracy
                                                                                   verticalAccuracy:location.verticalAccuracy
                                                                                             course:location.course
                                                                                              speed:location.speed
                                                                                          timestamp:location.timestamp];
    return [newLocation autorelease];
}

struct CTResult
{
    int flag;
    int a;
};

struct CTServerConnection
{
    int a;
    int b;
    CFMachPortRef port;
    int c;
    int d;
    int e;
    int f;
    int g;
    int h;
    int i;
};

int *  _CTServerConnectionCopyMobileIdentity(struct CTResult *, struct CTServerConnection *,  CFStringRef *);

int *  _CTServerConnectionCopyMobileEquipmentInfo(
                                                  struct CTResult *,
                                                  struct CTServerConnection *,
                                                  CFMutableDictionaryRef *
                                                  );

int *(* original_CTServerConnectionCopyMobileIdentity)(struct CTResult *res, struct CTServerConnection *connection, NSString **stringBuf);
static int * replaced_CTServerConnectionCopyMobileIdentity(struct CTResult *res, struct CTServerConnection *connection, NSString **stringBuf) {
    int *result = original_CTServerConnectionCopyMobileIdentity(res, connection, stringBuf);
    NSString *replaceIMEI = R(kMewEncInternationalMobileEquipmentIdentity);
    if (!replaceIMEI) {
        return result;
    }
    *stringBuf = [[NSString alloc] initWithString:replaceIMEI];
    return result;
}

#ifdef __arm64__
int *(* original_CTServerConnectionCopyMobileEquipmentInfo)(struct CTServerConnection *, CFDictionaryRef *, NSInteger *);
static int * replaced_CTServerConnectionCopyMobileEquipmentInfo(struct CTServerConnection *connection, CFDictionaryRef *dictBuf, NSInteger *unknown) {
    int *result = original_CTServerConnectionCopyMobileEquipmentInfo(connection, dictBuf, NULL);
#else
int *(* original_CTServerConnectionCopyMobileEquipmentInfo)(struct CTResult *, struct CTServerConnection *, CFDictionaryRef *);
static int * replaced_CTServerConnectionCopyMobileEquipmentInfo(struct CTResult *res, struct CTServerConnection *connection, CFDictionaryRef *dictBuf) {
    int *result = original_CTServerConnectionCopyMobileEquipmentInfo(res, connection, dictBuf);
#endif
    NSMutableDictionary *dict = [[NSMutableDictionary alloc] initWithDictionary:(__bridge NSDictionary *) *dictBuf];
    if (dict[kMewEncCTMobileEquipmentInfoIMEI] && R(kMewEncInternationalMobileEquipmentIdentity)) {
        dict[kMewEncCTMobileEquipmentInfoIMEI] = R(kMewEncInternationalMobileEquipmentIdentity);
    }
    if (dict[kMewEncCTMobileEquipmentInfoCurrentMobileId] && R(kMewEncCurrentMobileId)) {
        dict[kMewEncCTMobileEquipmentInfoCurrentMobileId] = R(kMewEncCurrentMobileId);
    }
    if (dict[kMewEncCTMobileEquipmentInfoICCID] && R(kMewEncICCID)) {
        dict[kMewEncCTMobileEquipmentInfoICCID] = R(kMewEncICCID);
    }
    if (dict[kMewEncCTMobileEquipmentInfoMEID] && R(kMewEncMEID)) {
        dict[kMewEncCTMobileEquipmentInfoMEID] = R(kMewEncMEID);
    }
    if (dict[kMewEncCTMobileEquipmentInfoIMSI] && R(kMewEncIMSI)) {
        dict[kMewEncCTMobileEquipmentInfoIMSI] = R(kMewEncIMSI);
    }
    if (dict[kMewEncCTMobileEquipmentInfoCurrentSubscriberId] && R(kMewEncCurrentSubscriberId)) {
        dict[kMewEncCTMobileEquipmentInfoCurrentSubscriberId] = R(kMewEncCurrentSubscriberId);
    }
    *dictBuf = CFBridgingRetain(dict);
    [dict release];
    return result;
}

typedef const struct CF_BRIDGED_TYPE(id) __SCNetworkInterface * SCNetworkInterfaceRef;
CFStringRef (* orig_SCNetworkInterfaceGetInterfaceType) (SCNetworkInterfaceRef anInterface);
const CFStringRef *orig_kSCNetworkInterfaceTypeIEEE80211;
CFStringRef (* orig_SCNetworkInterfaceGetBSDName) (SCNetworkInterfaceRef anInterface);
CFStringRef (* original_SCNetworkInterfaceGetHardwareAddressString)(SCNetworkInterfaceRef anInterface);
static CFStringRef replaced_SCNetworkInterfaceGetHardwareAddressString(SCNetworkInterfaceRef anInterface) {
    CFStringRef result = original_SCNetworkInterfaceGetHardwareAddressString(anInterface);
    if ([(__bridge NSString *)orig_SCNetworkInterfaceGetInterfaceType(anInterface) isEqualToString:(__bridge NSString * _Nonnull)(*orig_kSCNetworkInterfaceTypeIEEE80211)]) {
        NSString *ifNameString = (__bridge NSString *)orig_SCNetworkInterfaceGetBSDName(anInterface);
        NSDictionary *ifaddrs = R(kMewEncNetworkInterfaces);
        if (!ifaddrs) {
            return result;
        }
        if (ifNameString &&
            ifaddrs[ifNameString] &&
            ifaddrs[ifNameString][@"mac"]
            ) {
            const char *address = [ifaddrs[ifNameString][@"mac"] bytes];
            NSString *addressString = [NSString stringWithFormat:@"%02hhX:%02hhX:%02hhX:%02hhX:%02hhX:%02hhX", address[0], address[1], address[2], address[3], address[4], address[5]];
            return (__bridge CFStringRef) addressString;
        } else if ([ifNameString rangeOfString:@"en"].location != NSNotFound && R(kMewEncEthernetMacAddress)) {
            return (__bridge CFStringRef) R(kMewEncEthernetMacAddress);
        }
    }
    return result;
}

static IMP _orig_CTTelephonyNetworkInfo_currentRadioAccessTechnology;
NSString *CTTelephonyNetworkInfo_currentRadioAccessTechnology(id _self, SEL _cmd1) {
    NSNumber *networkType = R(kMewEncNetworkType);
    int nType = [networkType intValue];
    if (nType == 5) {
        // Wifi
    } else if (nType == 1) {
        // 2G
        return CTRadioAccessTechnologyGPRS;
    } else if (nType == 2) {
        // 3G
        return CTRadioAccessTechnologyWCDMA;
    } else if (nType == 3) {
        // 4G
        return CTRadioAccessTechnologyLTE;
    } else {
        // Unknown
    }
    
    return nil;
}

static IMP _orig_NSTimeZone_name;
NSString *NSTimeZone_name(id _self, SEL _cmd1) {
    NSString *timezoneName = R(kMewEncTimezoneName);
    if (timezoneName && [timezoneName isKindOfClass:[NSString class]]) {
        return timezoneName;
    }
    return _orig_NSTimeZone_name(_self, _cmd1);
}

static IMP _orig_NSTimeZone_data;
NSData *NSTimeZone_data(id _self, SEL _cmd1) {
    NSData *timezoneData = R(kMewEncTimezoneData);
    if (timezoneData && [timezoneData isKindOfClass:[NSData class]]) {
        return timezoneData;
    }
    return _orig_NSTimeZone_data(_self, _cmd1);
}

__attribute__((constructor))
__attribute((obfuscate))
static void initialize() {
    if (![R(kMewEncEnabled) boolValue]) {
        return;
    }
    
    mewStartTime = CFAbsoluteTimeGetCurrent();
    
    BOOL enabledApplication = NO;
    NSArray <NSString *> *appIdentifierList = R(kMewEncApplicationIdentifierWhiteList);
    NSArray <NSString *> *appBlackList = R(kMewEncApplicationIdentifierBlackList);
    NSString *bundleIdentifier = [[NSBundle mainBundle] bundleIdentifier];
    for (NSString *appIdentifier in appIdentifierList) {
        if ([appIdentifier isEqualToString:bundleIdentifier]) {
            enabledApplication = YES;
            break;
        }
    }
    for (NSString *appIdentifier in appBlackList) {
        if ([appIdentifier isEqualToString:bundleIdentifier]) {
            enabledApplication = NO;
            break;
        }
    }
    
    if (enabledApplication) {
        
        if ([R(kMewEncSwitchFakeJailbreak) boolValue]) {
            MSHookFunction(dladdr, replaced_dladdr, (void **) &original_dladdr);
            MSHookFunction(_dyld_get_image_name, replaced_dyld_get_image_name, (void **) &original_dyld_get_image_name);
            
            MSHookFunction(getenv, replaced_getenv, (void **) &original_getenv);
            
            MSHookFunction(stat, replaced_stat, (void **) &original_stat);
            MSHookFunction(access, replaced_access, (void **) &original_access);
            MSHookFunction(opendir, replaced_opendir, (void **) &original_opendir);
            MSHookFunction(fopen, replaced_fopen, (void **) &original_fopen);
            MSHookMessageEx(objc_getClass("NSFileManager"), @selector(fileExistsAtPath:), (IMP)NSFileManager_fileExistsAtPath, (IMP *)&_orig_NSFileManager_fileExistsAtPath);
            MSHookMessageEx(objc_getClass("NSFileManager"), @selector(fileExistsAtPath:isDirectory:), (IMP)NSFileManager_fileExistsAtPath_isDirectory, (IMP *)&_orig_NSFileManager_fileExistsAtPath_isDirectory);
            MSHookMessageEx(objc_getClass("NSFileManager"), @selector(contentsOfDirectoryAtPath:error:), (IMP)NSFileManager_contentsOfDirectoryAtPath_error, &_orig_NSFileManager_contentsOfDirectoryAtPath_error);
            
            MSHookMessageEx(objc_getClass("UIApplication"), @selector(canOpenURL:), (IMP)UIApplication_canOpenURL, (IMP *)&_orig_UIApplication_canOpenURL);
            
            MSHookMessageEx(objc_getClass("LSApplicationWorkspace"), @selector(allApplications), (IMP)LSApplicationWorkspace_allApplications, &_orig_LSApplicationWorkspace_allApplications);
            MSHookMessageEx(objc_getClass("LSApplicationWorkspace"), @selector(allInstalledApplications), (IMP)LSApplicationWorkspace_allInstalledApplications, &_orig_LSApplicationWorkspace_allInstalledApplications);
            MSHookMessageEx(objc_getClass("LSApplicationWorkspace"), @selector(deviceIdentifierForAdvertising), (IMP)LSApplicationWorkspace_deviceIdentifierForAdvertising, &_orig_LSApplicationWorkspace_deviceIdentifierForAdvertising);
            MSHookMessageEx(objc_getClass("LSApplicationWorkspace"), @selector(deviceIdentifierForVendor), (IMP)LSApplicationWorkspace_deviceIdentifierForVendor, &_orig_LSApplicationWorkspace_deviceIdentifierForVendor);
            MSHookMessageEx(objc_getClass("LSApplicationProxy"), @selector(deviceIdentifierForAdvertising), (IMP)LSApplicationProxy_deviceIdentifierForAdvertising, &_orig_LSApplicationProxy_deviceIdentifierForAdvertising);
            MSHookMessageEx(objc_getClass("LSApplicationProxy"), @selector(deviceIdentifierForVendor), (IMP)LSApplicationProxy_deviceIdentifierForVendor, &_orig_LSApplicationProxy_deviceIdentifierForVendor);
            MSHookMessageEx(objc_getClass("NSArray"), @selector(containsObject:), (IMP)NSArray_containsObject, (IMP *)&_orig_NSArray_containsObject);
            MSHookMessageEx(objc_getClass("NSString"), @selector(rangeOfString:), (IMP)NSString_rangeOfString, (IMP *)&_orig_NSString_rangeOfString);
        }
        if ([R(kMewEncSwitchFakeDeviceInfo) boolValue]) {
            MSHookFunction(uname, replace_uname, (void **)&original_uname);
            MSHookMessageEx(objc_getClass("UIDevice"), @selector(name), (IMP)UIDevice_name, &_orig_UIDevice_name);
            MSHookMessageEx(objc_getClass("UIDevice"), @selector(model), (IMP)UIDevice_model, &_orig_UIDevice_model);
            MSHookMessageEx(objc_getClass("UIDevice"), @selector(localizedModel), (IMP)UIDevice_localizedModel, &_orig_UIDevice_localizedModel);
            MSHookMessageEx(objc_getClass("UIDevice"), @selector(systemName), (IMP)UIDevice_systemName, &_orig_UIDevice_systemName);
            MSHookMessageEx(objc_getClass("UIDevice"), @selector(systemVersion), (IMP)UIDevice_systemVersion, &_orig_UIDevice_systemVersion);
            MSHookMessageEx(objc_getClass("UIDevice"), @selector(uniqueIdentifier), (IMP)UIDevice_uniqueIdentifier, &_orig_UIDevice_uniqueIdentifier);
            MSHookMessageEx(objc_getClass("UIDevice"), @selector(identifierForVendor), (IMP)UIDevice_identifierForVendor, &_orig_UIDevice_identifierForVendor);
            MSHookMessageEx(objc_getClass("UIDevice"), @selector(batteryState), (IMP)UIDevice_batteryState, (IMP *)&_orig_UIDevice_batteryState);
            MSHookMessageEx(objc_getClass("UIDevice"), @selector(batteryLevel), (IMP)UIDevice_batteryLevel, (IMP *)&_orig_UIDevice_batteryLevel);
            MSHookMessageEx(objc_getClass("UIScreen"), @selector(brightness), (IMP)UIScreen_brightness, (IMP *)&_orig_UIScreen_brightness);
            MSHookMessageEx(objc_getClass("ASIdentifierManager"), @selector(isAdvertisingTrackingEnabled), (IMP)ASIdentifierManager_isAdvertisingTrackingEnabled, (IMP *)&_orig_ASIdentifierManager_isAdvertisingTrackingEnabled);
            MSHookMessageEx(objc_getClass("ASIdentifierManager"), @selector(advertisingIdentifier), (IMP)ASIdentifierManager_advertisingIdentifier, (IMP *)&_orig_ASIdentifierManager_advertisingIdentifier);
            void *IOKit = dlopen("/System/Library/Frameworks/IOKit.framework/IOKit", RTLD_GLOBAL | RTLD_LAZY);
            if (IOKit) {
                CFTypeRef (*IORegistryEntryCreateCFProperty)(mach_port_t entry, CFStringRef key, CFAllocatorRef allocator, uint32_t options) = dlsym(IOKit, "IORegistryEntryCreateCFProperty");
                MSHookFunction(IORegistryEntryCreateCFProperty, replaced_IORegistryEntryCreateCFProperty, (void **)&original_IORegistryEntryCreateCFProperty);
                CFTypeRef (*IORegistryEntrySearchCFProperty)(io_registry_entry_t entry, const io_name_t plane, CFStringRef key, CFAllocatorRef allocator, IOOptionBits options) = dlsym(IOKit, "IORegistryEntrySearchCFProperty");
                MSHookFunction(IORegistryEntrySearchCFProperty, replaced_IORegistryEntrySearchCFProperty, (void **)&original_IORegistryEntrySearchCFProperty);
                kern_return_t (* IORegistryEntryCreateCFProperties)(io_registry_entry_t entry,
                                                                    CFMutableDictionaryRef *properties,
                                                                    CFAllocatorRef allocator,
                                                                    IOOptionBits options) = dlsym(IOKit, "IORegistryEntryCreateCFProperties");
                MSHookFunction(IORegistryEntryCreateCFProperties, replaced_IORegistryEntryCreateCFProperties, (void **)&original_IORegistryEntryCreateCFProperties);
            }
            MSHookFunction(sysctl, replaced_sysctl, (void **)&original_sysctl);
            MSHookFunction(sysctlbyname, replaced_sysctlbyname, (void **)&original_sysctlbyname);
            static CFStringRef (*$MGCopyAnswer)(CFStringRef);
            void *gestalt = dlopen("/usr/lib/libMobileGestalt.dylib", RTLD_GLOBAL | RTLD_LAZY);
            if (gestalt) {
                $MGCopyAnswer = dlsym(gestalt, "MGCopyAnswer");
                
                uint8_t MGCopyAnswer_arm64_impl[8] = {0x01, 0x00, 0x80, 0xd2, 0x01, 0x00, 0x00, 0x14};
                uint8_t MGCopyAnswer_armv7_impl[8] = {0x00, 0x21, 0x00, 0xf0, 0x01, 0xb8, 0x00, 0xbf};
                const uint8_t* MGCopyAnswer_ptr = (const uint8_t*) $MGCopyAnswer;
#ifdef __arm64__
                if (memcmp((void *)MGCopyAnswer_ptr, (void *)MGCopyAnswer_arm64_impl, 8) == 0) {
#else
                if (memcmp((void *)(MGCopyAnswer_ptr - 1), (void *)MGCopyAnswer_armv7_impl, 8) == 0) {
#endif
                    MSHookFunction((void *)(MGCopyAnswer_ptr + 8), (void*)new_MGCopyAnswer_internal, (void**)&orig_MGCopyAnswer_internal);
                } else {
                    MSHookFunction((void *)MGCopyAnswer_ptr, (void*)new_MGCopyAnswer, (void**)&orig_MGCopyAnswer);
                }
            }
            MSHookFunction(_CTServerConnectionCopyMobileIdentity, replaced_CTServerConnectionCopyMobileIdentity, (void **)&original_CTServerConnectionCopyMobileIdentity);
            MSHookFunction(_CTServerConnectionCopyMobileEquipmentInfo, replaced_CTServerConnectionCopyMobileEquipmentInfo, (void **)&original_CTServerConnectionCopyMobileEquipmentInfo);
            void * systemConfiguration = dlopen("/System/Library/Framework/SystemConfiguration.framework/SystemConfiguration", RTLD_GLOBAL | RTLD_LAZY);
            if (systemConfiguration) {
                CFStringRef (* _SCNetworkInterfaceGetHardwareAddressString)(SCNetworkInterfaceRef interface) = dlsym(systemConfiguration, "SCNetworkInterfaceGetHardwareAddressString");
                orig_SCNetworkInterfaceGetInterfaceType = dlsym(systemConfiguration, "SCNetworkInterfaceGetInterfaceType");
                orig_kSCNetworkInterfaceTypeIEEE80211 = dlsym(systemConfiguration, "kSCNetworkInterfaceTypeIEEE80211");
                orig_SCNetworkInterfaceGetBSDName = dlsym(systemConfiguration, "SCNetworkInterfaceGetBSDName");
                if (orig_SCNetworkInterfaceGetInterfaceType && orig_kSCNetworkInterfaceTypeIEEE80211 && orig_SCNetworkInterfaceGetBSDName) {
                    MSHookFunction(_SCNetworkInterfaceGetHardwareAddressString, replaced_SCNetworkInterfaceGetHardwareAddressString, (void **)&original_SCNetworkInterfaceGetHardwareAddressString);
                }
            }
            MSHookMessageEx(objc_getMetaClass("NSDictionary"), @selector(newWithContentsOf:immutable:), (IMP)NSDictionary_newWithContentsOf_immutable, (IMP *)&_orig_NSDictionary_newWithContentsOf_immutable);
        }
        if ([R(kMewEncSwitchFakeNetworkInfo) boolValue]) {
            MSHookMessageEx(objc_getClass("CTCarrier"), @selector(carrierName), (IMP)CTCarrier_carrierName, (IMP *)&_orig_CTCarrier_carrierName);
            MSHookMessageEx(objc_getClass("CTCarrier"), @selector(mobileCountryCode), (IMP)CTCarrier_mobileCountryCode, (IMP *)&_orig_CTCarrier_mobileCountryCode);
            MSHookMessageEx(objc_getClass("CTCarrier"), @selector(mobileNetworkCode), (IMP)CTCarrier_mobileNetworkCode, (IMP *)&_orig_CTCarrier_mobileNetworkCode);
            MSHookMessageEx(objc_getClass("CTCarrier"), @selector(isoCountryCode), (IMP)CTCarrier_isoCountryCode, (IMP *)&_orig_CTCarrier_isoCountryCode);
            MSHookMessageEx(objc_getClass("CTCarrier"), @selector(allowsVOIP), (IMP)CTCarrier_allowsVOIP, (IMP *)&_orig_CTCarrier_allowsVOIP);
            MSHookMessageEx(objc_getClass("UIStatusBarDataNetworkItemView"), @selector(valueForKeyPath:), (IMP)UIStatusBarDataNetworkItemView_valueForKeyPath, &_orig_UIStatusBarDataNetworkItemView_valueForKeyPath);
            MSHookMessageEx(objc_getClass("UIStatusBarServiceItemView"), @selector(valueForKey:), (IMP)UIStatusBarServiceItemView_valueForKey, &_orig_UIStatusBarServiceItemView_valueForKey);
            MSHookFunction(CNCopyCurrentNetworkInfo, replaced_CNCopyCurrentNetworkInfo, (void **)&original_CNCopyCurrentNetworkInfo);
            MSHookFunction(SCNetworkReachabilityGetFlags, replaced_SCNetworkReachabilityGetFlags, (void **)&original_SCNetworkReachabilityGetFlags);
            MSHookFunction(getifaddrs, replaced_getifaddrs, (void **)&original_getifaddrs);
            MSHookMessageEx(objc_getClass("CTTelephonyNetworkInfo"), @selector(currentRadioAccessTechnology), (IMP)CTTelephonyNetworkInfo_currentRadioAccessTechnology, (IMP *)&_orig_CTTelephonyNetworkInfo_currentRadioAccessTechnology);
        }
        if ([R(kMewEncSwitchFakeLocation) boolValue]) {
            MSHookMessageEx(objc_getClass("CLLocation"), @selector(coordinate), (IMP)CLLocation_coordinate, (IMP *)&_orig_CLLocation_coordinate);
            MSHookMessageEx(objc_getClass("CLLocationManager"), @selector(location), (IMP)CLLocationManager_location, (IMP *)&_orig_CLLocationManager_location);
            MSHookMessageEx(objc_getClass("NSTimeZone"), @selector(name), (IMP)NSTimeZone_name, (IMP *)&_orig_NSTimeZone_name);
            MSHookMessageEx(objc_getClass("NSTimeZone"), @selector(data), (IMP)NSTimeZone_data, (IMP *)&_orig_NSTimeZone_data);
            if ([R(kMewEncSwitchFakeRandomLocation) boolValue]) {
                randomLocation.latitude = ((arc4random() % RAND_MAX) / (RAND_MAX * 1.0)) * (90.0 - -90.0) + -90.0;
                randomLocation.longitude = ((arc4random() % RAND_MAX) / (RAND_MAX * 1.0)) * (180.0 - -180.0) + -180.0;
                useRandomLocation = YES;
            } else {
                useRandomLocation = NO;
            }
        }
        
    }
    
}

_Pragma("clang diagnostic pop")
