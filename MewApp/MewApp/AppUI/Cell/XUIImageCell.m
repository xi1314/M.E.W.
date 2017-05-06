//
//  XUIImageCell.m
//  XXTouchApp
//
//  Created by Zheng on 19/03/2017.
//  Copyright © 2017 Zheng. All rights reserved.
//

#import "XUIImageCell.h"
#import <Preferences/PSSpecifier.h>

@interface XUIImageCell ()
@property (nonatomic, strong) UIImageView *mImageView;

@end

@implementation XUIImageCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier specifier:(PSSpecifier *)specifier {
    if (self = [super initWithStyle:style reuseIdentifier:reuseIdentifier specifier:specifier]) {
        [self addSubview:self.mImageView];
    }
    return self;
}

- (void)refreshCellContentsWithSpecifier:(PSSpecifier *)specifier {
    [super refreshCellContentsWithSpecifier:specifier];
    if (specifier.properties[@"path"]) {
        UIImage *mImage = [UIImage imageWithContentsOfFile:specifier.properties[@"path"]];
        self.mImageView.image = mImage;
    } else {
        self.mImageView.image = nil;
    }
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    if (self.specifier.properties[@"action"] || self.specifier.properties[@"detail"]) {
        [super setSelected:selected animated:animated];
    }
}

- (void)setHighlighted:(BOOL)highlighted animated:(BOOL)animated {
    if (self.specifier.properties[@"action"] || self.specifier.properties[@"detail"]) {
        [super setHighlighted:highlighted animated:animated];
    }
}

#pragma mark - UIView Getters

- (UIImageView *)mImageView {
    if (!_mImageView) {
        UIImageView *mImageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, self.bounds.size.width, self.bounds.size.height)];
        mImageView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        mImageView.contentMode = UIViewContentModeScaleAspectFit;
        mImageView.layer.masksToBounds = YES;
        _mImageView = mImageView;
    }
    return _mImageView;
}

@end
