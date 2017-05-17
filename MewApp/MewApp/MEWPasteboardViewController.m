//
//  MEWPasteboardViewController.m
//  MewApp
//
//  Created by Zheng on 10/05/2017.
//  Copyright © 2017 Zheng. All rights reserved.
//

#import "MEWPasteboardViewController.h"
#import "MEWPasteboardCell.h"
#import <Preferences/PSSpecifier.h>

enum {
    kMEWPasteboardCellSection = 0,
};

enum {
    kMEWPasteboardSearchTypeString = 0,
    kMEWPasteboardSearchTypeBundleID
};

@interface MEWPasteboardViewController ()
<
UITableViewDelegate,
UITableViewDataSource,
UISearchDisplayDelegate,
UIAlertViewDelegate
>

@property(nonatomic, strong) UITableView *tableView;
@property(nonatomic, strong) NSArray <NSDictionary *> *pasteboardArray;
@property(nonatomic, strong) NSArray <NSDictionary *> *displayPasteboardArray;

@end

@implementation MEWPasteboardViewController {
    UISearchDisplayController *_searchDisplayController;
}


#pragma mark - Default Style

- (UIStatusBarStyle)preferredStatusBarStyle {
    return UIStatusBarStyleDefault;
}

- (NSString *)title {
    return [self.specifier propertyForKey:PSTitleKey];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.edgesForExtendedLayout = UIRectEdgeLeft | UIRectEdgeBottom | UIRectEdgeRight;
    
    NSArray *pasteboardArray = [self readPreferenceValue:self.specifier];
    self.pasteboardArray = pasteboardArray;
    
    UISearchBar *searchBar = [[UISearchBar alloc] initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width, 44.f)];
    searchBar.placeholder = @"搜索剪贴板";
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
    
    UIBarButtonItem *clearItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemTrash
                                                                               target:self
                                                                               action:@selector(clearPasteboardHistory:)];
    self.navigationItem.rightBarButtonItem = clearItem;
    
    UITableView *tableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStylePlain];
    [tableView registerNib:[UINib nibWithNibName:@"MEWPasteboardCell" bundle:[NSBundle mainBundle]] forCellReuseIdentifier:kMEWPasteboardCellReuseIdentifier];
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
    
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 44.f;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (section == kMEWPasteboardCellSection) {
        if (tableView == self.tableView) {
            return self.pasteboardArray.count;
        } else {
            return self.displayPasteboardArray.count;
        }
    }
    return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    MEWPasteboardCell *cell = [tableView dequeueReusableCellWithIdentifier:kMEWPasteboardCellReuseIdentifier];
    if (cell == nil) {
        cell = [[MEWPasteboardCell alloc] initWithStyle:UITableViewCellStyleDefault
                                        reuseIdentifier:kMEWPasteboardCellReuseIdentifier];
    }
    if (indexPath.section == kMEWPasteboardCellSection) {
        if (tableView == self.tableView) {
            cell.textLabel.text = self.pasteboardArray[indexPath.row][@"string"];
        } else {
            cell.textLabel.text = self.displayPasteboardArray[indexPath.row][@"string"];
        }
    }
    [cell setTintColor:MAIN_COLOR];
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    UIPasteboard *pasteboard = [UIPasteboard generalPasteboard];
    if (tableView == self.tableView) {
        [pasteboard setString:self.pasteboardArray[indexPath.row][@"string"]];
    } else {
        [pasteboard setString:self.displayPasteboardArray[indexPath.row][@"string"]];
    }
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"提示"
                                                        message:@"已成功复制到剪贴板。"
                                                       delegate:nil
                                              cancelButtonTitle:@"好"
                                              otherButtonTitles:nil];
    [alertView show];
}

- (void)tableView:(UITableView *)tableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath {
    NSDictionary *pasteboardDetail = nil;
    if (tableView == self.tableView) {
        pasteboardDetail = self.pasteboardArray[indexPath.row];
    } else {
        pasteboardDetail = self.displayPasteboardArray[indexPath.row];
    }
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:pasteboardDetail[@"applicationIdentifier"]
                                                        message:[NSString stringWithFormat:@"%@", pasteboardDetail[@"date"]]
                                                       delegate:nil
                                              cancelButtonTitle:@"好"
                                              otherButtonTitles:nil];
    [alertView show];
}

#pragma mark - UISearchDisplayDelegate

- (void)searchDisplayController:(UISearchDisplayController *)controller willShowSearchResultsTableView:(UITableView *)tableView {
    [tableView registerNib:[UINib nibWithNibName:@"MEWPasteboardCell" bundle:[NSBundle mainBundle]] forCellReuseIdentifier:kMEWPasteboardCellReuseIdentifier];
}

- (BOOL)searchDisplayController:(UISearchDisplayController *)controller shouldReloadTableForSearchString:(NSString *)searchString {
    [self tableViewReloadSearch:controller.searchResultsTableView];
    return YES;
}

- (void)tableViewReloadSearch:(UITableView *)tableView {
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"string CONTAINS[cd] %@", self.searchDisplayController.searchBar.text];
    if (predicate) {
        self.displayPasteboardArray = [[NSMutableArray alloc] initWithArray:[self.pasteboardArray filteredArrayUsingPredicate:predicate]];
    }
}

#pragma mark - Button Actions

- (void)clearPasteboardHistory:(id)sender {
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"警告"
                                                        message:@"您确定要清空剪贴板历史记录吗？\n此操作不可撤销。"
                                                       delegate:self
                                              cancelButtonTitle:@"取消"
                                              otherButtonTitles:@"确定", nil];
    [alertView show];
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (buttonIndex == 1) {
        [self setPreferenceValue:@[] specifier:self.specifier];
        self.pasteboardArray = @[];
        [self.tableView reloadData];
    }
}

#pragma mark - Memory

- (void)dealloc {
#ifdef TEST_FLAG
    NSLog(@"[MEWPasteboardViewController dealloc]");
#endif
}

@end
