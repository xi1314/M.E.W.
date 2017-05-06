//
//  XUIAction.h
//  XXTouchApp
//
//  Created by Zheng on 17/04/2017.
//  Copyright © 2017 Zheng. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Preferences/PSSpecifier.h>

@protocol XUIAction <NSObject>

- (void)copyValue:(PSSpecifier *)specifier;
- (void)dismissViewController;
- (void)popViewController;
- (void)presentViewController:(PSSpecifier *)specifier;
- (void)noAction;
- (void)exit;

@end
