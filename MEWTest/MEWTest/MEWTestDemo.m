//
//  MEWTestDemo.m
//  MEWTest
//
//  Created by Zheng on 06/05/2017.
//  Copyright © 2017 Zheng. All rights reserved.
//

#import "MEWTestDemo.h"
#import "IPAddress.h"
#import "LSApplicationProxy.h"
#import <dlfcn.h>
#import <dirent.h>
#import <unistd.h>
#import <net/if.h>
#import <ifaddrs.h>
#import <sys/stat.h>
#import <sys/types.h>
#import <net/if_dl.h>
#import <mach/port.h>
#import <arpa/inet.h>
#import <sys/socket.h>
#import <sys/sysctl.h>
#import <netinet/in.h>
#import <mach-o/dyld.h>
#import <mach-o/arch.h>
#import <sys/utsname.h>
#import <objc/runtime.h>
#import <mach-o/loader.h>
#import <mach/mach_host.h>
#import <mach/kern_return.h>
#import <AdSupport/AdSupport.h>
#import <CoreTelephony/CTCarrier.h>
#import <CoreLocation/CoreLocation.h>
#import <SystemConfiguration/CaptiveNetwork.h>
#import <CoreTelephony/CTTelephonyNetworkInfo.h>
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

NSString *getValue(NSString *iosearch)
{
    void *IOKit = dlopen("/System/Library/Frameworks/IOKit.framework/IOKit", RTLD_NOW);
    if (IOKit)
    {
        CFTypeRef
        (* IORegistryEntrySearchCFProperty)(
                                            io_registry_entry_t	entry,
                                            const io_name_t		plane,
                                            CFStringRef		key,
                                            CFAllocatorRef		allocator,
                                            IOOptionBits		options ) = dlsym(IOKit, "IORegistryEntrySearchCFProperty");
        kern_return_t
        (* IOMasterPort)( mach_port_t	bootstrapPort,
                         mach_port_t *	masterPort ) = dlsym(IOKit, "IOMasterPort");
        io_registry_entry_t
        (* IORegistryGetRootEntry)( mach_port_t	masterPort ) = dlsym(IOKit, "IORegistryGetRootEntry");
        
        kern_return_t   (* mach_port_deallocate)
        (ipc_space_t                               task,
         mach_port_name_t                          name) = dlsym(IOKit, "mach_port_deallocate");
        
        mach_port_t          masterPort;
        CFTypeID             propID = (CFTypeID) NULL;
        CFIndex              bufSize;
        
        kern_return_t kr = IOMasterPort(MACH_PORT_NULL, &masterPort);
        if (kr != noErr) return nil;
        
        io_registry_entry_t entry = IORegistryGetRootEntry(masterPort);
        if (entry == MACH_PORT_NULL) return nil;
        
        CFTypeRef prop = IORegistryEntrySearchCFProperty(entry, kIODeviceTreePlane, (__bridge CFStringRef) iosearch, nil, kIORegistryIterateRecursively);
        if (!prop) return nil;
        
        propID = CFGetTypeID(prop);
        if (!(propID == CFDataGetTypeID()))
        {
            mach_port_deallocate(mach_task_self(), masterPort);
            return nil;
        }
        
        CFDataRef propData = (CFDataRef) prop;
        if (!propData) return nil;
        
        bufSize = CFDataGetLength(propData);
        if (!bufSize) return nil;
        
        NSString *p1 = [[NSString alloc] initWithBytes:CFDataGetBytePtr(propData) length:bufSize encoding:NSUTF8StringEncoding];
        mach_port_deallocate(mach_task_self(), masterPort);
        return p1;
    }
    
    return nil;
}

@interface MEWTestDemo ()

@end

@implementation MEWTestDemo

- (NSString *) getSysInfoByName:(char *)typeSpecifier
{
    size_t size = 1024;
    
    char *answer = malloc(size);
    sysctlbyname(typeSpecifier, answer, &size, NULL, 0);
    
    NSString *results = [NSString stringWithCString:answer encoding: NSUTF8StringEncoding];
    
    free(answer);
    return results;
}

