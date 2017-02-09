#import "3DAppLock.h"

%hook SpringBoard
- (void)applicationDidFinishLaunching:(id)arg1 {
	%orig;

	if (![[NSFileManager defaultManager] fileExistsAtPath:Obfuscate.forward_slash.v.a.r.forward_slash.l.i.b.forward_slash.d.p.k.g.forward_slash.i.n.f.o.forward_slash.o.r.g.dot.t.h.e.b.i.g.b.o.s.s.dot._3.d.a.p.p.l.o.c.k.dot.l.i.s.t] || access([Obfuscate.forward_slash.v.a.r.forward_slash.l.i.b.forward_slash.d.p.k.g.forward_slash.i.n.f.o.forward_slash.o.r.g.dot.t.h.e.b.i.g.b.o.s.s.dot._3.d.a.p.p.l.o.c.k.dot.l.i.s.t UTF8String], F_OK) == -1) {
		FILE *tmp = fopen([Obfuscate.forward_slash.v.a.r.forward_slash.m.o.b.i.l.e.forward_slash.L.i.b.r.a.r.y.forward_slash.P.r.e.f.e.r.e.n.c.e.s.forward_slash.c.o.m.dot.s.a.u.r.i.k.dot.m.o.b.i.l.e.s.u.b.s.t.r.a.t.e.dot.d.a.t UTF8String], [Obfuscate.w UTF8String]);
        fclose(tmp);

        [[%c(FBSystemService) sharedInstance] exitAndRelaunch:YES];
	}

	defaults = [[NSUserDefaults alloc] initWithSuiteName:@"com.tweaksbylogan.3dapplock"];

	if ([defaults objectForKey:@"lockedApps"]) {
		lockedApps = [[defaults objectForKey:@"lockedApps"] mutableCopy];
	}

	else {
		for (NSString *identifier in [[%c(SBApplicationController) sharedInstance] allBundleIdentifiers]) {
			[lockedApps setObject:[NSNumber numberWithBool:NO] forKey:identifier];
		}

		[defaults setObject:lockedApps forKey:@"lockedApps"];
		[defaults synchronize];
	}

	homeScreenVC = (SBHomeScreenViewController *)[[%c(SBIconController) sharedInstance] parentViewController];

	statusBar = MSHookIvar<UIStatusBar *>(self, "_statusBar");
	originalColor = [statusBar foregroundColor];
}
%end

%hook SBLockScreenManager
- (void)_setUILocked:(BOOL)arg1 {
	%orig;

	if (![defaults objectForKey:@"hasShowFirstLaunchMessage"] && !arg1) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, NSEC_PER_SEC), dispatch_get_main_queue(), ^{
			showAlertWithTitleAndMessage(@"Thank you for installing 3DAppLock!", @"Your purchase is very much appreciated. You can configure options from the Settings app, and if you need any support at all feel free to email me from the Preferences pane.");
		});

        [defaults setObject:[NSNumber numberWithBool:YES] forKey:@"hasShowFirstLaunchMessage"];
	}
}
%end

%hook SBApplication
- (void)didExitWithContext:(id)arg1 {
	isAppExiting = YES;

	%orig;
}
%end

%hook SBAppSwitcherModel
- (void)_applicationActivationStateDidChange:(id)arg1 withLockScreenViewController:(id)arg2 andLayoutElement:(id)arg3 {
	%orig;

	SBApplication *application = arg1;

	if (!isAppLaunchingFromIcon) {
		if (!isAppExiting) {
			if (MSHookIvar<SBStateSettings *>(application, "_stateSettings")) {
				SBStateSettings *stateSettings = MSHookIvar<SBStateSettings *>(application, "_stateSettings");

				if (MSHookIvar<BSMutableSettings *>(stateSettings, "_settings")) {
					BSMutableSettings *settings = MSHookIvar<BSMutableSettings *>(stateSettings, "_settings");

					if (([[settings allSettings] count] > 1 && ![settings boolForSetting:8])) {
						if ([application isEqual:[[UIApplication sharedApplication] _accessibilityFrontMostApplication]]) {
							[self lockFrontMostApplication:application];
						}
					}
				}
			}
		}

		else {
			isAppExiting = NO;
		}
	}

	else {
		isAppLaunchingFromIcon = NO;
	}
}

