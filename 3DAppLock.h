#import "substrate.h"
#import "PAPasscodeViewController/PAPasscodeViewController.h"
#import "UAObfuscatedString/UAObfuscatedString.h"

@interface SBSApplicationShortcutIcon : NSObject
@end

@interface SBSApplicationShortcutItem : NSObject
+ (instancetype)staticShortcutItemWithDictionary:(NSDictionary *)arg1 localizationHandler:(id)arg2;
- (void)setIcon:(SBSApplicationShortcutIcon *)arg1;
- (NSString *)type;
- (NSString *)bundleIdentifierToLaunch;
- (void)setBundleIdentifierToLaunch:(NSString *)arg1;
@end

@interface SBApplication : NSObject
- (NSArray *)staticApplicationShortcutItems;
- (NSArray *)dynamicApplicationShortcutItems;
- (NSString *)bundleIdentifier;
- (NSString *)displayName;
- (void)didExitWithContext:(id)arg1;
- (SBSApplicationShortcutItem *)createCustomShortcutItemForApplication:(SBApplication *)application;
@end

@interface UIStatusBar : UIView
- (UIColor *)foregroundColor;
- (void)setForegroundColor:(UIColor *)arg1;
@end

@interface UIApplication (ThreeDAppLock)
- (SBApplication *)_accessibilityFrontMostApplication;
- (void)_simulateHomeButtonPress;
@end

@interface SBStateSettings : NSObject
@end

@interface SBActivationSettings : NSObject
@end

@interface BSMutableSettings : NSObject
- (NSMutableIndexSet *)allSettings;
- (BOOL)boolForSetting:(unsigned int)arg1;
@end

@interface SBAppSwitcherModel : NSObject
- (void)_applicationActivationStateDidChange:(id)arg1 withLockScreenViewController:(id)arg2 andLayoutElement:(id)arg3;
- (void)lockFrontMostApplication:(SBApplication *)application;
@end

@interface UIApplicationShortcutIcon (ThreeDAppLock)
+ (id)iconWithCustomImage:(UIImage *)arg1 ;
- (SBSApplicationShortcutIcon *)sbsShortcutIcon;
@end

@interface SBUIAppIconForceTouchController : NSObject
+ (NSArray *)filteredApplicationShortcutItemsWithStaticApplicationShortcutItems:(NSArray *)arg1 dynamicApplicationShortcutItems:(NSArray *)arg2;
@end

@interface SBUIAppIconForceTouchControllerDataProvider
- (NSString *)applicationBundleIdentifier;
- (NSString *)applicationShortcutWidgetBundleIdentifier;
- (NSArray *)applicationShortcutItems;
@end

@interface SBIcon : NSObject
- (SBApplication *)application;
@end

@interface SBIconView : UIView
- (id)initWithContentType:(unsigned long long)arg1;
- (void)_updateJitter;
@end

@interface SBHomeScreenViewController : UIViewController
@end

@interface SBIconController : NSObject
+ (id)sharedInstance;
- (void)_dismissAppIconForceTouchControllerIfNecessaryAnimated:(BOOL)arg1 withCompletionHandler:(id)arg2;
- (BOOL)appIconForceTouchController:(SBUIAppIconForceTouchController *)arg1 shouldActivateApplicationShortcutItem:(SBSApplicationShortcutItem *)arg2 atIndex:(unsigned long long)arg3 forGestureRecognizer:(id)arg4;
- (void)clearHighlightedIcon;
- (void)_launchIcon:(SBIcon *)arg1;
- (void)verifyUnlockApplication:(SBApplication *)application;
- (void)lockFrontMostApplication:(SBApplication *)application;
@end

@interface SBApplicationController : NSObject
+ (id)sharedInstance;
- (NSArray *)allBundleIdentifiers;
- (SBApplication *)applicationWithBundleIdentifier:(NSString *)bundleIdentifier;
@end

@interface SBUIController : NSObject
+ (id)sharedInstance;
- (void)activateApplication:(SBApplication *)arg1;
@end

@interface SBDisplayItem : NSObject
- (NSString *)displayIdentifier;
@end

