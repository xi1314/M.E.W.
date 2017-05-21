//
//  MEWBackupViewController.m
//  MewApp
//
//  Created by Zheng on 19/05/2017.
//  Copyright © 2017 Zheng. All rights reserved.
//

#import "MEWBackupViewController.h"
#import "MEWBackupCell.h"
#import <Preferences/PSSpecifier.h>

enum {
    kMEWBackupCellSection = 0,
};

@interface MEWBackupViewController () <
UITableViewDelegate,
UITableViewDataSource,
UIAlertViewDelegate
>

@property(nonatomic, strong) UITableView *tableView;
@property(nonatomic, strong) NSArray <NSDictionary *> *backupList;
@property(nonatomic, strong) NSIndexPath *selectedIndexPath;
@property(nonatomic, strong) NSString *actionType;

@end

@implementation MEWBackupViewController

#pragma mark - Default Style

- (UIStatusBarStyle)preferredStatusBarStyle {
    return UIStatusBarStyleDefault;
}

- (NSString *)title {
    return [self.specifier propertyForKey:PSTitleKey];
}

- (void)reloadData {
    NSError *error = nil;
    NSArray <NSString *> *subpaths = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:kMewEncBackupPath error:&error];
    NSMutableArray <NSDictionary *> *backupList = [NSMutableArray arrayWithCapacity:subpaths.count];
    for (NSString *path in subpaths) {
        NSString *absPath = [kMewEncBackupPath stringByAppendingPathComponent:path];
        NSDictionary *attrs = [[NSFileManager defaultManager] attributesOfItemAtPath:absPath error:&error];
        if (attrs) {
            NSString *configPath = [absPath stringByAppendingPathComponent:kMewEncConfigName];
            NSDictionary *configDict = [[NSDictionary alloc] initWithContentsOfFile:configPath];
            if (configDict && configDict[kMewEncVersion]) {
                [backupList addObject:@{
                                        @"path": absPath,
                                        @"version": configDict[kMewEncVersion],
                                        @"attributes": attrs
                                        }];
            }
        }
        if (error) {
            break;
        }
    }
    [backupList sortUsingComparator:^NSComparisonResult(NSDictionary *  _Nonnull obj1, NSDictionary *  _Nonnull obj2) {
        return [obj2[@"attributes"][NSFileCreationDate] compare:obj1[@"attributes"][NSFileCreationDate]];
    }];
    self.backupList = backupList;
    if (error) {
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"错误"
                                                            message:[error localizedDescription]
                                                           delegate:nil
                                                  cancelButtonTitle:nil
                                                  otherButtonTitles:@"好", nil];
        [alertView show];
    }
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.edgesForExtendedLayout = UIRectEdgeLeft | UIRectEdgeBottom | UIRectEdgeRight;
    
    [self reloadData];
    
    UITableView *tableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStylePlain];
    [tableView registerNib:[UINib nibWithNibName:@"MEWBackupCell" bundle:[NSBundle mainBundle]] forCellReuseIdentifier:kMEWBackupCellReuseIdentifier];
    tableView.delegate = self;
    tableView.dataSource = self;
    tableView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    START_IGNORE_PARTIAL
    if (XXT_SYSTEM_9) {
        tableView.cellLayoutMarginsFollowReadableWidth = NO;
    }
    END_IGNORE_PARTIAL
    tableView.scrollIndicatorInsets = tableView.contentInset =
    UIEdgeInsetsMake(0, 0, self.tabBarController.tabBar.frame.size.height, 0);
    tableView.contentOffset = CGPointMake(0, self.searchDisplayController.searchBar.bounds.size.height);
    [self.view addSubview:tableView];
    self.tableView = tableView;
    
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 44.f;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    return YES;
}

- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath {
    return UITableViewCellEditingStyleDelete;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (section == kMEWBackupCellSection) {
        return self.backupList.count;
    }
    return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    MEWBackupCell *cell = [tableView dequeueReusableCellWithIdentifier:kMEWBackupCellReuseIdentifier];
    if (cell == nil) {
        cell = [[MEWBackupCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:kMEWBackupCellReuseIdentifier];
    }
    if (indexPath.section == kMEWBackupCellSection) {
        cell.textLabel.text = [self.backupList[indexPath.row][@"attributes"][NSFileCreationDate] description];
    }
    [cell setTintColor:MAIN_COLOR];
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    NSDictionary *detailDict = self.backupList[indexPath.row];
    self.selectedIndexPath = indexPath;
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"提示"
                                                        message:[NSString stringWithFormat:@"MEW 备份版本：%@\n%@\n即将恢复，轻按「继续」以恢复备份。",
                                                                 detailDict[@"version"],
                                                                 [detailDict[@"attributes"][NSFileCreationDate] description]]
                                                       delegate:self
                                              cancelButtonTitle:@"取消"
                                              otherButtonTitles:@"继续", nil];
    self.actionType = @"recover_confirm";
    [alertView show];
}