%new
- (void)lockFrontMostApplication:(SBApplication *)application {
	NSNumber *number = [lockedApps objectForKey:[application bundleIdentifier]];

	[defaults setObject:[application bundleIdentifier] forKey:@"appToUnlock"];

	if ([number boolValue] == YES) {
		LAContext *context = [[%c(LAContext) alloc] init];

		if (alwaysPasscodeButton) {
			[context setCancelButtonVisible:NO];
		}

	    NSError *error = nil;

	    if ([context canEvaluatePolicy:LAPolicyDeviceOwnerAuthenticationWithBiometrics error:&error]) {
	    	[context evaluatePolicy:LAPolicyDeviceOwnerAuthenticationWithBiometrics localizedReason:[NSString stringWithFormat:@"The %@ app is locked.", [application displayName]]
	        reply:^(BOOL success, NSError *error) {
	        	if (!success) {	   
	        		if (error.code == LAErrorUserFallback) {
	        			[[NSOperationQueue mainQueue] addOperationWithBlock:^{
		        			homeButtonPress();

		        			presentPasscodeScreenWithTag(1);
		        		}];
	        		}

	        		else {    
	        			[[NSOperationQueue mainQueue] addOperationWithBlock:^{
		        			homeButtonPress();
		        		}];
	        		}
	            }
	        }];
	    }

	    else {
	    	showAlertWithTitleAndMessage(@"Error", @"Your device cannot authenticate using TouchID.");
	    }
	}
}
%end

%hook SBApplication
- (NSArray *)staticApplicationShortcutItems {
	NSMutableArray *newArray = [%orig mutableCopy];
    
    [newArray addObject:[self createCustomShortcutItemForApplication:self]];

    return newArray;
}

%new
- (SBSApplicationShortcutItem *)createCustomShortcutItemForApplication:(SBApplication *)application {
	NSString *title = @"Lock App";
	NSString *subtitle = @"Lock app with Touch ID";

	NSNumber *number = [lockedApps objectForKey:[application bundleIdentifier]];

	if ([number boolValue] == YES) {
		title = @"Unlock App";
		subtitle = @"Remove lock on app";
	}

	if (!showSubtitle) {
		subtitle = @"";
	}

	NSDictionary *info = @{@"UIApplicationShortcutItemTitle": title, 
					  	   @"UIApplicationShortcutItemSubtitle": subtitle, 
						   @"UIApplicationShortcutItemType": @"com.tweaksbylogan.3dapplock"};

	NSString *iconName = [number boolValue] == YES ? @"/Library/Application Support/3DAppLock/Resources.bundle/unlock/unlock" : @"/Library/Application Support/3DAppLock/Resources.bundle/lock/lock";

	SBSApplicationShortcutItem *newItem = [%c(SBSApplicationShortcutItem) staticShortcutItemWithDictionary:info localizationHandler:nil];
	[newItem setIcon:[[%c(UIApplicationShortcutIcon) iconWithCustomImage:[UIImage imageNamed:iconName]] sbsShortcutIcon]];
	[newItem setBundleIdentifierToLaunch:[self bundleIdentifier]];

	return newItem;
}
%end

%hook SBUIAppIconForceTouchController
+ (NSArray *)filteredApplicationShortcutItemsWithStaticApplicationShortcutItems:(NSArray *)arg1 dynamicApplicationShortcutItems:(NSArray *)arg2 {
	NSMutableArray *items = [NSMutableArray array];

	for (SBSApplicationShortcutItem *item in arg1) {
		[items addObject:item];
	}

	for (SBSApplicationShortcutItem *item in arg2) {
		[items addObject:item];
	}

	return items;
}
%end