@interface SBAppSwitcherSnapshotView
+ (UIImageView *)appSwitcherSnapshotViewForDisplayItem:(SBDisplayItem *)arg1 orientation:(long long)arg2 preferringDownscaledSnapshot:(BOOL)arg3 loadAsync:(BOOL)arg4 withQueue:(id)arg5;
@end

@interface SBLockScreenManager : NSObject
-(void)_setUILocked:(BOOL)arg1;
@end

@interface LAContext : NSObject
- (void)setCancelButtonVisible:(BOOL)arg1;
- (void)setLocalizedFallbackTitle:(NSString *)arg1;
- (BOOL)canEvaluatePolicy:(int)arg1 error:(id *)arg2;
- (void)evaluatePolicy:(int)arg1 localizedReason:(id)arg2 reply:(void (^)(BOOL success, NSError *error))arg3;
@end

@interface CAFilter : NSObject
+ (id)filterWithName:(NSString *)arg1;
@end

@interface FBSystemService : NSObject
+ (id)sharedInstance;
- (void)exitAndRelaunch:(BOOL)arg1;
@end

@interface SBSRelaunchAction : NSObject
+ (id)actionWithReason:(id)arg1 options:(unsigned int)arg2 targetURL:(id)arg3;
@end

@interface FBSSystemService : NSObject
+ (id)sharedService;
- (void)sendActions:(NSSet *)arg1 withResult:(id)arg2;
@end

@interface ThreeDApplockPasscodeDelegate : NSObject <PAPasscodeViewControllerDelegate>
@end

typedef NS_ENUM (NSInteger, LAPolicy) {
   LAPolicyDeviceOwnerAuthenticationWithBiometrics = 1 
};

typedef NS_ENUM (NSInteger, LAError) {
   LAErrorUserFallback = -3
};

static NSMutableDictionary *lockedApps = [NSMutableDictionary dictionary];

static SBHomeScreenViewController *homeScreenVC;

static UIStatusBar *statusBar;
static UIColor *originalColor;

static BOOL isAppExiting = NO;
static BOOL isAppLaunchingFromIcon = NO;
static NSUserDefaults *defaults;

static BOOL enabled;
static BOOL showSubtitle;
static BOOL alwaysPasscodeButton;

static void showAlertWithTitleAndMessage(NSString *title, NSString *message) {
	#pragma clang diagnostic push
	#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:title message:message delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
    
    [alert show];
    #pragma clang diagnostic pop
}

static void lockAppWithIdentifier(NSString *identifier, BOOL lock) {
	[lockedApps setObject:[NSNumber numberWithBool:lock] forKey:identifier];

	[defaults setObject:lockedApps forKey:@"lockedApps"];
	[defaults synchronize];
}

static void presentPasscodeScreenWithTag(int tag) {
	PAPasscodeViewController *passcodeViewController;
	if (![defaults objectForKey:@"passcode"]) {
		passcodeViewController = [[PAPasscodeViewController alloc] initForAction:PasscodeActionSet];
	}

	else {
		passcodeViewController = [[PAPasscodeViewController alloc] initForAction:PasscodeActionEnter];
		passcodeViewController.passcode = [defaults objectForKey:@"passcode"];
	}

	passcodeViewController.delegate = [[ThreeDApplockPasscodeDelegate alloc] init];
	passcodeViewController.view.tag = tag;
	
	[homeScreenVC presentViewController:[[UINavigationController alloc] initWithRootViewController:passcodeViewController] animated:YES completion:^{
		statusBar = MSHookIvar<UIStatusBar *>([UIApplication sharedApplication], "_statusBar");
		[statusBar performSelector:@selector(setForegroundColor:) withObject:[UIColor blackColor] afterDelay:0.1];
	}];
}

static void dismissPasscodeScreenAndResetStatusBar() {
	[homeScreenVC dismissViewControllerAnimated:YES completion:nil];

	statusBar = MSHookIvar<UIStatusBar *>([UIApplication sharedApplication], "_statusBar");
	[statusBar setForegroundColor:originalColor];
}

static void homeButtonPress() {
	dispatch_after(dispatch_time(DISPATCH_TIME_NOW, NSEC_PER_SEC), dispatch_get_main_queue(), ^{
		[[UIApplication sharedApplication] _simulateHomeButtonPress];
	});
}