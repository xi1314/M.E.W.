//
//  MEWMain.c
//  MEW
//
//  Created by Zheng on 05/05/2017.
//

#import <errno.h>
#import <dlfcn.h>
#import <unistd.h>
#import <dirent.h>
#import <net/if.h>
#import <ifaddrs.h>
#import <sys/stat.h>
#import <substrate.h>
#import <arpa/inet.h>
#import <mach/port.h>
#import <sys/types.h>
#import <sys/sysctl.h>
#import <sys/utsname.h>
#import <mach-o/dyld.h>
#import <mach-o/arch.h>
#import <UIKit/UIKit.h>
#import <mach-o/loader.h>
#import <mach/mach_host.h>
#import <mach/kern_return.h>
#import "LSApplicationProxy.h"
#import <SystemConfiguration/CaptiveNetwork.h>
#import <SystemConfiguration/SCNetworkReachability.h>

#define kIODeviceTreePlane		"IODeviceTree"

enum {
    kIORegistryIterateRecursively	= 0x00000001,
    kIORegistryIterateParents		= 0x00000002
};

typedef mach_port_t	io_object_t;
typedef io_object_t	io_registry_entry_t;
typedef char		io_name_t[128];
typedef UInt32		IOOptionBits;

#pragma mark - Config

static NSString * const kMewConfigPath = @"/Library/MobileSubstrate/DynamicLibraries/MEWConfiguration.plist";
static CFAbsoluteTime mewStartTime = 0.f;
static NSDictionary *getMewConfig() {
    static NSDictionary *mewConfig = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSString *mewConfigPath = kMewConfigPath;
        NSDictionary *mewDict = [[NSDictionary alloc] initWithContentsOfFile:mewConfigPath];
        if (!mewDict)
            mewDict = [[NSDictionary alloc] initWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"MEWConfiguration" ofType:@"plist"]];
        assert(mewDict);
        mewConfig = mewDict;
    });
    return mewConfig;
}

#pragma mark - Dynamic Image Check

static NSString * const kMewReplaceImagePathList = @"ReplaceImagePathList";

int (*original_dladdr)(void *addr, Dl_info *info);
static int replaced_dladdr(void *addr, Dl_info *info) {
    NSArray <NSString *> *replaceList = getMewConfig()[kMewReplaceImagePathList];
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
        }
    }
    return result;
}

