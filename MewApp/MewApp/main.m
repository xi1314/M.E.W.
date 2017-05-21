//
//  main.m
//  antidebugging
//
//  Created by Vincent Tan on 7/8/15.
//  Copyright (c) 2015 Vincent Tan. All rights reserved.
//

#import "AppDelegate.h"

#ifndef TEST_FLAG
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

typedef int (*ptrace_ptr_t)(int _request, pid_t _pid, caddr_t _addr, int _data);

#if !defined(PT_DENY_ATTACH)
#define PT_DENY_ATTACH 31
#endif  // !defined(PT_DENY_ATTACH)

/*!
 @brief This is the basic ptrace functionality.
 @link http://www.coredump.gr/articles/ios-anti-debugging-protections-part-1/
 */
__attribute((obfuscate))
void _main_1()
{
    void* handle = dlopen(0, RTLD_GLOBAL | RTLD_NOW);
    ptrace_ptr_t ptrace_ptr = dlsym(handle, [D(@"two+RHOPCcQ=") UTF8String]);
    ptrace_ptr(PT_DENY_ATTACH, 0, 0, 0);
    dlclose(handle);
}

/*!
 @brief This function uses sysctl to check for attached debuggers.
 @link https://developer.apple.com/library/mac/qa/qa1361/_index.html
 @link http://www.coredump.gr/articles/ios-anti-debugging-protections-part-2/
 */
__attribute((obfuscate))
static bool _main_2(void)
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

#endif

__attribute((obfuscate))
int _main_3(int argc, char * argv[]) {
    
#ifndef TEST_FLAG
    // If enabled the program should exit with code 055 in GDB
    // Program exited with code 055.
    _main_1();
    
    // If enabled the program should exit with code 0377 in GDB
    // Program exited with code 0377.
    if (_main_2())
    {
        kill(getpid(), SIGKILL);
    }
    
    // Another way of calling ptrace.
    // Ref: https://www.theiphonewiki.com/wiki/Kernel_Syscalls
    syscall(26, 31, 0, 0);
    
    
    // Another way of figuring out if LLDB is attached.
    if (isatty(1)) {
        kill(getpid(), SIGKILL);
    }
    
    // Yet another way of figuring out if LLDB is attached.
    if (!ioctl(1, TIOCGWINSZ)) {
        kill(getpid(), SIGKILL);
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
    
    setgid(0); setuid(0);
    @autoreleasepool {
        return UIApplicationMain(argc, argv, nil, NSStringFromClass([AppDelegate class]));
    }
}

__attribute((obfuscate))
int main(int argc, char * argv[]) {
    _main_3(argc, argv);
}
