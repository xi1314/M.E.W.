//
//  LSApplicationProxy.h
//  MEW
//
//  Created by Zheng on 05/05/2017.
//
//

#ifndef LSApplicationProxy_h
#define LSApplicationProxy_h

#import <Foundation/Foundation.h>

@interface LSApplicationProxy : NSObject

+ (LSApplicationProxy *)applicationProxyForIdentifier:(NSString *)bid;
- (NSData *)iconDataForVariant:(int)arg1;
- (NSString *)itemName;
- (NSString *)localizedName;
- (NSURL *)resourcesDirectoryURL;
- (NSURL *)containerURL;
- (NSURL *)dataContainerURL;

@property (nonatomic, readonly) NSString *applicationIdentifier;

@end

#endif /* LSApplicationProxy_h */