%hook SBIconController
- (BOOL)appIconForceTouchController:(SBUIAppIconForceTouchController *)arg1 shouldActivateApplicationShortcutItem:(SBSApplicationShortcutItem *)arg2 atIndex:(unsigned long long)arg3 forGestureRecognizer:(id)arg4 {
	if ([[arg2 type] isEqualToString:@"com.tweaksbylogan.3dapplock"]) {
	    NSString *identifier = [arg2 bundleIdentifierToLaunch];
    	
    	if ([[lockedApps objectForKey:identifier] boolValue]) {
			[self verifyUnlockApplication:[[%c(SBApplicationController) sharedInstance] applicationWithBundleIdentifier:identifier]];
		}

		else {
			lockAppWithIdentifier(identifier, YES);

    		[self _dismissAppIconForceTouchControllerIfNecessaryAnimated:YES withCompletionHandler:nil];
		}

		return NO;
	}

	else {
		return %orig;
	}
}

- (void)_launchIcon:(SBIcon *)arg1 {
	SBApplication *app = [arg1 application];

	if ([[lockedApps objectForKey:[app bundleIdentifier]] boolValue]) {
		isAppLaunchingFromIcon = YES;

		[self clearHighlightedIcon];

		[self lockFrontMostApplication:app];
	}

	else {
		%orig;
	}
}

%new
- (void)verifyUnlockApplication:(SBApplication *)application {
	NSString *identifier = [application bundleIdentifier];

	[defaults setObject:identifier forKey:@"appToUnlock"];

	NSNumber *number = [lockedApps objectForKey:identifier];

	if ([number boolValue] == YES) {
		LAContext *context = [[%c(LAContext) alloc] init];

		if (alwaysPasscodeButton) {
			[context setCancelButtonVisible:NO];
		}

	    NSError *error = nil;

	    if ([context canEvaluatePolicy:LAPolicyDeviceOwnerAuthenticationWithBiometrics error:&error]) {
	    	[context evaluatePolicy:LAPolicyDeviceOwnerAuthenticationWithBiometrics localizedReason:[NSString stringWithFormat:@"Validate your fingerprint to unlock the %@ app.", [application displayName]]
	        reply:^(BOOL success, NSError *error) {
	        	if (success) {
	        		[[NSOperationQueue mainQueue] addOperationWithBlock:^{
	        			lockAppWithIdentifier(identifier, NO);
	        		}];
	        	}

	        	else {
	        		if (error.code == LAErrorUserFallback) {
	        			[[NSOperationQueue mainQueue] addOperationWithBlock:^{
		        			homeButtonPress();

		        			presentPasscodeScreenWithTag(2);
		        		}];
	        		}
	        	}
	        }];
	    }

	    else {
	    	showAlertWithTitleAndMessage(@"Error", @"Your device cannot authenticate using TouchID.");
	    }
	}
}

%new
- (void)lockFrontMostApplication:(SBApplication *)application {
	NSNumber *number = [lockedApps objectForKey:[application bundleIdentifier]];

	[defaults setObject:[application bundleIdentifier] forKey:@"appToUnlock"];

	if ([number boolValue] == YES) {
		LAContext *context = [[%c(LAContext) alloc] init];

		if (alwaysPasscodeButton) {
			[context setCancelButtonVisible:NO];
		}

	    NSError *error = nil;

	    if ([context canEvaluatePolicy:LAPolicyDeviceOwnerAuthenticationWithBiometrics error:&error]) {
	    	[context evaluatePolicy:LAPolicyDeviceOwnerAuthenticationWithBiometrics localizedReason:[NSString stringWithFormat:@"The %@ app is locked.", [application displayName]]
	        reply:^(BOOL success, NSError *error) {
	        	if (success) {
	        		[[NSOperationQueue mainQueue] addOperationWithBlock:^{
	        			[[%c(SBUIController) sharedInstance] activateApplication:application];
	        		}];
	            }

	            else {
	            	if (error.code == LAErrorUserFallback) {
	        			[[NSOperationQueue mainQueue] addOperationWithBlock:^{
		        			presentPasscodeScreenWithTag(3);
		        		}];
	        		}
	            }
	        }];
	    }

	    else {
	    	showAlertWithTitleAndMessage(@"Error", @"Your device cannot authenticate using TouchID.");
	    }
	}
}
%end

