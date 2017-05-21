//
//  MEWRootViewController.m
//  MewApp
//
//  Created by Zheng on 07/05/2017.
//  Copyright © 2017 Zheng. All rights reserved.
//

#import "MEWRootViewController.h"
#import <Preferences/PSSpecifier.h>

@interface MEWRootViewController () <UIAlertViewDelegate>
@property(nonatomic, strong) NSString *actionType;

@end

@implementation MEWRootViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.navigationController.navigationBar.translucent = NO;
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
            self.actionType = @"reset_all_confirm";
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
            [self performSelector:@selector(performAction:) withObject:@[action, alertView, @([[NSDate date] timeIntervalSince1970])] afterDelay:1.f];
        }
        else if ([action isEqualToString:@"clean_uicache"]) {
            UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"清理中……"
                                                                message:nil
                                                               delegate:nil
                                                      cancelButtonTitle:nil
                                                      otherButtonTitles:nil];
            [alertView show];
            [self performSelector:@selector(performAction:) withObject:@[action, alertView] afterDelay:1.f];
        }
        else if ([action isEqualToString:@"backup_now"]) {
            UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"备份中……"
                                                                message:nil
                                                               delegate:nil
                                                      cancelButtonTitle:nil
                                                      otherButtonTitles:nil];
            [alertView show];
            [self performSelector:@selector(performAction:) withObject:@[action, alertView, @([[NSDate date] timeIntervalSince1970])] afterDelay:1.f];
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
            [self performSelector:@selector(performAction:) withObject:@[@"clean_safari_done", args[1]] afterDelay:.2f];
        }
        else if (args.count == 2 &&
                 [args[0] isKindOfClass:[NSString class]] &&
                 [args[0] isEqualToString:@"clean_uicache"]
                 ) {
            [[MEWSharedUtility sharedInstance] cleanUICache];
            [self performSelector:@selector(performAction:) withObject:@[@"clean_uicache_done", args[1]] afterDelay:.2f];
        }
        else if (args.count == 3 &&
                 [args[0] isKindOfClass:[NSString class]] &&
                 [args[0] isEqualToString:@"new_device"]
                 ) {
            [[MEWSharedUtility sharedInstance] bootstrapDevice];
            [self performSelector:@selector(performAction:) withObject:@[@"new_device_done", args[1], args[2]] afterDelay:.2f];
        }
        else if (args.count == 3 &&
                 [args[0] isKindOfClass:[NSString class]] &&
                 [args[0] isEqualToString:@"backup_now"]
                 ) {
            [[MEWSharedUtility sharedInstance] makeBackup];
            [self performSelector:@selector(performAction:) withObject:@[@"backup_now_done", args[1], args[2]] afterDelay:.2f];
        }
        else if (args.count == 2 &&
                 [args[0] isKindOfClass:[NSString class]] &&
                 [args[0] isEqualToString:@"clean_safari_done"]) {
            [args[1] dismissWithClickedButtonIndex:0 animated:YES];
            UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"提示"
                                                                message:@"Safari 清理完成。"
                                                               delegate:nil
                                                      cancelButtonTitle:nil
                                                      otherButtonTitles:@"好", nil];
            [alertView show];
        }
        else if (args.count == 2 &&
                 [args[0] isKindOfClass:[NSString class]] &&
                 [args[0] isEqualToString:@"clean_uicache_done"]) {
            [args[1] dismissWithClickedButtonIndex:0 animated:YES];
            UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"提示"
                                                                message:@"主屏幕图标缓存重建完成。"
                                                               delegate:nil
                                                      cancelButtonTitle:nil
                                                      otherButtonTitles:@"好", nil];
            [alertView show];
        }
        else if (args.count == 3 &&
                 [args[0] isKindOfClass:[NSString class]] &&
                 [args[0] isEqualToString:@"new_device_done"]) {
            [args[1] dismissWithClickedButtonIndex:0 animated:YES];
            NSTimeInterval intval = [[NSDate date] timeIntervalSince1970] - [args[2] doubleValue];
            UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"提示"
                                                                message:[NSString stringWithFormat:@"一键新机完成，用时 %d 秒。\n轻按「好」以重置并退出 M.E.W.", (int)intval]
                                                               delegate:self
                                                      cancelButtonTitle:nil
                                                      otherButtonTitles:@"好", nil];
            self.actionType = @"new_device_finished";
            [alertView show];
        }
        else if (args.count == 3 &&
                 [args[0] isKindOfClass:[NSString class]] &&
                 [args[0] isEqualToString:@"backup_now_done"]) {
            [args[1] dismissWithClickedButtonIndex:0 animated:YES];
            NSTimeInterval intval = [[NSDate date] timeIntervalSince1970] - [args[2] doubleValue];
            UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"提示"
                                                                message:[NSString stringWithFormat:@"备份完成，此次备份用时 %d 秒。", (int)intval]
                                                               delegate:nil
                                                      cancelButtonTitle:nil
                                                      otherButtonTitles:@"好", nil];
            [alertView show];
        }
    }
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if ([self.actionType isEqualToString:@"reset_all_confirm"]) {
        if (buttonIndex == 1) {
            M(); _exit(0);
        }
    } else if ([self.actionType isEqualToString:@"new_device_finished"]) {
        if (buttonIndex == 0) {
            _exit(0);
        }
    }
}

- (NSString *)valueForSpecifier:(PSSpecifier *)spec {
    return R([spec propertyForKey:PSKeyNameKey]);
}

- (void)setPreferenceValue:(id)value specifier:(PSSpecifier *)spec {
    S([spec propertyForKey:PSKeyNameKey], value);
}

@end
