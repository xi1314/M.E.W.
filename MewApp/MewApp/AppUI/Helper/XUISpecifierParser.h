#import <Preferences/PSListController.h>

static const NSString *kXUINotificationString = @"com.darwindev.xxtouchapp.xui/preferences.changed";

@interface XUISpecifierParser : NSObject
+ (PSCellType)PSCellTypeFromString:(NSString *)str;

+ (NSArray *)specifiersFromArray:(NSArray *)array forTarget:(PSListController *)target;

+ (NSString *)convertPathFromPath:(NSString *)path relativeTo:(NSString *)root;
@end
