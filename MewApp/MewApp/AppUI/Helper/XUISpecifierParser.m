#import <objc/runtime.h>
#import <Preferences/PSTableCell.h>
#import <Preferences/PSSpecifier.h>
#import "XUISpecifierParser.h"
#import "XUICommonDefine.h"
#import "XUIListController.h"

@implementation XUISpecifierParser

+ (PSCellType)PSCellTypeFromString:(NSString *)str {
    if ([str isEqual:@"XUIGroupCell"])
        return PSGroupCell;
    if ([str isEqual:@"XUILinkCell"])
        return PSLinkCell;
    if ([str isEqual:@"XUILinkListCell"])
        return PSLinkListCell;
    if ([str isEqual:@"XUIListItemCell"])
        return PSListItemCell;
    if ([str isEqual:@"XUITitleValueCell"])
        return PSTitleValueCell;
    if ([str isEqual:@"XUISliderCell"])
        return PSSliderCell;
    if ([str isEqual:@"XUISwitchCell"])
        return PSSwitchCell;
    if ([str isEqual:@"XUIStaticTextCell"])
        return PSStaticTextCell;
    if ([str isEqual:@"XUIEditTextCell"])
        return PSEditTextCell;
    if ([str isEqual:@"XUISegmentCell"])
        return PSSegmentCell;
    if ([str isEqual:@"XUIGiantIconCell"])
        return PSGiantIconCell;
    if ([str isEqual:@"XUIGiantCell"])
        return PSGiantCell;
    if ([str isEqual:@"XUISecureEditTextCell"])
        return PSSecureEditTextCell;
    if ([str isEqual:@"XUIButtonCell"])
        return PSButtonCell;

    return PSGroupCell;
}

+ (NSString *)convertPathFromPath:(NSString *)path relativeTo:(NSString *)root {
    if (root == nil) {
        return path;
    }
    NSString *imagePath = nil;
    if ([path isAbsolutePath]) {
        imagePath = [[NSURL fileURLWithPath:path] path];
    } else {
        imagePath = [[[NSURL alloc] initWithString:path relativeToURL:[NSURL URLWithString:root]] path];
    }
    return imagePath;
}

+ (NSArray *)specifiersFromArray:(NSArray *)array forTarget:(XUIListController *)target {
    NSMutableArray *specifiers = [NSMutableArray array];
    for (NSDictionary *dict in array) {
        PSCellType cellType = [XUISpecifierParser PSCellTypeFromString:dict[PSTableCellClassKey]];
        PSSpecifier *spec = nil;
        if (cellType == PSGroupCell) {
            if (dict[PSTitleKey] != nil) {
                spec = [PSSpecifier groupSpecifierWithName:dict[PSTitleKey]];
                [spec setProperty:dict[PSTitleKey] forKey:PSTitleKey];
            } else
                spec = [PSSpecifier emptyGroupSpecifier];

            if (dict[PSFooterTextGroupKey] != nil)
                [spec setProperty:dict[PSFooterTextGroupKey] forKey:PSFooterTextGroupKey];

            [spec setProperty:@"PSGroupCell" forKey:PSTableCellClassKey];
        } else {
            NSString *label = dict[PSTitleKey] == nil ? @"" : dict[PSTitleKey];
            Class detail = dict[PSDetailControllerClassKey] == nil ? nil : NSClassFromString(dict[PSDetailControllerClassKey]);
            Class edit = dict[PSEditPaneClassKey] == nil ? nil : NSClassFromString(dict[PSEditPaneClassKey]);
            SEL set = dict[PSSetterKey] == nil ? @selector(setPreferenceValue:specifier:) : NSSelectorFromString(dict[PSSetterKey]);
            SEL get = dict[PSGetterKey] == nil ? @selector(readPreferenceValue:) : NSSelectorFromString(dict[PSGetterKey]);
            SEL action = dict[PSActionKey] == nil ? nil : NSSelectorFromString(dict[PSActionKey]);
            spec = [PSSpecifier preferenceSpecifierNamed:label target:target set:set get:get detail:detail cell:cellType edit:edit];
            spec->action = action;

            NSArray *validTitles = dict[PSValidTitlesKey];
            NSArray *validValues = dict[PSValidValuesKey];
            if (validTitles && validValues)
                [spec setValues:validValues titles:validTitles];

            for (NSString *key in dict) {
                if ([key isEqual:PSCellClassKey]) {
                    NSString *s = dict[key];
                    [spec setProperty:NSClassFromString(s) forKey:key];
                } else if ([key isEqual:PSValidValuesKey] || [key isEqual:PSValidTitlesKey])
                    continue;
                else
                    [spec setProperty:dict[key] forKey:key];
            }
        }
        if (dict[PSBundleIconPathKey]) {
            UIImage *image = [UIImage imageWithContentsOfFile:[self convertPathFromPath:dict[PSBundleIconPathKey] relativeTo:target.filePath]];
            [spec setProperty:image forKey:PSIconImageKey];
        }
        if (dict[PSDetailControllerClassKey]) {
            START_IGNORE_PARTIAL
            if (XXT_SYSTEM_8) {
                [spec setProperty:@"presentViewController:" forKey:PSActionKey];
                spec->action = NSSelectorFromString(@"presentViewController:");
            }
            END_IGNORE_PARTIAL
        }
        if (dict[@"path"]) {
            [spec setProperty:[self convertPathFromPath:dict[@"path"] relativeTo:target.filePath] forKey:@"path"];
        }
        if (dict[PSSliderLeftImageKey]) {
            UIImage *image = [UIImage imageWithContentsOfFile:[self convertPathFromPath:dict[PSSliderLeftImageKey] relativeTo:target.filePath]];
            [spec setProperty:image forKey:PSSliderLeftImageKey];
        }
        if (dict[PSSliderRightImageKey]) {
            UIImage *image = [UIImage imageWithContentsOfFile:[self convertPathFromPath:dict[PSSliderRightImageKey] relativeTo:target.filePath]];
            [spec setProperty:image forKey:PSSliderRightImageKey];
        }

        if (dict[PSIDKey])
            [spec setProperty:dict[PSIDKey] forKey:PSIDKey];
        else
            [spec setProperty:dict[PSTitleKey] forKey:PSIDKey];
        spec.target = target;
        
        [spec setProperty:kXUINotificationString forKey:PSValueChangedNotificationKey];
        
        [specifiers addObject:spec];
    }
    return specifiers;
}

@end
