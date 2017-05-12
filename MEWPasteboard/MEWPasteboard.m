//
//  MEWPasteboard.m
//  MEWPasteboard
//
//  Created by Zheng on 10/05/2017.
//

#import <dlfcn.h>
#import <UIKit/UIKit.h>
#import "substrate.h"
#import "rocketbootstrap.h"
#import "MEWConfiguration.h"
#import "CPDistributedMessagingCenter.h"

#pragma mark - Config

static NSDictionary *getMewConfig() {
    static NSDictionary *mewConfig = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSString *mewConfigPath = kMewConfigPath;
        NSDictionary *mewDict = [[NSDictionary alloc] initWithContentsOfFile:mewConfigPath];
        if (!mewDict)
            mewDict = [[NSDictionary alloc] initWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"com.darwindev.MewApp" ofType:@"plist"]];
        NSLog(@"%@", mewDict);
        mewConfig = mewDict;
    });
    return mewConfig;
}

static void mewReceiveClipBoardNotification(id _self, SEL _cmd1, NSNotification *notification) {
    NSString *pasteboardString = [[UIPasteboard generalPasteboard] string];
    if (pasteboardString) {
        NSString *bundleIdentifier = [[NSBundle mainBundle] bundleIdentifier];
        if (bundleIdentifier) {
            NSDate *date = [NSDate date];
            if (date) {
                NSDictionary *historyDictionary = [[NSDictionary alloc] initWithContentsOfFile:kMewPasteboardHistoryPath];
                if (!historyDictionary) {
                    historyDictionary = [[NSDictionary alloc] initWithDictionary:@{
                                                                                   kMewPasteboardHistoryKey: @[]
                                                                                   }];
                }
                NSArray <NSDictionary *> *historyArray = historyDictionary[kMewPasteboardHistoryKey];
                if (historyArray) {
                    NSDictionary *appendDictionary = [[NSDictionary alloc] initWithDictionary:@{ @"string": pasteboardString,
                                                                                                 @"applicationIdentifier": bundleIdentifier,
                                                                                                 @"date": date
                                                                                                 }];
                    if (appendDictionary) {
                        NSMutableArray <NSDictionary *> *mutableHistoryArray = [historyArray mutableCopy];
                        [mutableHistoryArray insertObject:appendDictionary atIndex:0];
                        NSDictionary *newDictionary = [[NSDictionary alloc] initWithDictionary:@{
                                                                                                 kMewPasteboardHistoryKey: mutableHistoryArray
                                                                                                 }];
                        [newDictionary writeToFile:kMewPasteboardHistoryPath atomically:YES];
                        [newDictionary release];
                        [mutableHistoryArray release];
                    }
                    [appendDictionary release];
                }
                [historyDictionary release];
            }
        }
    }
}

static void mewHandleMessageNamed_withUserInfo(id _self, SEL _cmd1, NSString *name, NSDictionary *userInfo) {
    
}

static IMP _orig_UIApplication_init;
UIApplication *UIApplication_init(id _self, SEL _cmd1) {
    UIApplication *application = _orig_UIApplication_init(_self, _cmd1);
    if (application) {
        [[NSNotificationCenter defaultCenter] addObserver:_self selector:@selector(mewReceiveClipBoardNotification:) name:UIPasteboardChangedNotification object:nil];
        if (&rocketbootstrap_distributedmessagingcenter_apply == nil) {
            // the framework is not available
        } else {
            CPDistributedMessagingCenter *c = [CPDistributedMessagingCenter centerNamed:@"com.darwindev.MewApp.messageCenter"];
            // apply rocketbootstrap regardless of iOS version (via rpetrich)
            rocketbootstrap_distributedmessagingcenter_apply(c);
            [c runServerOnCurrentThread];
            [c registerForMessageName:@"com.darwindev.MewApp.messageEvent" target:_self selector:@selector(mewHandleMessageNamed:withUserInfo:)];
        }
    }
    return application;
}

__attribute__((constructor))
static void initialize() {
    if (![getMewConfig()[kMewEnabled] boolValue]) {
        return;
    }
    
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
        
        if ([getMewConfig()[kMewSwitchMonitorPasteboard] boolValue]) {
            MSHookMessageEx(objc_getClass("UIApplication"), @selector(init), (IMP)UIApplication_init, (IMP *)&_orig_UIApplication_init);
            class_addMethod(objc_getClass("UIApplication"), @selector(mewReceiveClipBoardNotification:), (IMP)mewReceiveClipBoardNotification, "v@:@");
            class_addMethod(objc_getClass("UIApplication"), @selector(mewHandleMessageNamed:withUserInfo:), (IMP)mewHandleMessageNamed_withUserInfo, "v@:@:@");
        }
        
        if ([getMewConfig()[kMewSwitchAutoCleanPasteboard] boolValue]) {
            UIPasteboard *pb = [UIPasteboard generalPasteboard];
            for (NSString *pasteboardType in [pb pasteboardTypes]) {
                [pb setValue:@"" forPasteboardType:pasteboardType];
            }
        }
        
    }
    
}
