#include "TDLRootListController.h"

@implementation TDLRootListController
- (NSArray *)specifiers {
	if (!_specifiers) {
		_specifiers = [[self loadSpecifiersFromPlistName:@"Root" target:self] retain];
	}

	return _specifiers;
}

- (void)viewDidLoad {
    [super viewDidLoad];

    self.navigationItem.rightBarButtonItems = [NSArray arrayWithObjects:[[UIBarButtonItem alloc] initWithImage:[UIImage imageWithContentsOfFile:@"/Library/PreferenceBundles/3DAppLockPrefs.bundle/twitter.png"] style:UIBarButtonItemStyleDone target:self action:@selector(share:)], nil];
}

- (void)viewDidAppear:(BOOL)arg1 {
    UIImageView *imageView = [[UIImageView alloc] initWithImage:[UIImage imageWithContentsOfFile:@"/Library/PreferenceBundles/3DAppLockPrefs.bundle/icon.png"]];
    imageView.frame = CGRectMake(0, 0, 29, 29);
    imageView.contentMode = UIViewContentModeScaleAspectFit;

    self.navigationItem.titleView = imageView;

    [super viewDidAppear:arg1];
}

- (void)unlockAllApps {
	CFNotificationCenterPostNotification(CFNotificationCenterGetDarwinNotifyCenter(), CFSTR("com.tweaksbylogan.3dapplock/unlockAllApps"), NULL, NULL, YES);
}

- (void)changePasscode {
	CFNotificationCenterPostNotification(CFNotificationCenterGetDarwinNotifyCenter(), CFSTR("com.tweaksbylogan.3dapplock/changePasscode"), NULL, NULL, YES);
}

- (void)respring {
	#pragma clang diagnostic push
	#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    [[[UIAlertView alloc] initWithTitle:@"Respring?" message:@"" delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"OK", nil] show];
    #pragma clang diagnostic pop
}

- (void)followLogan {
	NSString *user = @"logandev22";

	#pragma clang diagnostic push
	#pragma clang diagnostic ignored "-Wdeprecated-declarations"
	if ([[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"tweetbot:"]]) {
		[[UIApplication sharedApplication] openURL:[NSURL URLWithString:[@"tweetbot:///user_profile/" stringByAppendingString:user]]];
	}
	
	else if ([[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"twitterrific:"]]) {
		[[UIApplication sharedApplication] openURL:[NSURL URLWithString:[@"twitterrific:///profile?screen_name=" stringByAppendingString:user]]];
	}
	
	else if ([[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"tweetings:"]]) {
		[[UIApplication sharedApplication] openURL:[NSURL URLWithString:[@"tweetings:///user?screen_name=" stringByAppendingString:user]]];
	}
	
	else if ([[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"twitter:"]]) {
		[[UIApplication sharedApplication] openURL:[NSURL URLWithString:[@"twitter://user?screen_name=" stringByAppendingString:user]]];
	}
	
	else {
		[[UIApplication sharedApplication] openURL:[NSURL URLWithString:[@"https://mobile.twitter.com/" stringByAppendingString:user]]];
	}
	#pragma clang diagnostic pop
}

- (void)share:(id)sender {
    TWTweetComposeViewController *tweetComposeViewController = [[TWTweetComposeViewController alloc] init];
    [tweetComposeViewController setInitialText:@"#3DAppLock - Lock apps with 3D touch! Developed by @logandev22"];
    
    [self.navigationController presentViewController:tweetComposeViewController animated:YES completion:nil];
}

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
- (void)alertView:(UIAlertView *)arg1 clickedButtonAtIndex:(NSInteger)arg2 {
	if (arg2 == 1) {
        CFNotificationCenterPostNotification(CFNotificationCenterGetDarwinNotifyCenter(), CFSTR("com.tweaksbylogan.3dapplock/respring"), NULL, NULL, YES);
    }
}
#pragma clang diagnostic pop
@end

@interface ThreeDAppLockPrefsCustomCell : PSTableCell <PreferencesTableCustomView> {
	UILabel *firstLabel;
	UILabel *secondLabel;
	UILabel *thirdLabel;
}
@end

