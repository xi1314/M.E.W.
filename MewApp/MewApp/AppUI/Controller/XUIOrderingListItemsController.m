//
//  XUIOrderingListItemsController.m
//  XXTouchApp
//
//  Created by Zheng on 19/03/2017.
//  Copyright © 2017 Zheng. All rights reserved.
//

#import "XUIOrderingListItemsController.h"
#import <Preferences/PSSpecifier.h>

#define kXUICellIdentifier @"XUICellIdentifier"

@interface XUIOrderingListItemsController () <UITableViewDelegate, UITableViewDataSource>
@property (nonatomic, strong) IBOutlet UITableView *tableView;

@end

@implementation XUIOrderingListItemsController {
    NSMutableArray *_currentValues;
    NSMutableArray *_leftValues;
    NSUInteger _maxCount;
    NSUInteger _minCount;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    if (self.specifier.properties[@"maxCount"]) {
        _maxCount = [self.specifier.properties[@"maxCount"] unsignedIntegerValue];
    } else {
        _maxCount = 1;
    }
    
    if (self.specifier.properties[@"minCount"]) {
        _minCount = [self.specifier.properties[@"minCount"] unsignedIntegerValue];
    } else {
        _minCount = 0;
    }
    
    _currentValues = [[self readPreferenceValue:self.specifier] mutableCopy];
    if (_currentValues == nil) {
        _currentValues = [NSMutableArray array];
    }
    NSMutableArray *leftValues = [NSMutableArray arrayWithArray:self.specifier.titleDictionary.allKeys];
    for (id curVal in _currentValues) {
        [leftValues removeObject:curVal];
    }
    _leftValues = leftValues;
    
    if ([_currentValues isKindOfClass:[NSArray class]]) {
        [self.view addSubview:self.tableView];
    }
}

#pragma mark - Table View

- (UITableView *)tableView {
    if (!_tableView) {
        UITableView *tableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStylePlain];
        tableView.delegate = self;
        tableView.dataSource = self;
        tableView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        tableView.editing = YES;
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

- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
    return YES;
}

- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath {
    return UITableViewCellEditingStyleNone;
}

- (NSIndexPath *)tableView:(UITableView *)tableView targetIndexPathForMoveFromRowAtIndexPath:(NSIndexPath *)sourceIndexPath toProposedIndexPath:(NSIndexPath *)proposedDestinationIndexPath {
    if (sourceIndexPath.section == 1 && proposedDestinationIndexPath.section == 0) {
        // Move In
        if (_currentValues.count >= _maxCount) {
            return sourceIndexPath;
        }
    } else if (sourceIndexPath.section == 0 && proposedDestinationIndexPath.section == 1) {
        // Move Out
        if (_currentValues.count <= _minCount) {
            return sourceIndexPath;
        }
    }
    return proposedDestinationIndexPath;
}

- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)sourceIndexPath toIndexPath:(NSIndexPath *)destinationIndexPath {
    if (sourceIndexPath.section == 0 && destinationIndexPath.section == 0) {
        [_currentValues exchangeObjectAtIndex:sourceIndexPath.row withObjectAtIndex:destinationIndexPath.row];
    } else if (sourceIndexPath.section == 1 && destinationIndexPath.section == 1) {
        [_leftValues exchangeObjectAtIndex:sourceIndexPath.row withObjectAtIndex:destinationIndexPath.row];
    } else if (sourceIndexPath.section == 0 && destinationIndexPath.section == 1) {
        [_leftValues insertObject:_currentValues[sourceIndexPath.row] atIndex:destinationIndexPath.row];
        [_currentValues removeObjectAtIndex:sourceIndexPath.row];
    } else if (sourceIndexPath.section == 1 && destinationIndexPath.section == 0) {
        [_currentValues insertObject:_leftValues[sourceIndexPath.row] atIndex:destinationIndexPath.row];
        [_leftValues removeObjectAtIndex:sourceIndexPath.row];
    }
    [self setPreferenceValue:[_currentValues copy] specifier:self.specifier];
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    if (section == 0) {
        return NSLocalizedString(@"Selected", nil);
    } else if (section == 1) {
        return NSLocalizedString(@"Remained", nil);
    }
    return @"";
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section {
    if (section == 0) {
        return @"";
    } else if (section == 1) {
        return self.specifier.properties[PSStaticTextMessageKey];
    }
    return @"";
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (section == 0) {
        return _currentValues.count;
    } else if (section == 1) {
        return _leftValues.count;
    }
    return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell =
    [tableView dequeueReusableCellWithIdentifier:kXUICellIdentifier];
    if (nil == cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault
                                      reuseIdentifier:kXUICellIdentifier];
    }
    cell.contentView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin;
    cell.tintColor = [UIColor colorWithRed:0.0 green:122.0/255.0 blue:1.0 alpha:1.0];
    cell.showsReorderControl = YES;
    if (indexPath.section == 0) {
        cell.textLabel.text = self.specifier.titleDictionary[_currentValues[indexPath.row]];
    } else if (indexPath.section == 1) {
        cell.textLabel.text = self.specifier.titleDictionary[_leftValues[indexPath.row]];
    }
    return cell;
}

@end