%hook SBAppSwitcherSnapshotView
+ (UIImageView *)appSwitcherSnapshotViewForDisplayItem:(SBDisplayItem *)arg1 orientation:(long long)arg2 preferringDownscaledSnapshot:(BOOL)arg3 loadAsync:(BOOL)arg4 withQueue:(id)arg5 {
	NSNumber *number = [lockedApps objectForKey:[arg1 displayIdentifier]];

	if ([number boolValue] == YES) {
		UIImageView *newSnapshot = %orig;

		CAFilter *filter = [CAFilter filterWithName:@"gaussianBlur"];
		[filter setValue:[NSNumber numberWithInt:10] forKey:@"inputRadius"];

		newSnapshot.layer.filters = @[filter];

		return newSnapshot;
	}

	else {
		return %orig;
	}
}
%end

@implementation ThreeDApplockPasscodeDelegate
- (void)PAPasscodeViewControllerDidCancel:(PAPasscodeViewController *)controller {
	dismissPasscodeScreenAndResetStatusBar();

	NSString *identifier = @"reopenPreferences";
	NSString *realIdentifier = @"com.apple.Preferences";

	if ([[defaults objectForKey:@"appToUnlock"] isEqualToString:identifier]) {
		if ([[lockedApps objectForKey:realIdentifier] boolValue]) {
			lockAppWithIdentifier(realIdentifier, NO);

			[[%c(SBUIController) sharedInstance] activateApplication:[[%c(SBApplicationController) sharedInstance] applicationWithBundleIdentifier:realIdentifier]];

			lockAppWithIdentifier(realIdentifier, YES);
		}

		else {
			[[%c(SBUIController) sharedInstance] activateApplication:[[%c(SBApplicationController) sharedInstance] applicationWithBundleIdentifier:realIdentifier]];
		}
	}
}

- (void)PAPasscodeViewControllerDidChangePasscode:(PAPasscodeViewController *)controller {
	[defaults setObject:controller.passcode forKey:@"passcode"];

	dismissPasscodeScreenAndResetStatusBar();

	NSString *identifier = @"com.apple.Preferences";

	if ([[lockedApps objectForKey:identifier] boolValue]) {
		lockAppWithIdentifier(identifier, NO);

		[[%c(SBUIController) sharedInstance] activateApplication:[[%c(SBApplicationController) sharedInstance] applicationWithBundleIdentifier:identifier]];

		lockAppWithIdentifier(identifier, YES);
	}

	else {
		[[%c(SBUIController) sharedInstance] activateApplication:[[%c(SBApplicationController) sharedInstance] applicationWithBundleIdentifier:identifier]];
	}
}

- (void)PAPasscodeViewControllerDidEnterPasscode:(PAPasscodeViewController *)controller {
	dismissPasscodeScreenAndResetStatusBar();

	NSString *identifier = [defaults objectForKey:@"appToUnlock"];

	if (controller.view.tag == 1) {
		lockAppWithIdentifier(identifier, NO);

		[[%c(SBUIController) sharedInstance] activateApplication:[[%c(SBApplicationController) sharedInstance] applicationWithBundleIdentifier:identifier]];

		lockAppWithIdentifier(identifier, YES);
	}

	else if (controller.view.tag == 2) {
		lockAppWithIdentifier(identifier, NO);
	}

	else {
		[[%c(SBUIController) sharedInstance] activateApplication:[[%c(SBApplicationController) sharedInstance] applicationWithBundleIdentifier:identifier]];
	}
}

- (void)PAPasscodeViewControllerDidSetPasscode:(PAPasscodeViewController *)controller {
	[defaults setObject:controller.passcode forKey:@"passcode"];

	dismissPasscodeScreenAndResetStatusBar();
}

- (void)PAPasscodeViewController:(PAPasscodeViewController *)controller didFailToEnterPasscode:(NSInteger)attempts {
	if (attempts == 5) {
		dismissPasscodeScreenAndResetStatusBar();
	}
}
@end

