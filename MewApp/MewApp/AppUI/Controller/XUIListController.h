//
//  XUIListController.h
//  XXTouchApp
//
//  Created by Zheng on 14/03/2017.
//  Copyright © 2017 Zheng. All rights reserved.
//

#import <Preferences/PSListController.h>
#import "XUIListControllerProtocol.h"
#import "XUICommonDefine.h"

@interface XUIListController : PSListController <XUIListControllerProtocol>
@property (nonatomic, copy) NSString *filePath;

@end
