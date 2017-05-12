//
//  MEWApplicationCell.m
//  MewApp
//
//  Created by Zheng on 08/05/2017.
//  Copyright © 2017 Zheng. All rights reserved.
//

#import "MEWApplicationCell.h"
#import "UIImage+imageData.h"

@interface MEWApplicationCell ()
@property (weak, nonatomic) IBOutlet UIImageView *iconImageView;
@property (weak, nonatomic) IBOutlet UILabel *appLabel;
@property (weak, nonatomic) IBOutlet UILabel *bundleIDLabel;

@end

@implementation MEWApplicationCell

- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
    
    self.iconImageView.layer.masksToBounds = YES;
    self.iconImageView.layer.cornerRadius = 6.f;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (void)setApplicationName:(NSString *)name {
    self.appLabel.text = name;
}

- (void)setApplicationBundleID:(NSString *)bundleID {
    self.bundleIDLabel.text = bundleID;
}

- (void)setApplicationIconData:(NSData *)iconData {
    self.iconImageView.image = [UIImage imageWithImageData:iconData];
}

- (NSString *)applicationBundleID {
    return self.bundleIDLabel.text;
}

@end
