//
//  MEWConfigurationViewController.m
//  MewApp
//
//  Created by Zheng on 10/05/2017.
//  Copyright © 2017 Zheng. All rights reserved.
//

#import "MEWConfigurationViewController.h"
#import <Preferences/PSSpecifier.h>

@interface MEWConfigurationViewController ()

@end

@implementation MEWConfigurationViewController

- (NSString *)valueForSpecifier:(PSSpecifier *)spec {
    return R([spec propertyForKey:PSKeyNameKey]);
}

- (void)setPreferenceValue:(id)value specifier:(PSSpecifier *)spec {
    S([spec propertyForKey:PSKeyNameKey], value);
}

@end
