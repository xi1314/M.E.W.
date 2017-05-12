//
//  XUIListController.m
//  XXTouchApp
//
//  Created by Zheng on 14/03/2017.
//  Copyright © 2017 Zheng. All rights reserved.

#import "AppDelegate.h"
#import "XUIAction.h"
#import "XUIListController.h"
#import "XUISpecifierParser.h"
#import <Preferences/PSSpecifier.h>
#import "XUICommonDefine.h"

@interface PSListController (Rotation)
- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation;
@end

@interface XUIListController () <XUIAction>
@property (nonatomic, strong) UIBarButtonItem *closeItem;
@property (nonatomic, strong) NSDictionary *plistDict;

@end

@implementation XUIListController

- (void)loadView {
    [super loadView];
    
    BOOL tintSwitches_ = YES;
    
    if ([self respondsToSelector:@selector(tintSwitches)])
        tintSwitches_ = [self tintSwitches];
    
    if (tintSwitches_) {
        if ([self respondsToSelector:@selector(switchOnTintColor)]) {
            START_IGNORE_PARTIAL
            if (!XXT_SYSTEM_9)
                [UISwitch appearanceWhenContainedIn:self.class, nil].onTintColor = self.switchOnTintColor;
            else
                [UISwitch appearanceWhenContainedInInstancesOfClasses:@[self.class]].onTintColor = self.switchOnTintColor;
            END_IGNORE_PARTIAL
        } else {
            if ([self respondsToSelector:@selector(tintColor)]) {
                START_IGNORE_PARTIAL
                if (!XXT_SYSTEM_9)
                    [UISwitch appearanceWhenContainedIn:self.class, nil].onTintColor = self.tintColor;
                else
                    [UISwitch appearanceWhenContainedInInstancesOfClasses:@[self.class]].onTintColor = self.tintColor;
                END_IGNORE_PARTIAL
            }
        }
        
        if ([self respondsToSelector:@selector(switchTintColor)]) {
            START_IGNORE_PARTIAL
            if (!XXT_SYSTEM_9)
                [UISwitch appearanceWhenContainedIn:self.class, nil].onTintColor = self.switchTintColor;
            else
                [UISwitch appearanceWhenContainedInInstancesOfClasses:@[self.class]].onTintColor = self.switchTintColor;
            END_IGNORE_PARTIAL
        } else if ([self respondsToSelector:@selector(tintColor)]) {
            START_IGNORE_PARTIAL
            if (!XXT_SYSTEM_9)
                [UISwitch appearanceWhenContainedIn:self.class, nil].onTintColor = self.tintColor;
            else
                [UISwitch appearanceWhenContainedInInstancesOfClasses:@[self.class]].onTintColor = self.tintColor;
            END_IGNORE_PARTIAL
        }
    }
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [self setupHeader];
    
    if ([self respondsToSelector:@selector(tintColor)]) {
        self.view.tintColor = self.tintColor;
    }
    if ([self respondsToSelector:@selector(navigationTintColor)]) {
        self.navigationController.navigationBar.tintColor = self.navigationTintColor;
    } else if ([self respondsToSelector:@selector(tintColor)]) {
        self.navigationController.navigationBar.tintColor = self.tintColor;
    }
    
    BOOL tintNavText = YES;
    if ([self respondsToSelector:@selector(tintNavigationTitleText)])
        tintNavText = self.tintNavigationTitleText;
    
    if (tintNavText) {
        if ([self respondsToSelector:@selector(navigationTitleTintColor)])
            self.navigationController.navigationBar.titleTextAttributes = @{NSForegroundColorAttributeName: self.navigationTitleTintColor};
        else if ([self respondsToSelector:@selector(tintColor)])
            self.navigationController.navigationBar.titleTextAttributes = @{NSForegroundColorAttributeName: self.tintColor};
    }
}

