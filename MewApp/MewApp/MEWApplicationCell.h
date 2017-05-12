//
//  MEWApplicationCell.h
//  MewApp
//
//  Created by Zheng on 08/05/2017.
//  Copyright © 2017 Zheng. All rights reserved.
//

#import <UIKit/UIKit.h>

static NSString * const kMEWApplicationCellReuseIdentifier = @"kMEWApplicationCellReuseIdentifier";

@interface MEWApplicationCell : UITableViewCell

- (void)setApplicationName:(NSString *)name;

- (NSString *)applicationBundleID;
- (void)setApplicationBundleID:(NSString *)bundleID;

- (void)setApplicationIconData:(NSData *)iconData;

@end
