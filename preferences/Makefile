include $(THEOS)/makefiles/common.mk

BUNDLE_NAME = SnooScreens
SnooScreens_FILES = Preferences.mm
SnooScreens_INSTALL_PATH = /Library/PreferenceBundles
SnooScreens_FRAMEWORKS = UIKit Social
SnooScreens_PRIVATE_FRAMEWORKS = Preferences

include $(THEOS_MAKE_PATH)/bundle.mk

internal-stage::
	$(ECHO_NOTHING)mkdir -p $(THEOS_STAGING_DIR)/Library/PreferenceLoader/Preferences$(ECHO_END)
	$(ECHO_NOTHING)cp entry.plist $(THEOS_STAGING_DIR)/Library/PreferenceLoader/Preferences/SnooScreens.plist$(ECHO_END)
