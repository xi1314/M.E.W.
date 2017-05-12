//
//  MEWSharedUtility.h
//  MewApp
//
//  Created by Zheng on 10/05/2017.
//  Copyright © 2017 Zheng. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MEWConfiguration.h"

@interface MEWSharedUtility : NSObject

+ (instancetype)sharedInstance;
- (id)MEWCopyAnswer:(NSString *)key;
- (BOOL)cleanSystemKeychainWithError:(NSError **)error;

@end
