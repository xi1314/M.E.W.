#import "XUIListItemsController.h"
#import "XUICommonDefine.h"

@implementation XUIListItemsController

- (void)viewWillAppear:(BOOL)animated {
    if ([self respondsToSelector:@selector(tintColor)]) {
        self.view.tintColor = self.tintColor;
    }
    
    if ([self respondsToSelector:@selector(switchTintColor)]) {
        START_IGNORE_PARTIAL
        if (!XXT_SYSTEM_9)
            [UITableViewCell appearanceWhenContainedIn:self.class, nil].tintColor = self.switchTintColor;
        else
            [UITableViewCell appearanceWhenContainedInInstancesOfClasses:@[self.class]].tintColor = self.switchTintColor;
        END_IGNORE_PARTIAL
    }

    if ([self respondsToSelector:@selector(navigationTintColor)]) {
        self.navigationController.navigationBar.tintColor = self.navigationTintColor;
    } else {
        if ([self respondsToSelector:@selector(tintColor)]) {
            self.navigationController.navigationBar.tintColor = self.tintColor;
        }
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

    [super viewWillAppear:animated];
}

@end
