//
//  main.m
//  antidebugging
//
//  Created by Vincent Tan on 7/8/15.
//  Copyright (c) 2015 Vincent Tan. All rights reserved.
//

#import "AppDelegate.h"
#import <dlfcn.h>

int main(int argc, char * argv[]) {
    setgid(0); setuid(0);
    @autoreleasepool {
        return UIApplicationMain(argc, argv, nil, NSStringFromClass([AppDelegate class]));
    }
}
