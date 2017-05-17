//
//  MEWPasteboard.m
//  MEWPasteboard
//
//  Created by Zheng on 10/05/2017.
//

#import <dlfcn.h>
#import <UIKit/UIKit.h>
#import "substrate.h"
#import "MEWConfiguration.h"
#import "MEWAuthorizationUtility.h"

#import <UIKit/UIKit.h>

// For debugger_ptrace. Ref: https://www.theiphonewiki.com/wiki/Bugging_Debuggers
#import <dlfcn.h>
#import <sys/types.h>

// For debugger_sysctl
#include <stdio.h>
#include <sys/types.h>
#include <unistd.h>
#include <sys/sysctl.h>
#include <stdlib.h>

// For ioctl
#include <termios.h>
#include <sys/ioctl.h>

// For task_get_exception_ports
#include <mach/task.h>
#include <mach/mach_init.h>

_Pragma("clang diagnostic push")
_Pragma("clang diagnostic ignored \"-Wmissing-prototypes\"")

typedef int (*ptrace_ptr_t)(int _request, pid_t _pid, caddr_t _addr, int _data);

#if !defined(PT_DENY_ATTACH)
#define PT_DENY_ATTACH 31
#endif  // !defined(PT_DENY_ATTACH)

/*!
 @brief This is the basic ptrace functionality.
 @link http://www.coredump.gr/articles/ios-anti-debugging-protections-part-1/
 */
void debugger_ptrace()
{
    void* handle = dlopen(0, RTLD_GLOBAL | RTLD_NOW);
    ptrace_ptr_t ptrace_ptr = dlsym(handle, "ptrace");
    ptrace_ptr(PT_DENY_ATTACH, 0, 0, 0);
    dlclose(handle);
}

/*!
 @brief This function uses sysctl to check for attached debuggers.
 @link https://developer.apple.com/library/mac/qa/qa1361/_index.html
 @link http://www.coredump.gr/articles/ios-anti-debugging-protections-part-2/
 */
static bool debugger_sysctl(void)
// Returns true if the current process is being debugged (either
// running under the debugger or has a debugger attached post facto).
{
    int mib[4];
    struct kinfo_proc info;
    size_t info_size = sizeof(info);
    
    // Initialize the flags so that, if sysctl fails for some bizarre
    // reason, we get a predictable result.
    
    info.kp_proc.p_flag = 0;
    
    // Initialize mib, which tells sysctl the info we want, in this case
    // we're looking for information about a specific process ID.
    
    mib[0] = CTL_KERN;
    mib[1] = KERN_PROC;
    mib[2] = KERN_PROC_PID;
    mib[3] = getpid();
    
    // Call sysctl.
    
    if (sysctl(mib, 4, &info, &info_size, NULL, 0) == -1)
    {
        kill(getpid(), SIGKILL);
    }
    
    // We're being debugged if the P_TRACED flag is set.
    
    return ((info.kp_proc.p_flag & P_TRACED) != 0);
}

#pragma mark - Config

static NSDictionary *getMewConfig() {
    static NSDictionary *mewConfig = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSString *mewConfigPath = kMewConfigPath;
        NSDictionary *mewDict = [[NSDictionary alloc] initWithContentsOfFile:mewConfigPath];
        if (!mewDict)
            mewDict = [[NSDictionary alloc] initWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"com.darwindev.MewApp" ofType:@"plist"]];
#ifdef TEST_FLAG
        NSLog(@"%@", mewDict);
#endif
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
    }
    return application;
}

static IMP _orig__UIApplication_init;
UIApplication *_UIApplication_init(id _self, SEL _cmd1) {
    UIApplication *application = _orig__UIApplication_init(_self, _cmd1);
    
#ifndef TEST_FLAG
    int pid = getpid();
    
    // If enabled the program should exit with code 055 in GDB
    // Program exited with code 055.
    debugger_ptrace();
    
    // If enabled the program should exit with code 0377 in GDB
    // Program exited with code 0377.
    if (debugger_sysctl())
    {
        kill(pid, SIGKILL);
    }
    
    // Another way of calling ptrace.
    // Ref: https://www.theiphonewiki.com/wiki/Kernel_Syscalls
    syscall(26, 31, 0, 0);
    
    
    // Another way of figuring out if LLDB is attached.
    if (isatty(1)) {
        kill(pid, SIGKILL);
    }
    
    // Yet another way of figuring out if LLDB is attached.
    if (!ioctl(1, TIOCGWINSZ)) {
        kill(pid, SIGKILL);
    }
    
    // Everything above relies on libraries. It is easy enough to hook these libraries and return the required
    // result to bypass those checks. So here it is implemented in ARM assembly. Not very fun to bypass these.
#ifdef __arm__
    asm volatile (
                  "mov r0, #31\n"
                  "mov r1, #0\n"
                  "mov r2, #0\n"
                  "mov r12, #26\n"
                  "svc #80\n"
                  );
#endif
#ifdef __arm64__
    asm volatile (
                  "mov x0, #26\n"
                  "mov x1, #31\n"
                  "mov x2, #0\n"
                  "mov x3, #0\n"
                  "mov x16, #0\n"
                  "svc #128\n"
                  );
#endif
    
#endif
    
    MEWAuthorizationUtility *test = [[MEWAuthorizationUtility alloc] init];
    [test g0:application];
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
    
    if ([bundleIdentifier isEqualToString:kMewBundleID]) {
        MSHookMessageEx(objc_getClass("UIApplication"), @selector(init), (IMP)_UIApplication_init, (IMP *)&_orig__UIApplication_init);
    }
    
}

_Pragma("clang diagnostic pop")
