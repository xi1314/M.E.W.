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

@interface AppDelegate ()

@end

@implementation AppDelegate

- (void)loadDefaultConfiguration {
    
//    NSMutableString *conf = [NSMutableString string];
    
    NSDictionary *defaultConfig = [[NSDictionary alloc] initWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"MEWDefaultConfiguration" ofType:@"plist"]];
    [defaultConfig enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
#ifdef DEBUG
        id answer = MEWCopyAnswer(key);
        if (answer) {
            NSLog(@"%@: %@", key, answer);
            [[NSUserDefaults standardUserDefaults] setObject:answer forKey:key];
        } else {
            [[NSUserDefaults standardUserDefaults] setObject:obj forKey:key];
        }
//        [conf appendFormat:@"static NSString * const kMew%@ = @\"%@\";\n", key, key];
#else
        if (![[NSUserDefaults standardUserDefaults] objectForKey:key]) {
            id answer = MEWCopyAnswer(key);
            if (answer) {
                [[NSUserDefaults standardUserDefaults] setObject:answer forKey:key];
            } else {
                [[NSUserDefaults standardUserDefaults] setObject:obj forKey:key];
            }
        }
#endif
    }];
    
//    NSLog(@"%@", conf);
    
}

- (void)loadStartupCommands {
    if ([[NSUserDefaults standardUserDefaults] objectForKey:kMewSwitchAutoCleanPasteboard]) {
        system("/Applications/MewApp.app/MEWDo launchctl unload -w /System/Library/LaunchDaemons/com.apple.UIKit.pasteboardd.plist");
        system("/Applications/MewApp.app/MEWDo rm -rf /var/mobile/Library/Caches/com.apple.UIKit.pboard/*");
        system("/Applications/MewApp.app/MEWDo launchctl load -w /System/Library/LaunchDaemons/com.apple.UIKit.pasteboardd.plist");
    }
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    [self loadDefaultConfiguration];
    [self loadStartupCommands];
    
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    self.window.backgroundColor = [UIColor whiteColor];
    MEWRootViewController *listController = [[MEWRootViewController alloc] init];
    listController.filePath = [[NSBundle mainBundle] pathForResource:@"MEWRootEntry" ofType:@"plist"];
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
