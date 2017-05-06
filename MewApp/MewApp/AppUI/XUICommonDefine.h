#import <Preferences/PSListController.h>
#import <Preferences/PSTableCell.h>

@interface PSListController (SettingsKit)
- (UIView *)view;

- (UINavigationController *)navigationController;

- (void)viewWillAppear:(BOOL)animated;

- (void)viewWillDisappear:(BOOL)animated;

- (void)viewDidDisappear:(BOOL)animated;

- (void)presentViewController:(UIViewController *)viewControllerToPresent animated:(BOOL)flag completion:(void (^)(void))completion;

- (void)dismissViewControllerAnimated:(BOOL)flag completion:(void (^)(void))completion;

- (void)loadView;
@end

@interface PSTableCell (SettingsKit)
@property(nonatomic) UIView *backgroundView;

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier specifier:(PSSpecifier *)specifier;

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier;

- (UILabel *)textLabel;
@end

@interface UIPreferencesTable : UITableView
@end
