//
//  MEWSharedUtility.m
//  MewApp
//
//  Created by Zheng on 10/05/2017.
//  Copyright © 2017 Zheng. All rights reserved.
//

#import "MEWSharedUtility.h"
#import "MobileGestalt.h"
#import <sqlite3.h>
#import <dlfcn.h>


static CFStringRef (*$MGCopyAnswer)(CFStringRef);

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
    } else if ([key isEqualToString:kMewUniqueIdentifier]) {
        return [self MGCopyAnswer:kMGUniqueDeviceID];
    } else if ([key isEqualToString:kMewSystemVersion]) {
        return [self MGCopyAnswer:kMGProductVersion];
    } else if ([key isEqualToString:kMewSystemBuildVersion]) {
        return [self MGCopyAnswer:kMGBuildVersion];
    } else if ([key isEqualToString:kMewProductType]) {
        return [self MGCopyAnswer:kMGProductType];
    } else if ([key isEqualToString:kMewProductHWModel]) {
        return [self MGCopyAnswer:kMGHWModel];
    }
    
    return nil;
}

- (void)MEWSetAnswer:(NSString *)key {
    
}

- (id)MEWCopyAnswer:(NSString *)key fromDictionary:(NSString *)dictionaryKey {
    if ([dictionaryKey isEqualToString:kMewReplaceMGCopyAnswer]) {
        return [self MGCopyAnswer:(__bridge CFStringRef)(key)];
    } else if ([dictionaryKey isEqualToString:kMewReplaceIOKitProperties]) {
        // Get value from IOKit
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
