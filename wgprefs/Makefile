include $(THEOS)/makefiles/common.mk

ARCHS = arm64 arm64e

BUNDLE_NAME = wgprefs

wgprefs_FILES = WGPRootListController.m
wgprefs_INSTALL_PATH = /Library/PreferenceBundles
wgprefs_FRAMEWORKS = UIKit
wgprefs_PRIVATE_FRAMEWORKS = Preferences
wgprefs_CFLAGS = -fobjc-arc

include $(THEOS_MAKE_PATH)/bundle.mk

internal-stage::
	$(ECHO_NOTHING)mkdir -p $(THEOS_STAGING_DIR)/Library/PreferenceLoader/Preferences$(ECHO_END)
	$(ECHO_NOTHING)cp entry.plist $(THEOS_STAGING_DIR)/Library/PreferenceLoader/Preferences/wgprefs.plist$(ECHO_END)