- (void)setupHeader {
    UIView *header = nil;
    
    if ([self respondsToSelector:@selector(headerText)] && self.headerText.length != 0) {
        header = [[UIView alloc] initWithFrame:CGRectMake(0, 0, UIScreen.mainScreen.bounds.size.width, 60)];
        
        UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(0, 30, header.frame.size.width, header.frame.size.height + 20)];
        label.text = self.headerText;
        label.font = [UIFont fontWithName:@"HelveticaNeue-UltraLight" size:45];
        label.backgroundColor = [UIColor clearColor];
        
        if ([self respondsToSelector:@selector(headerColor)])
            label.textColor = self.headerColor;
        
        label.textAlignment = NSTextAlignmentCenter;
        
        if ([self respondsToSelector:@selector(headerSubText)] && self.headerSubText.length != 0) {
            header.frame = CGRectMake(header.frame.origin.x, header.frame.origin.y, header.frame.size.width, header.frame.size.height + 60);
            
            label.frame = CGRectMake(label.frame.origin.x, 10, label.frame.size.width, label.frame.size.height);
            [header addSubview:label];
            
            UILabel *subText = [[UILabel alloc] initWithFrame:CGRectMake(header.frame.origin.x, label.frame.origin.y + label.frame.size.height, header.frame.size.width, 20)];
            subText.text = self.headerSubText;
            subText.font = [UIFont fontWithName:@"HelveticaNeue-UltraLight" size:16];
            subText.backgroundColor = [UIColor clearColor];
            
            if ([self respondsToSelector:@selector(headerColor)])
                subText.textColor = self.headerColor;
            
            subText.textAlignment = NSTextAlignmentCenter;
            
            [header addSubview:subText];
        } else {
            label.frame = CGRectMake(label.frame.origin.x, 5, label.frame.size.width, label.frame.size.height);
            [header addSubview:label];
        }
    }
    
    if ([self respondsToSelector:@selector(headerView)]) {
        header = self.headerView;
    }
    
    if (header) {
        header.backgroundColor = [UIColor clearColor];
        
        header.autoresizesSubviews = YES;
        header.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        
        [self.table setTableHeaderView:header];
    }
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation {
    [super didRotateFromInterfaceOrientation:fromInterfaceOrientation];
    [UIView animateWithDuration:.3f
                          delay:0
                        options:UIViewAnimationOptionCurveLinear
                     animations:^{
                         [self setupHeader];
                     } completion:^(BOOL finished) {}];
}

- (void)viewDidLoad {
    NSString *rootPath = nil;
    
    UIViewController *parentController = nil;
    NSInteger numberOfViewControllers = self.navigationController.viewControllers.count;
    if (numberOfViewControllers < 2)
        parentController = self.navigationController.viewControllers[0];
    else
        parentController = self.navigationController.viewControllers[numberOfViewControllers - 2];
    
    if (parentController != self) {
        rootPath = [parentController performSelector:@selector(filePath)];
    } else {
        rootPath = self.filePath;
    }
    
    if (self.specifier && self.specifier.properties[@"path"]) {
        self.filePath = self.specifier.properties[@"path"];
    }
    
    [self setupAppearance];
    [super viewDidLoad];
    [self setTitle:self.title];
    
    if (!self.plistDict) {
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Error", nil)
                                                            message:[NSString stringWithFormat:NSLocalizedString(@"Cannot parse: %@.", nil), self.filePath]
                                                           delegate:nil
                                                  cancelButtonTitle:NSLocalizedString(@"OK", nil)
                                                  otherButtonTitles:nil];
        [alertView show];
    }
}

- (void)setupAppearance {
    
}

#pragma mark - UIView Getters

- (UIBarButtonItem *)closeItem {
    if (!_closeItem) {
        UIBarButtonItem *closeItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Close", nil) style:UIBarButtonItemStylePlain target:self action:@selector(closeItemTapped:)];
        closeItem.tintColor = [UIColor blackColor];
        _closeItem = closeItem;
    }
    return _closeItem;
}

#pragma mark - Actions

