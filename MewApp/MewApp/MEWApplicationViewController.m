//
//  MEWApplicationViewController.m
//  MewApp
//
//  Created by Zheng on 08/05/2017.
//  Copyright © 2017 Zheng. All rights reserved.
//

#import <objc/runtime.h>
#import <Preferences/PSSpecifier.h>
#import "LSApplicationProxy.h"
#import "MEWApplicationViewController.h"
#import "MEWApplicationCell.h"
#import "MEWInsetsLabel.h"

enum {
    kMEWApplicationPickerCellSectionSelected = 0,
    kMEWApplicationPickerCellSectionUnselected
};

enum {
    kMEWApplicationSearchTypeName = 0,
    kMEWApplicationSearchTypeBundleID
};

@interface MEWApplicationViewController ()
<
UITableViewDelegate,
UITableViewDataSource,
UISearchDisplayDelegate
>

@property(nonatomic, strong) UITableView *tableView;
@property(nonatomic, strong) NSMutableArray <LSApplicationProxy *> *selectedApplications;
@property(nonatomic, strong) NSMutableArray <LSApplicationProxy *> *unselectedApplications;
@property(nonatomic, strong) NSMutableArray <LSApplicationProxy *> *displaySelectedApplications;
@property(nonatomic, strong) NSMutableArray <LSApplicationProxy *> *displayUnselectedApplications;

@end

@implementation MEWApplicationViewController {
    UISearchDisplayController *_searchDisplayController;
}

- (UIStatusBarStyle)preferredStatusBarStyle {
    return UIStatusBarStyleDefault;
}

- (NSString *)title {
    return [self.specifier propertyForKey:PSTitleKey];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.edgesForExtendedLayout = UIRectEdgeLeft | UIRectEdgeBottom | UIRectEdgeRight;
    
    Class LSApplicationWorkspace_class = objc_getClass("LSApplicationWorkspace");
    SEL selector = NSSelectorFromString(@"defaultWorkspace");
    NSObject *workspace = [LSApplicationWorkspace_class performSelector:selector];
    SEL selectorAll = NSSelectorFromString(@"allInstalledApplications");
    NSArray <LSApplicationProxy *> *allApplications = [workspace performSelector:selectorAll];
    
//    NSArray <LSApplicationProxy *> *sortedApplications = [allApplications sortedArrayUsingComparator:^NSComparisonResult(LSApplicationProxy *  _Nonnull obj1, LSApplicationProxy *  _Nonnull obj2) {
//        return [obj1.localizedName compare:obj2.localizedName];
//    }];
    
#ifndef DEBUG
    self.unselectedApplications = [allApplications mutableCopy];
#else
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"applicationType = 'User'"];
    self.unselectedApplications = [[allApplications filteredArrayUsingPredicate:predicate] mutableCopy];
#endif
    self.selectedApplications = [NSMutableArray arrayWithCapacity:allApplications.count];
    
    NSArray <NSString *> *selectedValues = [[self readPreferenceValue:self.specifier] mutableCopy];
    for (NSString *appIdentifier in selectedValues) {
        for (LSApplicationProxy *appProxy in allApplications) {
            if ([appProxy.applicationIdentifier isEqualToString:appIdentifier]) {
                [self.unselectedApplications removeObject:appProxy];
                [self.selectedApplications addObject:appProxy];
            }
        }
    }
    
    UISearchBar *searchBar = [[UISearchBar alloc] initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width, 44.f)];
    searchBar.placeholder = @"搜索应用程序";
    searchBar.scopeButtonTitles = @[
                                    @"名称",
                                    @"标识符"
                                    ];
    searchBar.autocapitalizationType = UITextAutocapitalizationTypeNone;
    searchBar.autocorrectionType = UITextAutocorrectionTypeNo;
    searchBar.spellCheckingType = UITextSpellCheckingTypeNo;
    searchBar.backgroundColor = [UIColor whiteColor];
    searchBar.barTintColor = [UIColor whiteColor];
    searchBar.tintColor = MAIN_COLOR;
    
    UISearchDisplayController *searchDisplayController = [[UISearchDisplayController alloc] initWithSearchBar:searchBar contentsController:self];
    searchDisplayController.searchResultsDelegate = self;
    searchDisplayController.searchResultsDataSource = self;
    searchDisplayController.delegate = self;
    _searchDisplayController = searchDisplayController;
    
    UITableView *tableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStylePlain];
    [tableView registerNib:[UINib nibWithNibName:@"MEWApplicationCell" bundle:[NSBundle mainBundle]] forCellReuseIdentifier:kMEWApplicationCellReuseIdentifier];
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
    
    tableView.tableHeaderView = searchBar;
    [self.view addSubview:tableView];
    self.tableView = tableView;
    
    [tableView setEditing:YES animated:NO];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 66.f;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return 24.0;
}

