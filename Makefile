ARCHS = arm64
TARGET = iphone::9.3:9.3
THEOS_BUILD_DIR = Packages
THEOS_DEVICE_IP = 192.168.1.77
include theos/makefiles/common.mk

TWEAK_NAME = 3DAppLock
3DAppLock_FILES = 3DAppLock.xm PAPasscodeViewController/PAPasscodeViewController.m UAObfuscatedString/UAObfuscatedString.m
PAPasscodeViewController/PAPasscodeViewController.m_CFLAGS = -fobjc-arc
3DAppLock_LIBRARIES = substrate
3DAppLock_FRAMEWORKS = Foundation UIKit AudioToolbox LocalAuthentication
3DAppLock_PRIVATE_FRAMEWORKS = SpringBoardServices FrontBoardServices
3DAppLock_CODESIGN_FLAGS = -Sentitlements.xml

include $(THEOS_MAKE_PATH)/tweak.mk

after-install::
	install.exec "killall -9 SpringBoard"
SUBPROJECTS += 3dapplockprefs
include $(THEOS_MAKE_PATH)/aggregate.mk