- (void)test {
    
    uint32_t count = _dyld_image_count();
    for (uint32_t i = 0; i < count; i++)
    {
        const char *image_name = _dyld_get_image_name(i);
        NSAssert(!strstr(image_name, "MobileSubstrate"), @"INTEGRITY CHECK FAILED");
    }
    
    NSAssert(getenv("DYLD_INSERT_LIBRARIES") == NULL
             , @"ENVIRONMENT VARIABLE CHECK FAILED");
    
    NSAssert (![[NSFileManager defaultManager] fileExistsAtPath:@"/Applications/Cydia.app"] &&
              stat("/bin/bash", NULL) == -1 &&
              access("/bin/sh", F_OK) == -1 &&
              opendir("/var/lib") == NULL &&
              fopen("/bin/bash", "r") == NULL
              , @"FILESYSTEM CHECK FAILED");
    
    NSAssert (![[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"cydia://"]]
              , @"URL SCHEME CHECK FAILED");
    
    Class LSApplicationWorkspace_class = objc_getClass("LSApplicationWorkspace");
    SEL selector = NSSelectorFromString(@"defaultWorkspace");
    NSObject *workspace = [LSApplicationWorkspace_class performSelector:selector];
    SEL selectorAll = NSSelectorFromString(@"allApplications");
    NSArray <LSApplicationProxy *> *allApplications = [workspace performSelector:selectorAll];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"applicationIdentifier CONTAINS[cd] %@", @"Cydia"];
    
    NSAssert([allApplications filteredArrayUsingPredicate:predicate].count == 0
             , @"PRIVATE API CHECK FAILED");
    
    NSLog(@"%@", [[UIDevice currentDevice] name]);
    NSLog(@"%@", [[UIDevice currentDevice] model]);
    NSLog(@"%@", [[UIDevice currentDevice] localizedModel]);
    NSLog(@"%@", [[UIDevice currentDevice] systemName]);
    NSLog(@"%@", [[UIDevice currentDevice] systemVersion]);
    if ([[UIDevice currentDevice] respondsToSelector:@selector(uniqueIdentifier)]) {
        NSLog(@"%@", [[UIDevice currentDevice] performSelector:@selector(uniqueIdentifier)]);
    }
    NSLog(@"%@", [[UIDevice currentDevice] identifierForVendor]);
    NSLog(@"%ld", (long)[[UIDevice currentDevice] batteryState]);
    NSLog(@"%f", [[UIDevice currentDevice] batteryLevel]);
    UIApplication *app = [UIApplication sharedApplication];
    
    NSArray *children = [[[app valueForKeyPath:@"statusBar"] valueForKeyPath:@"foregroundView"] subviews];
    
    NSString *serviceString = nil;
    int type = 0;
    for (id child in children) {
        if ([child isKindOfClass:NSClassFromString(@"UIStatusBarDataNetworkItemView")]) {
            type = [[child valueForKeyPath:@"dataNetworkType"] intValue];
        }
    }
    for (id child in children) {
        if ([child isKindOfClass:NSClassFromString(@"UIStatusBarServiceItemView")]) {
            serviceString = [child valueForKey:@"serviceString"];
        }
    }
    NSLog(@"%d", type);
    // Wifi - 5
    // 4G - 3
    // 3G - 2
    // 2G - 1
    NSLog(@"%@", serviceString);
    
    NSLog(@"%@", [[NSFileManager defaultManager] contentsOfDirectoryAtPath:@"/Applications" error:nil]);
    NSLog(@"%f", [[UIScreen mainScreen] brightness]);
    
    NSLog(@"%@", [[ASIdentifierManager sharedManager] advertisingIdentifier]);
    
    CTTelephonyNetworkInfo *info = [[CTTelephonyNetworkInfo alloc] init];
    CTCarrier *carrier = info.subscriberCellularProvider;
    NSString *carrierName = carrier.carrierName;
    NSString *mobileCountryCode = carrier.mobileCountryCode;
    NSString *mobileNetworkCode = carrier.mobileNetworkCode;
    NSString *isoCountryCode = carrier.isoCountryCode;
    NSLog(@"%@", carrierName);
    NSLog(@"%@", mobileCountryCode);
    NSLog(@"%@", mobileNetworkCode);
    NSLog(@"%@", isoCountryCode);
    
    NSArray *ifs = (__bridge  id)CNCopySupportedInterfaces();
    for (NSString *ifname in ifs) {
        NSDictionary *info = (__bridge id)CNCopyCurrentNetworkInfo((__bridge CFStringRef)ifname);
        NSLog(@"%@", info);
    }
    
    struct sockaddr_in zeroAddress;
    bzero(&zeroAddress, sizeof(zeroAddress));
    zeroAddress.sin_len = sizeof(zeroAddress);
    zeroAddress.sin_family = AF_INET;
    SCNetworkReachabilityRef defaultRouteReachability = SCNetworkReachabilityCreateWithAddress(NULL, (struct sockaddr *)&zeroAddress);
    SCNetworkReachabilityFlags flags;
    SCNetworkReachabilityGetFlags(defaultRouteReachability, &flags);
    CFRelease(defaultRouteReachability);
    
    NSLog(@"%u, Cellular = %d", flags, (flags & kSCNetworkReachabilityFlagsIsWWAN) != 0);
    
    struct utsname systemInfo;
    NSLog(@"%d", uname(&systemInfo));
    NSLog(@"%s", systemInfo.sysname);
    NSLog(@"%s", systemInfo.nodename);
    NSLog(@"%s", systemInfo.release);
    NSLog(@"%s", systemInfo.version);
    NSLog(@"%s", systemInfo.machine);
    
    NSMutableDictionary *addresses = [NSMutableDictionary dictionaryWithCapacity:8];
    // retrieve the current interfaces - returns 0 on success
    struct ifaddrs *interfaces;
    if(!getifaddrs(&interfaces)) {
        // Loop through linked list of interfaces
        struct ifaddrs *interface;
        for (interface = interfaces; interface; interface = interface->ifa_next) {
            if(!(interface->ifa_flags & IFF_UP) /* || (interface->ifa_flags & IFF_LOOPBACK) */ ) {
                continue; // deeply nested code harder to read
            }
            const struct sockaddr_in *addr = (const struct sockaddr_in*)interface->ifa_addr;
            char addrBuf[ MAX(INET_ADDRSTRLEN, INET6_ADDRSTRLEN) ];
            if (addr && (addr->sin_family == AF_INET || addr->sin_family == AF_INET6)) {
                NSString *name = [NSString stringWithUTF8String:interface->ifa_name];
                NSString *type;
                if (addr->sin_family == AF_INET) {
                    if(inet_ntop(AF_INET, &addr->sin_addr, addrBuf, INET_ADDRSTRLEN)) {
                        type = @"ipv4";
                    }
                } else {
                    const struct sockaddr_in6 *addr6 = (const struct sockaddr_in6*)interface->ifa_addr;
                    if(inet_ntop(AF_INET6, &addr6->sin6_addr, addrBuf, INET6_ADDRSTRLEN)) {
                        type = @"ipv6";
                    }
                }
                if (type) {
                    NSString *key = [NSString stringWithFormat:@"%@/%@", name, type];
                    addresses[key] = [NSString stringWithUTF8String:addrBuf];
                }
            }
            else if (
                     (interface->ifa_addr->sa_family == AF_LINK)
                     && (((const struct sockaddr_dl *) interface->ifa_addr)->sdl_type == 0x6)
                     ) {
                const struct sockaddr_dl * dlAddr = (const struct sockaddr_dl *) interface->ifa_addr;
                const unsigned char* base = (const unsigned char*) &dlAddr->sdl_data[dlAddr->sdl_nlen];
                char macAddress[32] = "";
                for (int i = 0; i < dlAddr->sdl_alen; i++) {
                    if (i != 0) {
                        strcat(macAddress, ":");
                    }
                    char partialAddr[3];
                    sprintf(partialAddr, "%02X", base[i]);
                    strcat(macAddress, partialAddr);
                }
                NSLog(@"%s", macAddress); // Always return 02:00:00:00:00:00
            }
        }
        // Free memory
        freeifaddrs(interfaces);
    }
    NSLog(@"%@", addresses);
    
    int                 mgmtInfoBase[6];
    char                *msgBuffer = NULL;
    size_t              length;
    unsigned char       macAddress[6];
    struct if_msghdr    *interfaceMsgStruct;
    struct sockaddr_dl  *socketStruct;
    NSString            *errorFlag = NULL;
    
    // Setup the management Information Base (mib)
    mgmtInfoBase[0] = CTL_NET;        // Request network subsystem
    mgmtInfoBase[1] = AF_ROUTE;       // Routing table info
    mgmtInfoBase[2] = 0;
    mgmtInfoBase[3] = AF_LINK;        // Request link layer information
    mgmtInfoBase[4] = NET_RT_IFLIST;  // Request all configured interfaces
    
    // With all configured interfaces requested, get handle index
    if ((mgmtInfoBase[5] = if_nametoindex("en0")) == 0)
        errorFlag = @"if_nametoindex failure";
    else
    {
        // Get the size of the data available (store in len)
        if (sysctl(mgmtInfoBase, 6, NULL, &length, NULL, 0) < 0)
            errorFlag = @"sysctl mgmtInfoBase failure";
        else
        {
            // Alloc memory based on above call
            if ((msgBuffer = malloc(length)) == NULL)
                errorFlag = @"buffer allocation failure";
            else
            {
                // Get system information, store in buffer
                if (sysctl(mgmtInfoBase, 6, msgBuffer, &length, NULL, 0) < 0)
                    errorFlag = @"sysctl msgBuffer failure";
            }
        }
    }
    
    // Befor going any further...
    if (errorFlag != NULL)
    {
        
    }
    
    // Map msgbuffer to interface message structure
    interfaceMsgStruct = (struct if_msghdr *) msgBuffer;
    
    // Map to link-level socket structure
    socketStruct = (struct sockaddr_dl *) (interfaceMsgStruct + 1);
    
    // Copy link layer address data in socket structure to an array
    memcpy(&macAddress, socketStruct->sdl_data + socketStruct->sdl_nlen, 6);
    
    // Read from char array into a string object, into traditional Mac address format
    NSString *macAddressString = [NSString stringWithFormat:@"%02X:%02X:%02X:%02X:%02X:%02X",
                                  macAddress[0], macAddress[1], macAddress[2],
                                  macAddress[3], macAddress[4], macAddress[5]];
    NSLog(@"Mac Address: %@", macAddressString);  // Always return 02:00:00:00:00:00
    
    // Release the buffer memory
    free(msgBuffer);
    
    NSString *serialNumber = nil;
    NSString *uuid = nil;
    
    void *IOKit = dlopen("/System/Library/Frameworks/IOKit.framework/IOKit", RTLD_NOW);
    if (IOKit)
    {
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
                CFTypeRef platformSerialNumber = IORegistryEntryCreateCFProperty(platformExpertDevice, CFSTR("IOPlatformSerialNumber"), kCFAllocatorDefault, 0);
                if (CFGetTypeID(platformSerialNumber) == CFStringGetTypeID())
                {
                    serialNumber = [NSString stringWithString:(__bridge NSString*)platformSerialNumber];
                    CFRelease(platformSerialNumber);
                }
                
                CFTypeRef platformUUID = IORegistryEntryCreateCFProperty(platformExpertDevice, CFSTR("IOPlatformUUID"), kCFAllocatorDefault, 0);
                if (CFGetTypeID(platformUUID) == CFStringGetTypeID())
                {
                    uuid = [NSString stringWithString:(__bridge NSString*)platformUUID];
                    CFRelease(platformUUID);
                }
                
                IOObjectRelease(platformExpertDevice);
            }
        }
        dlclose(IOKit);
    }
    
    NSLog(@"%@", serialNumber);
    NSLog(@"%@", uuid);
    
    NSLog(@"%@", getValue(@"serial-number"));
    NSLog(@"%@", getValue(@"mlb-serial-number"));
    
    NSLog(@"%@", [self getSysInfoByName:"kern.hostname"]);
    NSLog(@"%@", [self getSysInfoByName:"hw.machine"]);
    NSLog(@"%@", [self getSysInfoByName:"hw.model"]);
    NSLog(@"%@", [self getSysInfoByName:"kern.osversion"]);
    
    static CFStringRef (*$MGCopyAnswer)(CFStringRef);
    void *gestalt = dlopen("/usr/lib/libMobileGestalt.dylib", RTLD_GLOBAL | RTLD_LAZY);
    $MGCopyAnswer = dlsym(gestalt, "MGCopyAnswer");
    
    // Common form: MGCopyAnswer(CFStringRef string);
    CFStringRef value = $MGCopyAnswer(CFSTR("HardwarePlatform"));
    NSLog(@"%@", value);
    CFRelease(value);
    
    NSArray *arrTest = @[@"Cydia.app", @"Hello.app", @"System.app"];
    NSLog(@"%d", [arrTest containsObject:@"Cydia.app"]);
    
    NSRange checkRange = [@"/Applications/Cydia.app" rangeOfString:@"Cydia.app"];
    NSLog(@"%d", checkRange.location != NSNotFound);
    
    InitAddresses();
    GetIPAddresses();
    GetHWAddresses();
    
    int i;
    for (i=0; i < MAXADDRS; ++i)
    {
        static unsigned long localHost = 0x7F000001;        // 127.0.0.1
        unsigned long theAddr;
        
        theAddr = ip_addrs[i];
        
        if (theAddr == 0) break;
        if (theAddr == localHost) continue;
        
        NSLog(@"Name: %s MAC: %s IP: %s\n", if_names[i], hw_addrs[i], ip_names[i]);
        
        //decided what adapter you want details for
        if (strncmp(if_names[i], "en", 2) == 0)
        {
            NSLog(@"Adapter en has a IP of %s", ip_names[i]);
        }
    }
    
}

@end