- (void)tableView:(UITableView *)tableView reloadHeaderView:(UITableViewHeaderFooterView *)view forSection:(NSInteger)section {
    
    UILabel *label = view.textLabel;
    if (label) {
        NSMutableArray <LSApplicationProxy *> *selectedApplications = nil;
        NSMutableArray <LSApplicationProxy *> *unselectedApplications = nil;
        if (tableView == self.tableView) {
            selectedApplications = self.selectedApplications;
            unselectedApplications = self.unselectedApplications;
        } else {
            selectedApplications = self.displaySelectedApplications;
            unselectedApplications = self.displayUnselectedApplications;
        }
        
        if (section == kMEWApplicationPickerCellSectionSelected) {
            label.text = [NSString stringWithFormat:@"已选择的应用程序 (%lu)", (unsigned long)selectedApplications.count];
        } else if (section == kMEWApplicationPickerCellSectionUnselected) {
            label.text = [NSString stringWithFormat:@"未选择的应用程序 (%lu)", (unsigned long)unselectedApplications.count];
        }
        
        CGSize newSize = [label sizeThatFits:CGSizeMake(0, 24)];
        label.bounds = CGRectMake(0, 0, newSize.width, newSize.height);
    }
    
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    static NSString *kMEWApplicationHeaderViewReuseIdentifier = @"kMEWApplicationHeaderViewReuseIdentifier";
    
    
    UITableViewHeaderFooterView *applicationHeaderView = [tableView dequeueReusableHeaderFooterViewWithIdentifier:kMEWApplicationHeaderViewReuseIdentifier];
    if (!applicationHeaderView) {
        applicationHeaderView = [[UITableViewHeaderFooterView alloc] initWithReuseIdentifier:kMEWApplicationHeaderViewReuseIdentifier];
    }
    
    [self tableView:tableView reloadHeaderView:applicationHeaderView forSection:section];
    
    return applicationHeaderView;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (tableView == self.tableView) {
        if (section == kMEWApplicationPickerCellSectionSelected) {
            return self.selectedApplications.count;
        } else if (section == kMEWApplicationPickerCellSectionUnselected) {
            return self.unselectedApplications.count;
        }
    } else {
        if (section == kMEWApplicationPickerCellSectionSelected) {
            return self.displaySelectedApplications.count;
        } else if (section == kMEWApplicationPickerCellSectionUnselected) {
            return self.displayUnselectedApplications.count;
        }
    }
    return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    MEWApplicationCell *cell = [tableView dequeueReusableCellWithIdentifier:kMEWApplicationCellReuseIdentifier];
    if (cell == nil) {
        cell = [[MEWApplicationCell alloc] initWithStyle:UITableViewCellStyleDefault
                                         reuseIdentifier:kMEWApplicationCellReuseIdentifier];
    }
    LSApplicationProxy *appProxy;
    if (tableView == self.tableView) {
        if (indexPath.section == kMEWApplicationPickerCellSectionSelected) {
            appProxy = self.selectedApplications[(NSUInteger) indexPath.row];
        } else if (indexPath.section == kMEWApplicationPickerCellSectionUnselected) {
            appProxy = self.unselectedApplications[(NSUInteger) indexPath.row];
        }
    } else {
        if (indexPath.section == kMEWApplicationPickerCellSectionSelected) {
            appProxy = self.displaySelectedApplications[(NSUInteger) indexPath.row];
        } else if (indexPath.section == kMEWApplicationPickerCellSectionUnselected) {
            appProxy = self.displayUnselectedApplications[(NSUInteger) indexPath.row];
        }
    }
    [cell setApplicationName:[appProxy localizedName]];
    [cell setApplicationBundleID:[appProxy applicationIdentifier]];
    if (XXT_SYSTEM_9) {
        [cell setApplicationIconData:[appProxy performSelector:@selector(iconDataForVariant:) withObject:@(2)]];
    } else {
        [cell setApplicationIconData:[appProxy iconDataForVariant:0]];
    }
    [cell setTintColor:MAIN_COLOR];
    [cell setShowsReorderControl:YES];
    return cell;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    return YES;
}

- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
    if (tableView == self.tableView) {
        return NO; // There is no need to change its order.
    }
    return NO;
}

- (NSIndexPath *)tableView:(UITableView *)tableView targetIndexPathForMoveFromRowAtIndexPath:(NSIndexPath *)sourceIndexPath toProposedIndexPath:(NSIndexPath *)proposedDestinationIndexPath {
    return proposedDestinationIndexPath;
}

- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath {
    if (tableView == self.tableView) {
        if (fromIndexPath.section == toIndexPath.section == kMEWApplicationPickerCellSectionSelected) {
            [self.selectedApplications exchangeObjectAtIndex:fromIndexPath.row withObjectAtIndex:toIndexPath.row];
        } else if (fromIndexPath.section == toIndexPath.section == kMEWApplicationPickerCellSectionUnselected) {
            [self.unselectedApplications exchangeObjectAtIndex:fromIndexPath.row withObjectAtIndex:toIndexPath.row];
        } else if (fromIndexPath.section == kMEWApplicationPickerCellSectionSelected && toIndexPath.section == kMEWApplicationPickerCellSectionUnselected) {
            LSApplicationProxy *appProxy = self.selectedApplications[fromIndexPath.row];
            [self.selectedApplications removeObjectAtIndex:fromIndexPath.row];
            [self.unselectedApplications insertObject:appProxy atIndex:toIndexPath.row];
        } else if (fromIndexPath.section == kMEWApplicationPickerCellSectionUnselected && toIndexPath.section == kMEWApplicationPickerCellSectionSelected) {
            LSApplicationProxy *appProxy = self.unselectedApplications[fromIndexPath.row];
            [self.unselectedApplications removeObjectAtIndex:fromIndexPath.row];
            [self.selectedApplications insertObject:appProxy atIndex:toIndexPath.row];
        }
        [tableView moveRowAtIndexPath:fromIndexPath toIndexPath:toIndexPath];
    }
    // TODO
}

- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == kMEWApplicationPickerCellSectionSelected) {
        return UITableViewCellEditingStyleDelete;
    } else if (indexPath.section == kMEWApplicationPickerCellSectionUnselected) {
        return UITableViewCellEditingStyleInsert;
    }
    return UITableViewCellEditingStyleNone;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    
    LSApplicationProxy *appProxy;
    
    NSMutableArray <LSApplicationProxy *> *selectedApplications = nil;
    NSMutableArray <LSApplicationProxy *> *unselectedApplications = nil;
    if (tableView == self.tableView) {
        selectedApplications = self.selectedApplications;
        unselectedApplications = self.unselectedApplications;
    } else {
        selectedApplications = self.displaySelectedApplications;
        unselectedApplications = self.displayUnselectedApplications;
    }
    
    if (indexPath.section == kMEWApplicationPickerCellSectionSelected) {
        appProxy = selectedApplications[(NSUInteger) indexPath.row];
    } else if (indexPath.section == kMEWApplicationPickerCellSectionUnselected) {
        appProxy = unselectedApplications[(NSUInteger) indexPath.row];
    }
    
    NSArray <NSString *> *blacklistIdentifiers = [[NSUserDefaults standardUserDefaults] objectForKey:@"ApplicationIdentifierBlackList"];
    
    for (NSString *blacklistIdentifier in blacklistIdentifiers) {
        if ([blacklistIdentifier isEqualToString:appProxy.applicationIdentifier]) {
            UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"错误"
                                                                message:[NSString stringWithFormat:@"无法选择用户应用程序 %@", appProxy.applicationIdentifier]
                                                               delegate:nil
                                                      cancelButtonTitle:@"取消"
                                                      otherButtonTitles:nil];
            [alertView show];
            return;
        }
    }
    
    NSIndexPath *toIndexPath = nil;
    
    BOOL alreadyExists = [selectedApplications containsObject:appProxy];
    
    if (alreadyExists && editingStyle == UITableViewCellEditingStyleDelete) {
        toIndexPath = [NSIndexPath indexPathForRow:0 inSection:kMEWApplicationPickerCellSectionUnselected];
        [selectedApplications removeObject:appProxy];
        [unselectedApplications insertObject:appProxy atIndex:0];
        if (tableView != self.tableView) {
            [self.selectedApplications removeObject:appProxy];
            [self.unselectedApplications insertObject:appProxy atIndex:0];
        }
    } else if (!alreadyExists && editingStyle == UITableViewCellEditingStyleInsert) {
        toIndexPath = [NSIndexPath indexPathForRow:selectedApplications.count inSection:kMEWApplicationPickerCellSectionSelected];
        [unselectedApplications removeObject:appProxy];
        [selectedApplications addObject:appProxy];
        if (tableView != self.tableView) {
            [self.unselectedApplications removeObject:appProxy];
            [self.selectedApplications addObject:appProxy];
        }
    }
    
    if (toIndexPath) {
        [tableView moveRowAtIndexPath:indexPath toIndexPath:toIndexPath];
        [tableView reloadRowsAtIndexPaths:@[toIndexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
    }
    
    NSMutableArray <NSString *> *identifiers = [NSMutableArray arrayWithCapacity:self.selectedApplications.count];
    for (LSApplicationProxy *appProxy in self.selectedApplications) {
        [identifiers addObject:appProxy.applicationIdentifier];
    }
    [self setPreferenceValue:[identifiers copy] specifier:self.specifier];
    
    [self tableView:tableView reloadHeaderView:[tableView headerViewForSection:indexPath.section] forSection:indexPath.section];
    [self tableView:tableView reloadHeaderView:[tableView headerViewForSection:toIndexPath.section] forSection:toIndexPath.section];
    
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

#pragma mark - UISearchDisplayDelegate

- (void)searchDisplayController:(UISearchDisplayController *)controller willShowSearchResultsTableView:(UITableView *)tableView {
    [tableView setEditing:YES animated:NO];
    [tableView registerNib:[UINib nibWithNibName:@"MEWApplicationCell" bundle:[NSBundle mainBundle]] forCellReuseIdentifier:kMEWApplicationCellReuseIdentifier];
}

- (void)searchDisplayController:(UISearchDisplayController *)controller willHideSearchResultsTableView:(UITableView *)tableView {
    [self.tableView reloadData];
}

- (void)searchDisplayControllerWillBeginSearch:(UISearchDisplayController *)controller {
    
}

- (BOOL)searchDisplayController:(UISearchDisplayController *)controller shouldReloadTableForSearchString:(NSString *)searchString {
    [self tableViewReloadSearch:controller.searchResultsTableView];
    return YES;
}

- (BOOL)searchDisplayController:(UISearchDisplayController *)controller shouldReloadTableForSearchScope:(NSInteger)searchOption {
    [self tableViewReloadSearch:controller.searchResultsTableView];
    return YES;
}

- (void)tableViewReloadSearch:(UITableView *)tableView {
    NSPredicate *predicate = nil;
    if (self.searchDisplayController.searchBar.selectedScopeButtonIndex == kMEWApplicationSearchTypeName) {
        predicate = [NSPredicate predicateWithFormat:@"localizedName CONTAINS[cd] %@", self.searchDisplayController.searchBar.text];
    } else if (self.searchDisplayController.searchBar.selectedScopeButtonIndex == kMEWApplicationSearchTypeBundleID) {
        predicate = [NSPredicate predicateWithFormat:@"applicationIdentifier CONTAINS[cd] %@", self.searchDisplayController.searchBar.text];
    }
    if (predicate) {
        self.displaySelectedApplications = [[NSMutableArray alloc] initWithArray:[self.selectedApplications filteredArrayUsingPredicate:predicate]];
        self.displayUnselectedApplications = [[NSMutableArray alloc] initWithArray:[self.unselectedApplications filteredArrayUsingPredicate:predicate]];
    }
}

#pragma mark - Memory

- (void)dealloc {
#ifdef DEBUG
    NSLog(@"[MEWApplicationViewController dealloc]");
#endif
}

@end