- (void)tableView:(UITableView *)tableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath {
    NSDictionary *detailDict = self.backupList[indexPath.row];
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:[detailDict[@"attributes"][NSFileCreationDate] description]
                                                        message:detailDict[@"path"]
                                                       delegate:nil
                                              cancelButtonTitle:nil
                                              otherButtonTitles:@"好", nil];
    [alertView show];
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        NSDictionary *detailDict = self.backupList[indexPath.row];
        NSError *error = nil;
        [[MEWSharedUtility sharedInstance] removeBackup:detailDict[@"path"] withError:&error];
        if (error) {
            UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"错误"
                                                                message:[error localizedDescription]
                                                               delegate:nil
                                                      cancelButtonTitle:nil
                                                      otherButtonTitles:@"好", nil];
            [alertView show];
        } else {
            [self reloadData];
            [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
            [self.tableView reloadData];
        }
    }
}

- (void)performAction:(NSArray *)args {
    if (args.count >= 1) {
        if (args.count == 4 &&
            [args[0] isKindOfClass:[NSString class]] &&
            [args[0] isEqualToString:@"recover"]
            ) {
            NSError *error = nil;
            [[MEWSharedUtility sharedInstance] recoverFromBackupPath:args[1][@"path"] withError:&error];
            if (error) {
                [self performSelector:@selector(performAction:) withObject:@[@"recover_failed", args[1], args[2], args[3], error] afterDelay:.2f];
            } else {
                [self performSelector:@selector(performAction:) withObject:@[@"recover_done", args[1], args[2], args[3]] afterDelay:.2f];
            }
        }
        else if (args.count == 4 &&
                 [args[0] isKindOfClass:[NSString class]] &&
                 [args[0] isEqualToString:@"recover_done"]
                 ) {
            [args[2] dismissWithClickedButtonIndex:0 animated:YES];
            NSTimeInterval intval = [[NSDate date] timeIntervalSince1970] - [args[3] doubleValue];
            UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"提示"
                                                                message:[NSString stringWithFormat:@"MEW 备份版本：%@\n%@\n恢复完成，此次恢复用时 %d 秒。\n轻按「好」以重置并退出 M.E.W.",
                                                                         args[1][@"version"],
                                                                         [args[1][@"attributes"][NSFileCreationDate] description],
                                                                         (int)intval]
                                                               delegate:self
                                                      cancelButtonTitle:nil
                                                      otherButtonTitles:@"好", nil];
            self.actionType = @"recover_finished";
            [alertView show];
        }
        else if (args.count == 5 &&
                 [args[0] isKindOfClass:[NSString class]] &&
                 [args[0] isEqualToString:@"recover_failed"]
                 ) {
            [args[2] dismissWithClickedButtonIndex:0 animated:YES];
            NSTimeInterval intval = [[NSDate date] timeIntervalSince1970] - [args[3] doubleValue];
            UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"错误"
                                                                message:[NSString stringWithFormat:@"MEW 备份版本：%@\n%@\n恢复失败，此次恢复用时 %d 秒。\n%@",
                                                                         args[1][@"version"],
                                                                         [args[1][@"attributes"][NSFileCreationDate] description],
                                                                         (int)intval,
                                                                         [args[4] localizedDescription]
                                                                         ]
                                                               delegate:nil
                                                      cancelButtonTitle:nil
                                                      otherButtonTitles:@"好", nil];
            self.actionType = @"recover_failed";
            [alertView show];
        }
    }
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if ([self.actionType isEqualToString:@"recover_finished"]) {
        if (buttonIndex == 0) {
            _exit(0);
        }
    } else if ([self.actionType isEqualToString:@"recover_confirm"]) {
        if (buttonIndex == 1 && self.selectedIndexPath) {
            UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"恢复中……"
                                                                message:nil
                                                               delegate:nil
                                                      cancelButtonTitle:nil
                                                      otherButtonTitles:nil];
            [alertView show];
            NSDictionary *detailDict = self.backupList[self.selectedIndexPath.row];
            [self performSelector:@selector(performAction:) withObject:@[@"recover", detailDict, alertView, @([[NSDate date] timeIntervalSince1970])] afterDelay:1.f];
        }
    }
}

#pragma mark - Memory

- (void)dealloc {
#ifdef TEST_FLAG
    NSLog(@"[MEWBackupViewController dealloc]");
#endif
}

@end