@implementation ThreeDAppLockPrefsCustomCell
- (id)initWithSpecifier:(id)arg1 {
	if (self = [super initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"cell"]) {
		firstLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, -15, [[UIScreen mainScreen] bounds].size.width, 60)];
		[firstLabel setNumberOfLines:1];
		firstLabel.font = [UIFont fontWithName:@"HelveticaNeue-UltraLight" size:36];
		[firstLabel setBackgroundColor:[UIColor clearColor]];
		firstLabel.textColor = [UIColor blackColor];
		firstLabel.textAlignment = NSTextAlignmentCenter;
		[firstLabel setText:@"3DAppLock" automaticWritingAnimationWithDuration:0.1 blinkingMode:UILabelAWBlinkingModeUntilFinish];
		[self addSubview:firstLabel];

		secondLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 20, [[UIScreen mainScreen] bounds].size.width, 60)];
		[secondLabel setNumberOfLines:1];
		secondLabel.font = [UIFont fontWithName:@"HelveticaNeue-Light" size:14];
		[secondLabel setText:@"Lock apps with 3D touch!"];
		[secondLabel setBackgroundColor:[UIColor clearColor]];
		secondLabel.textColor = [UIColor grayColor];
		secondLabel.textAlignment = NSTextAlignmentCenter;
		[self addSubview:secondLabel];

		thirdLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 40, [[UIScreen mainScreen] bounds].size.width, 60)];
		[thirdLabel setNumberOfLines:1];
		thirdLabel.font = [UIFont fontWithName:@"HelveticaNeue-Light" size:14];
		[thirdLabel setText:@"Created by Logan O’Connell"];
		[thirdLabel setBackgroundColor:[UIColor clearColor]];
		thirdLabel.textColor = [UIColor grayColor];
		thirdLabel.textAlignment = NSTextAlignmentCenter;
		[self addSubview:thirdLabel];
	}
	
	return self;
}
 
- (CGFloat)preferredHeightForWidth:(CGFloat)arg1 {
	return 90;
}
@end

@interface ThreeDAppLockSupportController : PSListController <MFMailComposeViewControllerDelegate> {
    MFMailComposeViewController *mailComposeViewController;
}
@end

@implementation ThreeDAppLockSupportController
- (id)specifiers {
	if ([MFMailComposeViewController canSendMail]) {
		mailComposeViewController = [[MFMailComposeViewController alloc] init];
	    mailComposeViewController.mailComposeDelegate = self;
	    [mailComposeViewController setToRecipients:[NSArray arrayWithObjects:@"Logan O'Connell <logan.developeremail@gmail.com>", nil]];
	    [mailComposeViewController setSubject:[NSString stringWithFormat:@"EasyClear Support"]];
	    [mailComposeViewController setMessageBody:[NSString stringWithFormat:@"\n\n\nDevice: %@ on iOS %@", (NSString *)MGCopyAnswer(CFSTR("ProductType")), (NSString *)MGCopyAnswer(CFSTR("ProductVersion"))] isHTML:NO];

	    [self.navigationController presentViewController:mailComposeViewController animated:YES completion:nil];
	}

	else {
		[self.navigationController popViewControllerAnimated:YES];

		#pragma clang diagnostic push
		#pragma clang diagnostic ignored "-Wdeprecated-declarations"
	    [[[UIAlertView alloc] initWithTitle:@"Error" message:@"You have no configured mail accounts." delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
	    #pragma clang diagnostic pop
	}

    return nil;
}

- (void)viewWillAppear:(BOOL)arg1 {
	[self.navigationItem setTitle:@""];

	[super viewWillAppear:arg1];
}

- (void)viewDidAppear:(BOOL)arg1 {
    UIImageView *imageView = [[UIImageView alloc] initWithImage:[UIImage imageWithContentsOfFile:@"/Library/PreferenceBundles/3DAppLockPrefs.bundle/support.png"]];
    imageView.frame = CGRectMake(0, 0, 29, 29);
    imageView.contentMode = UIViewContentModeScaleAspectFit;
    self.navigationItem.titleView = imageView;

    [super viewDidAppear:arg1];
}

- (void)mailComposeController:(MFMailComposeViewController *)arg1 didFinishWithResult:(id)arg2 error:(NSError *)arg3 {
    [arg1 dismissViewControllerAnimated:YES completion:nil];

    [self.navigationController popViewControllerAnimated:YES];
}
@end

@interface ThreeDAppLockCustomSwitchCell : PSSwitchTableCell
@end

@implementation ThreeDAppLockCustomSwitchCell
- (id)initWithStyle:(int)arg1 reuseIdentifier:(id)arg2 specifier:(id)arg3 {
   	if (self = [super initWithStyle:arg1 reuseIdentifier:arg2 specifier:arg3]) {
        [[self control] setOnTintColor:[UIColor blackColor]];
    }
    
    return self;
}
@end