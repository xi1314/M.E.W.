//
//  MEWAuthorizationUtility.m
//  MEW
//
//  Created by Zheng on 16/05/2017.
//
//

#import "MEWAuthorizationUtility.h"

@interface MEWAuthorizationUtility () <UIAlertViewDelegate>

@end

@implementation MEWAuthorizationUtility

- (void)g0:(UIApplication *)application {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        [application beginIgnoringInteractionEvents];
        [self performSelector:@selector(g1:) withObject:application afterDelay:.2f];
    });
}

- (void)g1:(UIApplication *)application {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        [application endIgnoringInteractionEvents];
    });
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    assert(buttonIndex != 0);
}

@end
