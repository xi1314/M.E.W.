//
//  main.m
//  MEWTest
//
//  Created by Zheng on 05/05/2017.
//  Copyright © 2017 Zheng. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "AppDelegate.h"
#import <dlfcn.h>

int main(int argc, char * argv[]) {
    @autoreleasepool {
//        void *lib = dlopen([[NSBundle mainBundle] pathForResource:@"MEW" ofType:@"dylib"].UTF8String, RTLD_NOW);
//        if (lib == NULL) {
//            exit(-1);
//        }
        return UIApplicationMain(argc, argv, nil, NSStringFromClass([AppDelegate class]));
    }
}
