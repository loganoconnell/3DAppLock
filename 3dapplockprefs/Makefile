include $(THEOS)/makefiles/common.mk

BUNDLE_NAME = 3DAppLockPrefs
3DAppLockPrefs_FILES = TDLRootListController.m UILabel+AutomaticWriting/UILabel+AutomaticWriting.m
3DAppLockPrefs_INSTALL_PATH = /Library/PreferenceBundles
3DAppLockPrefs_LIBRARIES = MobileGestalt substrate
3DAppLockPrefs_FRAMEWORKS = Foundation UIKit CoreGraphics QuartzCore MessageUI LocalAuthentication
3DAppLockPrefs_PRIVATE_FRAMEWORKS = Preferences Twitter

include $(THEOS_MAKE_PATH)/bundle.mk

internal-stage::
	$(ECHO_NOTHING)mkdir -p $(THEOS_STAGING_DIR)/Library/PreferenceLoader/Preferences$(ECHO_END)
	$(ECHO_NOTHING)cp entry.plist $(THEOS_STAGING_DIR)/Library/PreferenceLoader/Preferences/3DAppLockPrefs.plist$(ECHO_END)
