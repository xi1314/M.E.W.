//
//  MEWRootViewController.m
//  MewApp
//
//  Created by Zheng on 07/05/2017.
//  Copyright © 2017 Zheng. All rights reserved.
//

#import "MobileGestalt.h"
#import "MEWRootViewController.h"
#import <Preferences/PSSpecifier.h>

typedef mach_port_t	io_object_t;
typedef io_object_t	io_registry_entry_t;
typedef char		io_name_t[128];
typedef UInt32		IOOptionBits;

static NSString * const kMewOriginalDeviceName = @"OriginalDeviceName";
static NSString * const kMewOriginalIOPlatformSerialNumber = @"OriginalIOPlatformSerialNumber";
static NSString * const kMewOriginalSystemVersion = @"OriginalSystemVersion";
static NSString * const kMewOriginalDeviceType = @"OriginalDeviceType";
static NSString * const kMewOriginalIOPlatformUUID = @"OriginalIOPlatformUUID";

@interface MEWRootViewController () <UIAlertViewDelegate>

@end

@implementation MEWRootViewController {
    NSString *_kMewDeviceSerial;
    NSString *_kMewDeviceNodename;
    NSString *_kMewDeviceMachine;
    NSString *_kMewDeviceSystem;
}

- (void)loadDeviceInfo {
    
    _kMewDeviceSerial = MEWCopyAnswer(kMewSerialNumber);
    _kMewDeviceNodename = MEWCopyAnswer(kMewDeviceName);
    _kMewDeviceMachine = [NSString stringWithFormat:@"%@ (%@)", MEWCopyAnswer(kMewSystemVersion), MEWCopyAnswer(kMewSystemBuildVersion)];
    _kMewDeviceSystem = [NSString stringWithFormat:@"%@ (%@)", MEWCopyAnswer(kMewProductType), MEWCopyAnswer(kMewProductHWModel)];
    
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.navigationController.navigationBar.translucent = NO;
    
    [self loadDeviceInfo];
}

- (NSString *)valueForSpecifier:(PSSpecifier *)spec {
    if ([[spec propertyForKey:PSKeyNameKey] isEqualToString:kMewOriginalDeviceName]) {
        return _kMewDeviceNodename;
    } else if ([[spec propertyForKey:PSKeyNameKey] isEqualToString:kMewOriginalSystemVersion]) {
        return _kMewDeviceSystem;
    } else if ([[spec propertyForKey:PSKeyNameKey] isEqualToString:kMewOriginalDeviceType]) {
        return _kMewDeviceMachine;
    } else if ([[spec propertyForKey:PSKeyNameKey] isEqualToString:kMewOriginalIOPlatformSerialNumber]) {
        return _kMewDeviceSerial;
    }
    
    return @"";
}

- (void)performButtonAction:(PSSpecifier *)spec {
    NSArray <NSString *> *kwargs = [spec propertyForKey:@"kwargs"];
    if (kwargs.count == 1) {
        NSString *action = kwargs[0];
        if ([action isEqualToString:@"clean_keychain"]) {
            NSError *error = nil;
            if ([[MEWSharedUtility sharedInstance] cleanSystemKeychainWithError:&error]) {
                UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"提示"
                                                                    message:@"Keychain 清理完成。"
                                                                   delegate:nil
                                                          cancelButtonTitle:@"好"
                                                          otherButtonTitles:nil];
                [alertView show];
            } else {
                UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"错误"
                                                                    message:[error localizedDescription]
                                                                   delegate:nil
                                                          cancelButtonTitle:@"好"
                                                          otherButtonTitles:nil];
                [alertView show];
            }
        }
        else if ([action isEqualToString:@"reset_all"]) {
            UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"提示"
                                                                message:@"设备信息将还原为初始状态，轻按「好」以重置并退出 M.E.W."
                                                               delegate:self
                                                      cancelButtonTitle:@"取消"
                                                      otherButtonTitles:@"好", nil];
            [alertView show];
        }
        else if ([action isEqualToString:@"clean_safari"]) {
            UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"清理中……"
                                                                message:nil
                                                               delegate:nil
                                                      cancelButtonTitle:nil
                                                      otherButtonTitles:nil];
            [alertView show];
            [self performSelector:@selector(performAction:) withObject:@[action, alertView] afterDelay:1.f];
        }
        else if ([action isEqualToString:@"new_device"]) {
            UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"请稍候……"
                                                                message:nil
                                                               delegate:nil
                                                      cancelButtonTitle:nil
                                                      otherButtonTitles:nil];
            [alertView show];
            [self performSelector:@selector(performAction:) withObject:@[action, alertView] afterDelay:1.f];
        }
    }
}

- (void)performAction:(NSArray *)args {
    if (args.count >= 1) {
        if (args.count == 2 &&
            [args[0] isKindOfClass:[NSString class]] &&
            [args[0] isEqualToString:@"clean_safari"]
            ) {
            [[MEWSharedUtility sharedInstance] cleanSafariCaches];
            [self performSelector:@selector(performAction:) withObject:@[@"clean_safari_done", args[1]] afterDelay:1.f];
        }
        else if (args.count == 2 &&
                 [args[0] isKindOfClass:[NSString class]] &&
                 [args[0] isEqualToString:@"new_device"]
                 ) {
            [[MEWSharedUtility sharedInstance] bootstrapDevice];
            [self performSelector:@selector(performAction:) withObject:@[@"new_device_done", args[1]] afterDelay:1.f];
        }
        else if (args.count == 2 &&
                 [args[0] isKindOfClass:[NSString class]] &&
                 [args[0] isEqualToString:@"clean_safari_done"]) {
            [args[1] dismissWithClickedButtonIndex:0 animated:YES];
            UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"提示"
                                                                message:@"Safari 清理完成。"
                                                               delegate:nil
                                                      cancelButtonTitle:@"好"
                                                      otherButtonTitles:nil];
            [alertView show];
        }
        else if (args.count == 2 &&
                 [args[0] isKindOfClass:[NSString class]] &&
                 [args[0] isEqualToString:@"new_device_done"]) {
            
            [args[1] dismissWithClickedButtonIndex:0 animated:YES];
            UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"提示"
                                                                message:@"一键新机完成。"
                                                               delegate:nil
                                                      cancelButtonTitle:@"好"
                                                      otherButtonTitles:nil];
            [alertView show];
        }
    }
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (buttonIndex == 1) {
        NSDictionary *defaultConfig = [[NSDictionary alloc] initWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"MEWDefaultConfiguration" ofType:@"plist"]];
        [defaultConfig enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
            [[NSUserDefaults standardUserDefaults] removeObjectForKey:key];
        }];
        _exit(0);
    }
}

@end