- (void)closeItemTapped:(UIBarButtonItem *)sender {
    [self.view endEditing:YES];
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - Getters

- (NSDictionary *)plistDict {
    if (!_plistDict) {
        NSDictionary *plistDict = [[NSDictionary alloc] initWithContentsOfFile:self.filePath];
        if (!plistDict) {
            // ? maybe JSON format
            NSError *error = nil;
            NSData *jsonData = [NSData dataWithContentsOfFile:self.filePath];
            if (jsonData) {
                plistDict = [NSJSONSerialization JSONObjectWithData:jsonData options:0 error:&error];
            }
        }
        _plistDict = plistDict;
    }
    return _plistDict;
}

#pragma mark - List View

- (NSString *)plistName {
    return @"";
}

- (NSArray <PSSpecifier *> *)specifiers {
    if (!_specifiers) {
        _specifiers = [XUISpecifierParser specifiersFromArray:self.customSpecifiers forTarget:self];
    }
    return _specifiers;
}

- (NSArray <NSDictionary *> *)customSpecifiers {
    return self.plistDict[@"items"];
}

- (NSString *)navigationTitle {
    return self.customTitle;
}

- (NSString *)title {
    if (self.customTitle.length == 0) {
        return NSLocalizedString(@"DynamicXUI", nil);
    }
    return self.customTitle;
}

- (NSString *)customTitle {
    return self.plistDict[@"title"];
}

- (NSString *)headerText {
    return self.plistDict[@"header"];
}

- (NSString *)headerSubText {
    return self.plistDict[@"subheader"];
}

- (UIColor *)navigationTintColor {
    return MAIN_COLOR;
}

- (UIColor *)navigationTitleTintColor {
    return [UIColor blackColor];
}

- (UIColor *)tintColor {
    return MAIN_COLOR;
}

- (UIColor *)headerColor {
    return [UIColor blackColor];
}

- (UIColor *)switchTintColor {
    return MAIN_COLOR;
}

- (UIColor *)switchOnTintColor {
    return MAIN_COLOR;
}

#pragma mark - Keyboard

- (void)_returnKeyPressed:(NSConcreteNotification *)notification {
    [self.view endEditing:YES];
    [super _returnKeyPressed:notification];
}

#pragma mark - Button Actions

- (void)copyValue:(PSSpecifier *)specifier {
    NSArray <NSString *> *kwargs = specifier.properties[@"kwargs"];
    if (!kwargs || kwargs.count == 0) return;
    id arg1 = kwargs[0];
    if ([arg1 isKindOfClass:[NSString class]]) {
        [[UIPasteboard generalPasteboard] setString:[NSString stringWithFormat:@"%@", arg1]];
    }
}

- (void)dismissViewController {
    [self closeItemTapped:nil];
}

- (void)popViewController {
    [self.view endEditing:YES];
    [self.navigationController popViewControllerAnimated:YES];
}

#pragma mark - Hidden action

- (void)presentViewController:(PSSpecifier *)specifier {
    if (specifier.properties[PSDetailControllerClassKey]) {
        Class className = NSClassFromString(specifier.properties[PSDetailControllerClassKey]);
        PSViewController *newController = [[className alloc] init];
        newController.specifier = specifier;
        [self.navigationController pushViewController:newController animated:YES];
    }
}

- (void)noAction {
    
}

- (void)exit {
    exit(0);
}

#pragma mark - XUITitleValueCell

- (NSString *)valueForSpecifier:(PSSpecifier *)specifier {
    if (specifier.properties[PSDefaultsKey] && specifier.properties[PSKeyNameKey]) {
        NSDictionary *configDict = [[NSDictionary alloc] initWithContentsOfFile:[specifier.properties[PSDefaultsKey] stringByAppendingPathExtension:@"plist"]];
        return [NSString stringWithFormat:@"%@", configDict[specifier.properties[PSKeyNameKey]]];
    } else if (specifier.properties[PSValueKey] && [specifier.properties[PSValueKey] isKindOfClass:[NSString class]]) {
        return specifier.properties[PSValueKey];
    }
    return @"";
}

#pragma mark - Memory

- (void)dealloc {
    
}

@end
