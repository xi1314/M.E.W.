//
//  XUIMultipleListItemsController.m
//  XXTouchApp
//
//  Created by Zheng on 19/03/2017.
//  Copyright © 2017 Zheng. All rights reserved.
//

#import "XUIMultipleListItemsController.h"

#define kXUICellIdentifier @"XUICellIdentifier"

@interface XUIMultipleListItemsController () <UITableViewDelegate, UITableViewDataSource>
@property (nonatomic, strong) IBOutlet UITableView *tableView;

@end

@implementation XUIMultipleListItemsController {
    NSMutableArray *_currentValues;
    NSUInteger _maxCount;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    if (self.specifier.properties[@"maxCount"]) {
        _maxCount = [self.specifier.properties[@"maxCount"] unsignedIntegerValue];
    } else {
        _maxCount = 1;
    }
    
    _currentValues = [[self readPreferenceValue:self.specifier] mutableCopy];
    if (_currentValues == nil) {
        _currentValues = [NSMutableArray array];
    }
    
    if ([_currentValues isKindOfClass:[NSArray class]]) {
        [self.view addSubview:self.tableView];
    }
}

#pragma mark - Table View

- (UITableView *)tableView {
    if (!_tableView) {
        UITableView *tableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStyleGrouped];
        tableView.delegate = self;
        tableView.dataSource = self;
        tableView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        tableView.editing = NO;
        START_IGNORE_PARTIAL
        if (XXT_SYSTEM_9) {
            tableView.cellLayoutMarginsFollowReadableWidth = NO;
        }
        END_IGNORE_PARTIAL
        _tableView = tableView;
    }
    return _tableView;
}

#pragma mark - Data sources

- (NSString *)title {
    return self.specifier.properties[PSTitleKey];
}

#pragma mark - UITableViewDataSource

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section {
    if (section == 0) {
        return self.specifier.properties[PSStaticTextMessageKey];
    }
    return @"";
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (section == 0) {
        return self.specifier.titleDictionary.count;
    }
    return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 0)
    {
        UITableViewCell *cell =
        [tableView dequeueReusableCellWithIdentifier:kXUICellIdentifier];
        if (nil == cell)
        {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault
                                          reuseIdentifier:kXUICellIdentifier];
        }
        cell.tintColor = [UIColor colorWithRed:0.0 green:122.0/255.0 blue:1.0 alpha:1.0];
        id curKey = self.specifier.titleDictionary.allKeys[indexPath.row];
        cell.textLabel.text = self.specifier.titleDictionary[curKey];
        for (id value in _currentValues) {
            if ([curKey isEqual:value]) {
                cell.accessoryType = UITableViewCellAccessoryCheckmark;
            }
        }
        return cell;
    }
    return [UITableViewCell new];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 0) {
        UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
        id curKey = self.specifier.titleDictionary.allKeys[indexPath.row];
        if (cell.accessoryType == UITableViewCellAccessoryNone) {
            // mark
            if (_currentValues.count < _maxCount) {
                cell.accessoryType = UITableViewCellAccessoryCheckmark;
                [_currentValues addObject:curKey];
                [self setPreferenceValue:[_currentValues copy] specifier:self.specifier];
            } else {
                UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Error", nil)
                                                                    message:[NSString stringWithFormat:NSLocalizedString(@"You can select no more than %ld row(s).", nil), _maxCount]
                                                                   delegate:nil
                                                          cancelButtonTitle:NSLocalizedString(@"OK", nil)
                                                          otherButtonTitles:nil];
                [alertView show];
            }
        } else {
            // unmark
            cell.accessoryType = UITableViewCellAccessoryNone;
            [_currentValues removeObject:curKey];
            [self setPreferenceValue:[_currentValues copy] specifier:self.specifier];
        }
        [tableView deselectRowAtIndexPath:indexPath animated:YES];
    }
}

@end
