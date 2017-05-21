//
//  AppDelegate.m
//  MewApp
//
//  Created by Zheng on 06/05/2017.
//  Copyright © 2017 Zheng. All rights reserved.
//

#import "AppDelegate.h"
#import "MEWOpenUDID.h"
#import "MEWRootViewController.h"
#import <unistd.h>

@interface AppDelegate ()

@end

@implementation AppDelegate

#pragma obfuscate on
- (void)loadDefaultConfiguration {
    NSDictionary *defaultConfig = [[NSDictionary alloc] initWithContentsOfFile:[[NSBundle mainBundle] pathForResource:kMewEncBundleID ofType:@"plist"]];
    [defaultConfig enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
        if (
            ![key isEqualToString:kMewEncVerifyKeys] &&
            ![key isEqualToString:kMewEncUniqueId] &&
            !R(key)
            ) {
            id answer = MEWCopyAnswer(key);
            if (answer) {
                S(key, answer);
            } else {
                S(key, obj);
            }
        }
    }];
    NSData *MGCAVerify = [[NSString stringWithFormat:@"%@/%@/%@", kMewEncSerialNumber, kMewEncMLBSerialNumber, kMewEncUniqueDeviceID] dataUsingEncoding:NSUTF8StringEncoding];
    unsigned char hashBuffer[20] = "";
    _T(MGCAVerify.bytes, (unsigned int)MGCAVerify.length, hashBuffer);
//    CC_SHA1(MGCAVerify.bytes, (CC_LONG)MGCAVerify.length, hashBuffer);
    NSMutableString *outputHash = [NSMutableString stringWithCapacity:40];
    for (int i = 0; i < 20; i++)
        [outputHash appendFormat:@"%02x", hashBuffer[i]];
    NSString *storedUniqueId = R(kMewEncUniqueId);
    if (!storedUniqueId) {
        S(kMewEncUniqueId, outputHash);
    } else {
        assert([outputHash isEqualToString:storedUniqueId]);
    }
    S(kMewEncVerifyKeys, defaultConfig[kMewEncVerifyKeys]);
}

- (void)loadStartupCommands {
    if (R(kMewEncSwitchAutoCleanPasteboard)) {
        [[MEWSharedUtility sharedInstance] cleanAllPasteboard];
    }
}
#pragma obfuscate off

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    
    [self loadDefaultConfiguration];
    [self loadStartupCommands];
    
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    self.window.backgroundColor = [UIColor whiteColor];
    MEWRootViewController *listController = [[MEWRootViewController alloc] init];
    listController.filePath = [[NSBundle mainBundle] pathForResource:@"MEWRootViewController" ofType:@"plist"];
    self.window.rootViewController = [[UINavigationController alloc] initWithRootViewController:listController];
    [self.window makeKeyAndVisible];
    
    return YES;
}


- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
}


- (void)applicationDidEnterBackground:(UIApplication *)application {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}


- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
}


- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}


- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}


@end