char *(* original_dyld_get_image_name)(int index);
static char *replaced_dyld_get_image_name(int index) {
    NSArray <NSString *> *replaceList = getMewConfig()[kMewReplaceImagePathList];
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

static NSString * const kMewReplaceEnvironmentVariableList = @"ReplaceEnvironmentVariableList";

char *(* original_getenv)(const char* name);
static char *replaced_getenv(const char* name) {
    NSArray <NSString *> *bypassList = getMewConfig()[kMewReplaceEnvironmentVariableList];
    for (NSString *bypassName in bypassList) {
        if (strcmp(name, bypassName.UTF8String) == 0) {
            
            return NULL;
        }
    }
    return original_getenv(name);
}

#pragma mark - File System Check
// There are so many system calls that check path, here we only hook part of them.

static NSString * const kMewPathCheckBypassList = @"PathCheckBypassList";

int (*original_stat)(const char *path, struct stat *info);
static int replaced_stat(const char *path, struct stat *info) {
    NSArray <NSString *> *bypassList = getMewConfig()[kMewPathCheckBypassList];
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
    NSArray <NSString *> *bypassList = getMewConfig()[kMewPathCheckBypassList];
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
    NSArray <NSString *> *bypassList = getMewConfig()[kMewPathCheckBypassList];
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
    NSArray <NSString *> *bypassList = getMewConfig()[kMewPathCheckBypassList];
    for (NSString *bypassPath in bypassList) {
        if (strcmp([bypassPath UTF8String], filename) == 0) {
            
            errno = ENOENT;
            return NULL;
        }
    }
    return original_fopen(filename, mode);
}

static IMP _orig_NSFileManager_fileExistsAtPath;
BOOL NSFileManager_fileExistsAtPath(id _self, SEL _cmd1, NSString *path) {
    NSArray <NSString *> *bypassList = getMewConfig()[kMewPathCheckBypassList];
    for (NSString *bypassPath in bypassList) {
        if ([bypassPath isEqualToString:path]) {
            
            return NO;
        }
    }
    return _orig_NSFileManager_fileExistsAtPath(_self, _cmd1, path);
}

static IMP _orig_NSFileManager_fileExistsAtPath_isDirectory;
BOOL NSFileManager_fileExistsAtPath_isDirectory(id _self, SEL _cmd1, NSString *path, BOOL *isDirectory) {
    NSArray <NSString *> *bypassList = getMewConfig()[kMewPathCheckBypassList];
    for (NSString *bypassPath in bypassList) {
        if ([bypassPath isEqualToString:path]) {
            
            return NO;
        }
    }
    return _orig_NSFileManager_fileExistsAtPath_isDirectory(_self, _cmd1, path, isDirectory);
}

static NSString * const kMewDirectoryCheckBypassList = @"DirectoryCheckBypassList";
static IMP _orig_NSFileManager_contentsOfDirectoryAtPath_error;
NSArray *NSFileManager_contentsOfDirectoryAtPath_error(id _self, SEL _cmd1, NSString *path, NSError **error) {
    NSArray <NSString *> *directoryList = getMewConfig()[kMewDirectoryCheckBypassList];
    for (NSString *directoryPath in directoryList) {
        if ([directoryPath isEqualToString:path]) {
            
            return [@[] autorelease];
        }
    }
    return _orig_NSFileManager_contentsOfDirectoryAtPath_error(_self, _cmd1, path, error);
}

#pragma mark - URL Scheme Check

static NSString * const kMewURLSchemeCheckBypassList = @"URLSchemeCheckBypassList";
static IMP _orig_UIApplication_canOpenURL;
BOOL UIApplication_canOpenURL(id _self, SEL _cmd1, NSURL *url) {
    NSArray <NSString *> *bypassList = getMewConfig()[kMewURLSchemeCheckBypassList];
    for (NSString *bypassPath in bypassList) {
        NSRange pathRange = [[url path] rangeOfString:bypassPath];
        if (pathRange.location != NSNotFound) {
            
            return NO;
        }
    }
    return _orig_UIApplication_canOpenURL(_self, _cmd1, url);
}

#pragma mark - Private APIs Check

static NSString * const kMewReplaceApplicationIdentifierList = @"ReplaceApplicationIdentifierList";

static IMP _orig_LSApplicationWorkspace_allApplications;
NSArray <LSApplicationProxy *> *LSApplicationWorkspace_allApplications(id _self, SEL _cmd1) {
    NSArray <NSString *> *filteredApplications = getMewConfig()[kMewReplaceApplicationIdentifierList];
    NSArray <LSApplicationProxy *> *result = _orig_LSApplicationWorkspace_allApplications(_self, _cmd1);
    if (!filteredApplications || filteredApplications.count == 0) {
        return result;
    }
    NSMutableArray <LSApplicationProxy *> *mutableResult = [result mutableCopy];
    NSMutableArray <LSApplicationProxy *> *removeApplications = [NSMutableArray array];
    for (LSApplicationProxy *appProxy in result) {
        for (NSString *appIdentifier in filteredApplications) {
            if ([appIdentifier isEqualToString:appProxy.applicationIdentifier]) {
                
                [removeApplications addObject:appProxy];
            }
        }
    }
    for (LSApplicationProxy *appProxy in removeApplications) {
        [mutableResult removeObject:appProxy];
    }
    return [[mutableResult copy] autorelease];
}

static IMP _orig_LSApplicationWorkspace_allInstalledApplications;
NSArray <LSApplicationProxy *> *LSApplicationWorkspace_allInstalledApplications(id _self, SEL _cmd1) {
    NSArray <NSString *> *filteredApplications = getMewConfig()[kMewReplaceApplicationIdentifierList];
    NSArray <LSApplicationProxy *> *result = _orig_LSApplicationWorkspace_allInstalledApplications(_self, _cmd1);
    if (!filteredApplications || filteredApplications.count == 0) {
        return result;
    }
    NSMutableArray <LSApplicationProxy *> *mutableResult = [result mutableCopy];
    NSMutableArray <LSApplicationProxy *> *removeApplications = [NSMutableArray array];
    for (LSApplicationProxy *appProxy in result) {
        for (NSString *appIdentifier in filteredApplications) {
            if ([appIdentifier isEqualToString:appProxy.applicationIdentifier]) {
                
                [removeApplications addObject:appProxy];
            }
        }
    }
    for (LSApplicationProxy *appProxy in removeApplications) {
        [mutableResult removeObject:appProxy];
    }
    return [[mutableResult copy] autorelease];
}

#pragma mark - Device Info Check

static NSString * const kMewDeviceName = @"DeviceName";
static IMP _orig_UIDevice_name;
NSString *UIDevice_name(id _self, SEL _cmd1) {
    NSString *fakeName = getMewConfig()[kMewDeviceName];
    if (!fakeName) {
        return _orig_UIDevice_name(_self, _cmd1);
    }
    return fakeName;
}

static NSString * const kMewMachineType = @"MachineType";
int (*original_uname)(struct utsname *uts);
static int replace_uname(struct utsname *uts) {
    NSString *fakeName = getMewConfig()[kMewDeviceName];
    NSString *fakeType = getMewConfig()[kMewMachineType];
    int result = original_uname(uts);
    if (fakeName && fakeType && fakeName.length != 0 && fakeType.length != 0) {
        strncpy(uts->nodename, [fakeName UTF8String], fakeName.length);
        strncpy(uts->machine, [fakeType UTF8String], fakeType.length);
    }
    return result;
}

static NSString * const kMewDeviceModel = @"DeviceModel";
static IMP _orig_UIDevice_model;
NSString *UIDevice_model(id _self, SEL _cmd1) {
    NSString *fakeModel = getMewConfig()[kMewDeviceModel];
    if (!fakeModel) {
        return _orig_UIDevice_model(_self, _cmd1);
    }
    return fakeModel;
}
static IMP _orig_UIDevice_localizedModel;
NSString *UIDevice_localizedModel(id _self, SEL _cmd1) {
    NSString *fakeModel = getMewConfig()[kMewDeviceModel];
    
    return fakeModel;
}

static NSString * const kMewSystemName = @"SystemName";
static IMP _orig_UIDevice_systemName;
NSString *UIDevice_systemName(id _self, SEL _cmd1) {
    NSString *fakeName = getMewConfig()[kMewSystemName];
    if (!fakeName) {
        return _orig_UIDevice_systemName(_self, _cmd1);
    }
    return fakeName;
}

static NSString * const kMewSystemVersion = @"SystemVersion";
static IMP _orig_UIDevice_systemVersion;
NSString *UIDevice_systemVersion(id _self, SEL _cmd1) {
    NSString *fakeVersion = getMewConfig()[kMewSystemVersion];
    if (!fakeVersion) {
        return _orig_UIDevice_systemVersion(_self, _cmd1);
    }
    return fakeVersion;
}

static NSString * const kMewUniqueIdentifier = @"UniqueIdentifier";
static IMP _orig_UIDevice_uniqueIdentifier;
NSString *UIDevice_uniqueIdentifier(id _self, SEL _cmd1) {
    NSString *fakeIdentifier = getMewConfig()[kMewUniqueIdentifier];
    if (!fakeIdentifier) {
        return _orig_UIDevice_uniqueIdentifier(_self, _cmd1);
    }
    return fakeIdentifier;
}

static NSString * const kMewIdentifierForVendor = @"IdentifierForVendor";
static IMP _orig_UIDevice_identifierForVendor;
NSUUID *UIDevice_identifierForVendor(id _self, SEL _cmd1) {
    NSString *fakeIdentifier = getMewConfig()[kMewIdentifierForVendor];
    if (!fakeIdentifier) {
        return _orig_UIDevice_identifierForVendor(_self, _cmd1);
    }
    return [[NSUUID alloc] initWithUUIDString:fakeIdentifier];
}

static NSString * const kMewDeviceBatteryState = @"DeviceBatteryState";
static NSUInteger (*_orig_UIDevice_batteryState)(id _self, SEL _cmd1);
NSUInteger UIDevice_batteryState(id _self, SEL _cmd1) {
    NSNumber *fakeState = getMewConfig()[kMewDeviceBatteryState];
    if (!fakeState) {
        return _orig_UIDevice_batteryState(_self, _cmd1);
    }
    return [fakeState unsignedIntegerValue];
}

static IMP _orig_UIDevice_batteryLevel;
float UIDevice_batteryLevel(id _self, SEL _cmd1) {
    float fakeLevel = -1.0f;
    CFAbsoluteTime timePassed = CFAbsoluteTimeGetCurrent() - mewStartTime;
    fakeLevel = .98f - (timePassed / (3600.f * 6));
    if (fakeLevel <= 0.f) {
        mewStartTime = CFAbsoluteTimeGetCurrent();
        fakeLevel = .98f;
    }
    return fakeLevel;
}

static NSString * const kMewNetworkType = @"NetworkType";
static IMP _orig_UIStatusBarDataNetworkItemView_valueForKeyPath;
id UIStatusBarDataNetworkItemView_valueForKeyPath(id _self, SEL _cmd1, NSString *keyPath) {
    if ([keyPath isEqualToString:@"dataNetworkType"]) {
        NSNumber *fakeType = getMewConfig()[kMewNetworkType];
        return fakeType;
    }
    return _orig_UIStatusBarDataNetworkItemView_valueForKeyPath(_self, _cmd1, keyPath);
}

static NSString * const kMewServiceString = @"ServiceString";
static IMP _orig_UIStatusBarServiceItemView_valueForKey;
id UIStatusBarServiceItemView_valueForKey(id _self, SEL _cmd1, NSString *keyPath) {
    if ([keyPath isEqualToString:@"serviceString"]) {
        NSString *fakeSerivceString = getMewConfig()[kMewServiceString];
        return fakeSerivceString;
    }
    return _orig_UIStatusBarServiceItemView_valueForKey(_self, _cmd1, keyPath);
}

static NSString * const kMewScreenBrightness = @"ScreenBrightness";
static float (*_orig_UIScreen_brightness)(id _self, SEL _cmd1);
float UIScreen_brightness(id _self, SEL _cmd1) {
    NSNumber *fakeBrightness = getMewConfig()[kMewScreenBrightness];
    if (!fakeBrightness) {
        return _orig_UIScreen_brightness(_self, _cmd1);
    }
    return [fakeBrightness floatValue];
}

static BOOL (*_orig_ASIdentifierManager_isAdvertisingTrackingEnabled)(id _self, SEL _cmd1);
BOOL ASIdentifierManager_isAdvertisingTrackingEnabled(id _self, SEL _cmd1) {
    
    return YES;
}

static NSString * const kMewAdvertisingIdentifier = @"AdvertisingIdentifier";
static IMP _orig_ASIdentifierManager_advertisingIdentifier;
NSUUID *ASIdentifierManager_advertisingIdentifier(id _self, SEL _cmd1) {
    NSString *fakeIdentifier = getMewConfig()[kMewAdvertisingIdentifier];
    if (!fakeIdentifier) {
        return _orig_ASIdentifierManager_advertisingIdentifier(_self, _cmd1);
    }
    return [[NSUUID alloc] initWithUUIDString:fakeIdentifier];
}

#pragma mark - Carrier Info Check

static NSString * const kMewCarrierName = @"CarrierName";
static IMP _orig_CTCarrier_carrierName;
NSString *CTCarrier_carrierName(id _self, SEL _cmd1) {
    NSString *fakeCarrierName = getMewConfig()[kMewCarrierName];
    if (!fakeCarrierName) {
        return _orig_CTCarrier_carrierName(_self, _cmd1);
    }
    return fakeCarrierName;
}

static NSString * const kMewCountryCode = @"CountryCode";
static IMP _orig_CTCarrier_mobileCountryCode;
NSString *CTCarrier_mobileCountryCode(id _self, SEL _cmd1) {
    NSString *fakeCountryCode = getMewConfig()[kMewCountryCode];
    if (!fakeCountryCode) {
        return _orig_CTCarrier_mobileCountryCode(_self, _cmd1);
    }
    return fakeCountryCode;
}

static NSString * const kMewNetworkCode = @"NetworkCode";
static IMP _orig_CTCarrier_mobileNetworkCode;
NSString *CTCarrier_mobileNetworkCode(id _self, SEL _cmd1) {
    NSString *fakeNetworkCode = getMewConfig()[kMewNetworkCode];
    if (!fakeNetworkCode) {
        return _orig_CTCarrier_mobileNetworkCode(_self, _cmd1);
    }
    return fakeNetworkCode;
}

static NSString * const kMewISOCountryCode = @"ISOCountryCode";
static IMP _orig_CTCarrier_isoCountryCode;
NSString *CTCarrier_isoCountryCode(id _self, SEL _cmd1) {
    NSString *fakeCountryCode = getMewConfig()[kMewISOCountryCode];
    if (!fakeCountryCode) {
        return _orig_CTCarrier_isoCountryCode(_self, _cmd1);
    }
    return fakeCountryCode;
}

static BOOL (*_orig_CTCarrier_allowsVOIP)(id _self, SEL _cmd1);
NSString *CTCarrier_allowsVOIP(id _self, SEL _cmd1) {
    
    return YES;
}

static NSString * const kMewNetworkInfo = @"NetworkInfo";
NSDictionary *(*original_CNCopyCurrentNetworkInfo)(NSString *ifname);
static NSDictionary *replaced_CNCopyCurrentNetworkInfo(NSString *ifname) {
    NSDictionary *networkInfo = getMewConfig()[kMewNetworkInfo][ifname];
    if (!networkInfo) {
        return original_CNCopyCurrentNetworkInfo(ifname);
    }
    return networkInfo;
}

Boolean (*original_SCNetworkReachabilityGetFlags)(SCNetworkReachabilityRef target, SCNetworkReachabilityFlags *flags);
static Boolean replaced_SCNetworkReachabilityGetFlags(SCNetworkReachabilityRef target, SCNetworkReachabilityFlags *flags) {
    if (flags != NULL) {
        NSNumber *networkType = getMewConfig()[kMewNetworkType];
        original_SCNetworkReachabilityGetFlags(target, flags);
        
        int nType = [networkType intValue];
        if (nType == 5) {
            *flags = 65538;
        } else if (nType == 1) {
            *flags = 262147;
        } else if (nType == 2) {
            *flags = 262147;
        } else if (nType == 3) {
            *flags = 262147;
        } else {
            *flags = 0;
        }
    }
    return true;
}

static NSString *kMewAddresses = @"Addresses";
int (*original_getifaddrs)(struct ifaddrs **interfaces);
static int replaced_getifaddrs(struct ifaddrs **interfaces) {
    NSDictionary *ipAddrs = getMewConfig()[kMewAddresses];
    int result = original_getifaddrs(interfaces);
    if (!ipAddrs) {
        return result;
    }
    struct ifaddrs *interface;
    for (interface = *interfaces; interface; interface = interface->ifa_next) {
        if(!(interface->ifa_flags & IFF_UP) /* || (interface->ifa_flags & IFF_LOOPBACK) */ ) {
            continue; // deeply nested code harder to read
        }
        char addrBuf[ MAX(INET_ADDRSTRLEN, INET6_ADDRSTRLEN) ];
        if (interface->ifa_addr && (((const struct sockaddr_in*)interface->ifa_addr)->sin_family == AF_INET || ((const struct sockaddr_in*)interface->ifa_addr)->sin_family == AF_INET6)) {
            NSString *name = [NSString stringWithUTF8String:interface->ifa_name];
            if (((const struct sockaddr_in*)interface->ifa_addr)->sin_family == AF_INET) {
                const struct sockaddr_in *addr = (const struct sockaddr_in*)interface->ifa_addr;
                if (inet_ntop(AF_INET, &addr->sin_addr, addrBuf, INET_ADDRSTRLEN)) {
                    if (ipAddrs[name][@"ipv4"]) {
                        const char *ipAddress = [ipAddrs[name][@"ipv4"] UTF8String];
                        inet_pton(AF_INET, ipAddress, (void *)&addr->sin_addr);
                    }
                }
            } else if (((const struct sockaddr_in*)interface->ifa_addr)->sin_family == AF_INET6) {
                const struct sockaddr_in6 *addr6 = (const struct sockaddr_in6*)interface->ifa_addr;
                if (inet_ntop(AF_INET6, &addr6->sin6_addr, addrBuf, INET6_ADDRSTRLEN)) {
                    if (ipAddrs[name][@"ipv6"]) {
                        inet_pton(AF_INET6, [ipAddrs[name][@"ipv6"] UTF8String], (void *)&addr6->sin6_addr);
                    }
                }
            }
        }
    }
    return result;
}

static NSString * const kMewIOSerialNumber = @"IOSerialNumber";
static NSString * const kMewIOUniqueIdentifier = @"IOUniqueIdentifier";
CFTypeRef (*original_IORegistryEntryCreateCFProperty)(mach_port_t entry, CFStringRef key, CFAllocatorRef allocator, uint32_t options);
static CFTypeRef replaced_IORegistryEntryCreateCFProperty(mach_port_t entry, CFStringRef key, CFAllocatorRef allocator, uint32_t options) {
    NSString *keyString = (__bridge NSString *)key;
    if ([keyString isEqualToString:@"IOPlatformSerialNumber"]) {
        CFTypeRef platformSerialNumber = original_IORegistryEntryCreateCFProperty(entry, key, allocator, options);
        if (platformSerialNumber && CFGetTypeID(platformSerialNumber) == CFStringGetTypeID())
        {
            NSString *replaceSerial = getMewConfig()[kMewIOSerialNumber];
            if (!replaceSerial) {
                return platformSerialNumber;
            }
            CFRelease(platformSerialNumber);
            return replaceSerial;
        }
    } else if ([keyString isEqualToString:@"IOPlatformUUID"]) {
        CFTypeRef platformUUID = original_IORegistryEntryCreateCFProperty(entry, key, allocator, options);
        if (platformUUID && CFGetTypeID(platformUUID) == CFStringGetTypeID())
        {
            NSString *replaceUUID = getMewConfig()[kMewIOUniqueIdentifier];
            if (!replaceUUID) {
                return platformUUID;
            }
            CFRelease(platformUUID);
            return replaceUUID;
        }
    }
    return original_IORegistryEntryCreateCFProperty(entry, key, allocator, options);
}

static NSString * const kMewMLBSerialNumber = @"MLBSerialNumber";
CFTypeRef
(* original_IORegistryEntrySearchCFProperty)(
                                    io_registry_entry_t	entry,
                                    const io_name_t		plane,
                                    CFStringRef		key,
                                    CFAllocatorRef		allocator,
                                    IOOptionBits		options );
static CFTypeRef replaced_IORegistryEntrySearchCFProperty(io_registry_entry_t entry, const io_name_t plane, CFStringRef key, CFAllocatorRef allocator, IOOptionBits options ) {
    NSString *keyString = (__bridge NSString *)key;
    if ([keyString isEqualToString:@"serial-number"]) {
        CFTypeRef platformSerialNumber = original_IORegistryEntrySearchCFProperty(entry, plane, key, allocator, options);
        if (platformSerialNumber && CFGetTypeID(platformSerialNumber) == CFDataGetTypeID())
        {
            NSString *replaceSerial = getMewConfig()[kMewIOSerialNumber];
            if (!replaceSerial) {
                return platformSerialNumber;
            }
            CFRelease(platformSerialNumber);
            return [replaceSerial dataUsingEncoding:NSUTF8StringEncoding];
        }
    } else if ([keyString isEqualToString:@"mlb-serial-number"]) {
        CFTypeRef platformSerialNumber = original_IORegistryEntrySearchCFProperty(entry, plane, key, allocator, options);
        if (platformSerialNumber && CFGetTypeID(platformSerialNumber) == CFDataGetTypeID())
        {
            NSString *replaceSerial = getMewConfig()[kMewMLBSerialNumber];
            if (!replaceSerial) {
                return platformSerialNumber;
            }
            CFRelease(platformSerialNumber);
            return [replaceSerial dataUsingEncoding:NSUTF8StringEncoding];
        }
    }
    return original_IORegistryEntrySearchCFProperty(entry, plane, key, allocator, options);
}

static NSString * const kMewMachineModel = @"MachineModel";
static NSString * const kMewSystemBuildVersion = @"SystemBuildVersion";
int	(* original_sysctlbyname)(const char *, void *, size_t *, const void *, size_t);
static int replaced_sysctlbyname(const char *name, void *oldp, size_t *oldlenp, const void *newp, size_t newlen) {
    int result = original_sysctlbyname(name, oldp, oldlenp, newp, newlen);
    NSString *replaceName = nil;
    if (strcmp(name, "kern.hostname") == 0) {
        replaceName = getMewConfig()[kMewDeviceName];
    } else if (strcmp(name, "hw.machine") == 0) {
        replaceName = getMewConfig()[kMewMachineType];
    } else if (strcmp(name, "hw.model") == 0) {
        replaceName = getMewConfig()[kMewMachineModel];
    } else if (strcmp(name, "kern.osversion") == 0) {
        replaceName = getMewConfig()[kMewSystemBuildVersion];
    }
    if (replaceName) {
        *oldlenp = strlen([replaceName UTF8String]) + 1;
        strcpy(oldp, [replaceName UTF8String]);
    }
    return result;
}

static NSString * const kMewMacAddressTips = @"It makes no sense to override MAC address above iOS 7, because you will always get 02:00:00:00:00:00 instead.";
int	(* original_sysctl)(const int *name, u_int namelen, void *oldp, size_t *oldlenp, const void *newp, size_t newlen);
static int replaced_sysctl(const int *name, u_int namelen, void *oldp, size_t *oldlenp, const void *newp, size_t newlen) {
    return original_sysctl(name, namelen, oldp, oldlenp, newp, newlen);
}

static NSString * const kMewReplaceMGCopyAnswer = @"ReplaceMGCopyAnswer";
static CFPropertyListRef (*orig_MGCopyAnswer_internal)(CFStringRef prop, uint32_t* outTypeCode);
CFPropertyListRef new_MGCopyAnswer_internal(CFStringRef prop, uint32_t* outTypeCode) {
    NSDictionary *answers = getMewConfig()[kMewReplaceMGCopyAnswer];
    NSString *answerKey = (__bridge NSString *)prop;
    if (answers && answers[answerKey]) {
        return answers[answerKey];
    }
    return orig_MGCopyAnswer_internal(prop, outTypeCode);
}

CFPropertyListRef MGCopyAnswer(CFStringRef prop);
static CFPropertyListRef (*orig_MGCopyAnswer)(CFStringRef prop);
CFPropertyListRef new_MGCopyAnswer(CFStringRef prop) {
    NSDictionary *answers = getMewConfig()[kMewReplaceMGCopyAnswer];
    NSString *answerKey = (__bridge NSString *)prop;
    if (answers && answers[answerKey]) {
        return answers[answerKey];
    }
    return orig_MGCopyAnswer(prop);
}

static NSString *const kMewStringSearchBypassList = @"StringSearchBypassList";
static BOOL (* _orig_NSArray_containsObject)(id _self, SEL _cmd1, id obj);
BOOL NSArray_containsObject(NSArray *_self, SEL _cmd1, id obj) {
    if (_self.count != 0) {
        if ([obj isKindOfClass:[NSString class]]) {
            NSArray <NSString *> *bypassList = getMewConfig()[kMewStringSearchBypassList];
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
        NSArray <NSString *> *bypassList = getMewConfig()[kMewStringSearchBypassList];
        for (NSString *bypassSubstr in bypassList) {
            if ([bypassSubstr isEqualToString:sub]) {
                return NSMakeRange(NSNotFound, NSNotFound);
            }
        }
    }
    return _orig_NSString_rangeOfString(_self, _cmd1, sub);
}

struct CLLocationCoordinate2D {
    double latitude;
    double longitude;
};
typedef struct CLLocationCoordinate2D CLLocationCoordinate2D;
static NSString *kMewFakeLocationCoordinate2D = @"FakeLocationCoordinate2D";
static CLLocationCoordinate2D (* _orig_CLLocation_coordinate)(id _self, SEL _cmd1);
CLLocationCoordinate2D CLLocation_coordinate(id _self, SEL _cmd1) {
    NSDictionary *fakeLocation = getMewConfig()[kMewFakeLocationCoordinate2D];
    if (!fakeLocation) {
        return _orig_CLLocation_coordinate(_self, _cmd1);
    }
    CLLocationCoordinate2D coordinate;
    coordinate.latitude = [fakeLocation[@"latitude"] doubleValue];
    coordinate.longitude = [fakeLocation[@"longitude"] doubleValue];
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
    NSDictionary *fakeLocation = getMewConfig()[kMewFakeLocationCoordinate2D];
    CLLocation *location = _orig_CLLocationManager_location(_self, _cmd1);
    if (!fakeLocation) {
        return location;
    }
    CLLocationCoordinate2D coordinate;
    coordinate.latitude = [fakeLocation[@"latitude"] doubleValue];
    coordinate.longitude = [fakeLocation[@"longitude"] doubleValue];
    CLLocation *newLocation = [(CLLocation *)[objc_getClass("CLLocation") alloc] initWithCoordinate:coordinate
                                                                                           altitude:location.altitude
                                                                                 horizontalAccuracy:location.horizontalAccuracy
                                                                                   verticalAccuracy:location.verticalAccuracy
                                                                                             course:location.course
                                                                                              speed:location.speed
                                                                                          timestamp:location.timestamp];
    return newLocation;
}

static void WillEnterForeground(CFNotificationCenterRef center, void *observer, CFStringRef name, const void *object, CFDictionaryRef userInfo)
{
    
}

static void ExternallyPostedNotification(CFNotificationCenterRef center, void *observer, CFStringRef name, const void *object, CFDictionaryRef userInfo)
{
    
}

static NSString * const kMewApplicationIdentifierWhiteList = @"ApplicationIdentifierWhiteList";
static NSString * const kMewApplicationIdentifierBlackList = @"ApplicationIdentifierBlackList";

__attribute__((constructor))
static void initialize() {
    mewStartTime = CFAbsoluteTimeGetCurrent();
    
    CFNotificationCenterRef center = CFNotificationCenterGetLocalCenter();
    CFNotificationCenterAddObserver(center, NULL, WillEnterForeground, CFSTR("UIApplicationWillEnterForegroundNotification"), NULL, CFNotificationSuspensionBehaviorCoalesce);
    
    CFNotificationCenterRef darwin = CFNotificationCenterGetDarwinNotifyCenter();
    CFNotificationCenterAddObserver(darwin, NULL, ExternallyPostedNotification, CFSTR("com.darwindev.mew.eventname"), NULL, CFNotificationSuspensionBehaviorCoalesce);
    
    BOOL enabledApplication = NO;
    NSArray <NSString *> *appIdentifierList = getMewConfig()[kMewApplicationIdentifierWhiteList];
    NSArray <NSString *> *appBlackList = getMewConfig()[kMewApplicationIdentifierBlackList];
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
        
        MSHookFunction(dladdr, replaced_dladdr, (void **) &original_dladdr);
        MSHookFunction(_dyld_get_image_name, replaced_dyld_get_image_name, (void **) &original_dyld_get_image_name);
        
        MSHookFunction(getenv, replaced_getenv, (void **) &original_getenv);
        
        MSHookFunction(stat, replaced_stat, (void **) &original_stat);
        MSHookFunction(access, replaced_access, (void **) &original_access);
        MSHookFunction(opendir, replaced_opendir, (void **) &original_opendir);
        MSHookFunction(fopen, replaced_fopen, (void **) &original_fopen);
        MSHookMessageEx(objc_getClass("NSFileManager"), @selector(fileExistsAtPath:), (IMP)NSFileManager_fileExistsAtPath, &_orig_NSFileManager_fileExistsAtPath);
        MSHookMessageEx(objc_getClass("NSFileManager"), @selector(fileExistsAtPath:isDirectory:), (IMP)NSFileManager_fileExistsAtPath_isDirectory, &_orig_NSFileManager_fileExistsAtPath_isDirectory);
        MSHookMessageEx(objc_getClass("NSFileManager"), @selector(contentsOfDirectoryAtPath:error:), (IMP)NSFileManager_contentsOfDirectoryAtPath_error, &_orig_NSFileManager_contentsOfDirectoryAtPath_error);
        
        MSHookMessageEx(objc_getClass("UIApplication"), @selector(canOpenURL:), (IMP)UIApplication_canOpenURL, &_orig_UIApplication_canOpenURL);
        
        MSHookMessageEx(objc_getClass("LSApplicationWorkspace"), @selector(allApplications), (IMP)LSApplicationWorkspace_allApplications, &_orig_LSApplicationWorkspace_allApplications);
        MSHookMessageEx(objc_getClass("LSApplicationWorkspace"), @selector(allInstalledApplications), (IMP)LSApplicationWorkspace_allInstalledApplications, &_orig_LSApplicationWorkspace_allInstalledApplications);
        
        MSHookFunction(uname, replace_uname, (void **)&original_uname);
        MSHookMessageEx(objc_getClass("UIDevice"), @selector(name), (IMP)UIDevice_name, &_orig_UIDevice_name);
        MSHookMessageEx(objc_getClass("UIDevice"), @selector(model), (IMP)UIDevice_model, &_orig_UIDevice_model);
        MSHookMessageEx(objc_getClass("UIDevice"), @selector(localizedModel), (IMP)UIDevice_localizedModel, &_orig_UIDevice_localizedModel);
        MSHookMessageEx(objc_getClass("UIDevice"), @selector(systemName), (IMP)UIDevice_systemName, &_orig_UIDevice_systemName);
        MSHookMessageEx(objc_getClass("UIDevice"), @selector(systemVersion), (IMP)UIDevice_systemVersion, &_orig_UIDevice_systemVersion);
        MSHookMessageEx(objc_getClass("UIDevice"), @selector(uniqueIdentifier), (IMP)UIDevice_uniqueIdentifier, &_orig_UIDevice_uniqueIdentifier);
        MSHookMessageEx(objc_getClass("UIDevice"), @selector(identifierForVendor), (IMP)UIDevice_identifierForVendor, &_orig_UIDevice_identifierForVendor);
        MSHookMessageEx(objc_getClass("UIDevice"), @selector(batteryState), (IMP)UIDevice_batteryState, (IMP *)&_orig_UIDevice_batteryState);
        MSHookMessageEx(objc_getClass("UIDevice"), @selector(batteryLevel), (IMP)UIDevice_batteryLevel, &_orig_UIDevice_batteryLevel);
        MSHookMessageEx(objc_getClass("UIScreen"), @selector(brightness), (IMP)UIScreen_brightness, (IMP *)&_orig_UIScreen_brightness);
        MSHookMessageEx(objc_getClass("ASIdentifierManager"), @selector(isAdvertisingTrackingEnabled), (IMP)ASIdentifierManager_isAdvertisingTrackingEnabled, (IMP *)&_orig_ASIdentifierManager_isAdvertisingTrackingEnabled);
        MSHookMessageEx(objc_getClass("ASIdentifierManager"), @selector(advertisingIdentifier), (IMP)ASIdentifierManager_advertisingIdentifier, (IMP *)&_orig_ASIdentifierManager_advertisingIdentifier);
        void *IOKit = dlopen("/System/Library/Frameworks/IOKit.framework/IOKit", RTLD_GLOBAL | RTLD_LAZY);
        if (IOKit) {
            CFTypeRef (*IORegistryEntryCreateCFProperty)(mach_port_t entry, CFStringRef key, CFAllocatorRef allocator, uint32_t options) = dlsym(IOKit, "IORegistryEntryCreateCFProperty");
            MSHookFunction(IORegistryEntryCreateCFProperty, replaced_IORegistryEntryCreateCFProperty, (void **)&original_IORegistryEntryCreateCFProperty);
            CFTypeRef (*IORegistryEntrySearchCFProperty)(io_registry_entry_t	entry, const io_name_t plane, CFStringRef key, CFAllocatorRef allocator, IOOptionBits options) = dlsym(IOKit, "IORegistryEntrySearchCFProperty");
            MSHookFunction(IORegistryEntrySearchCFProperty, replaced_IORegistryEntrySearchCFProperty, (void **)&original_IORegistryEntrySearchCFProperty);
        }
        MSHookFunction(sysctl, replaced_sysctl, (void **)&original_sysctl);
        MSHookFunction(sysctlbyname, replaced_sysctlbyname, (void **)&original_sysctlbyname);
        
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
        
        static CFStringRef (*$MGCopyAnswer)(CFStringRef);
        void *gestalt = dlopen("/usr/lib/libMobileGestalt.dylib", RTLD_GLOBAL | RTLD_LAZY);
        if (gestalt) {
            $MGCopyAnswer = dlsym(gestalt, "MGCopyAnswer");
            
            uint8_t MGCopyAnswer_arm64_impl[8] = {0x01, 0x00, 0x80, 0xd2, 0x01, 0x00, 0x00, 0x14};
            const uint8_t* MGCopyAnswer_ptr = (const uint8_t*) $MGCopyAnswer;
            if (memcmp(MGCopyAnswer_ptr, MGCopyAnswer_arm64_impl, 8) == 0) {
                MSHookFunction((void *)(MGCopyAnswer_ptr + 8), (void*)new_MGCopyAnswer_internal, (void**)&orig_MGCopyAnswer_internal);
            } else {
                MSHookFunction((void *)MGCopyAnswer_ptr, (void*)new_MGCopyAnswer, (void**)&orig_MGCopyAnswer);
            }
        }
        
        MSHookMessageEx(objc_getClass("NSArray"), @selector(containsObject:), (IMP)NSArray_containsObject, (IMP *)&_orig_NSArray_containsObject);
        MSHookMessageEx(objc_getClass("NSString"), @selector(rangeOfString:), (IMP)NSString_rangeOfString, (IMP *)&_orig_NSString_rangeOfString);
        
        MSHookMessageEx(objc_getClass("CLLocation"), @selector(coordinate), (IMP)CLLocation_coordinate, (IMP *)&_orig_CLLocation_coordinate);
        MSHookMessageEx(objc_getClass("CLLocationManager"), @selector(location), (IMP)CLLocationManager_location, (IMP *)&_orig_CLLocationManager_location);
        
    }
    
}