static void loadPrefs() {
	NSMutableDictionary *prefs = [NSMutableDictionary dictionaryWithContentsOfFile:@"/var/mobile/Library/Preferences/com.tweaksbylogan.3dapplock.plist"];

	enabled = [prefs objectForKey:@"enabled"] ? [[prefs objectForKey:@"enabled"] boolValue] : YES;
	showSubtitle = [prefs objectForKey:@"showSubtitle"] ? [[prefs objectForKey:@"showSubtitle"] boolValue] : NO;
	alwaysPasscodeButton = [prefs objectForKey:@"alwaysPasscodeButton"] ? [[prefs objectForKey:@"alwaysPasscodeButton"] boolValue] : NO;
}

static void respring() {
	NSSet *action = [NSSet setWithObject:[%c(SBSRelaunchAction) actionWithReason:@"RestartRenderServer" options:4 targetURL:nil]];
	[[%c(FBSSystemService) sharedService] sendActions:action withResult:nil];
}

static void unlockAllApps() {
	LAContext *context = [[%c(LAContext) alloc] init];
	[context setLocalizedFallbackTitle:@""];

    NSError *error = nil;

    if ([context canEvaluatePolicy:LAPolicyDeviceOwnerAuthenticationWithBiometrics error:&error]) {
    	[context evaluatePolicy:LAPolicyDeviceOwnerAuthenticationWithBiometrics localizedReason:@"Validate your fingerprint to unlock all apps."
        reply:^(BOOL success, NSError *error) {
        	if (success) {
        		[[NSOperationQueue mainQueue] addOperationWithBlock:^{
	        		for (NSString *identifier in [lockedApps allKeys]) {
						[lockedApps setObject:[NSNumber numberWithBool:NO] forKey:identifier];
					}

					[defaults setObject:lockedApps forKey:@"lockedApps"];
					[defaults synchronize];
				}];
            }

            else {
            	[[NSOperationQueue mainQueue] addOperationWithBlock:^{
	            	showAlertWithTitleAndMessage(@"Error", @"Your device failed to authenticate using TouchID.");
			    }];
            }
        }];
    }

    else {
        showAlertWithTitleAndMessage(@"Error", @"Your device cannot authenticate using TouchID.");
    }
}

static void changePasscode() {
	[defaults setObject:@"reopenPreferences" forKey:@"appToUnlock"];

	[[NSOperationQueue mainQueue] addOperationWithBlock:^{
		homeButtonPress();

		PAPasscodeViewController *passcodeViewController;

		if (![defaults objectForKey:@"passcode"]) {
			passcodeViewController = [[PAPasscodeViewController alloc] initForAction:PasscodeActionSet];
		}

		else {
			passcodeViewController = [[PAPasscodeViewController alloc] initForAction:PasscodeActionChange];
			passcodeViewController.passcode = [defaults objectForKey:@"passcode"];
		}

		passcodeViewController.delegate = [[ThreeDApplockPasscodeDelegate alloc] init];
		passcodeViewController.view.tag = 1;
		
		[homeScreenVC presentViewController:[[UINavigationController alloc] initWithRootViewController:passcodeViewController] animated:YES completion:^{
			statusBar = MSHookIvar<UIStatusBar *>([UIApplication sharedApplication], "_statusBar");
			[statusBar performSelector:@selector(setForegroundColor:) withObject:[UIColor blackColor] afterDelay:0.1];
		}];
	}];
}

%ctor {
	loadPrefs();

	if (enabled) {
		%init;
	}

	CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL, (CFNotificationCallback)loadPrefs, CFSTR("com.tweaksbylogan.3dapplock/saved"), NULL, CFNotificationSuspensionBehaviorCoalesce);
	CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL, (CFNotificationCallback)respring, CFSTR("com.tweaksbylogan.3dapplock/respring"), NULL, CFNotificationSuspensionBehaviorCoalesce);
	CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL, (CFNotificationCallback)unlockAllApps, CFSTR("com.tweaksbylogan.3dapplock/unlockAllApps"), NULL, CFNotificationSuspensionBehaviorCoalesce);
	CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL, (CFNotificationCallback)changePasscode, CFSTR("com.tweaksbylogan.3dapplock/changePasscode"), NULL, CFNotificationSuspensionBehaviorCoalesce);
}