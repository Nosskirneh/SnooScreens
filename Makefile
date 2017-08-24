include $(THEOS)/makefiles/common.mk

TWEAK_NAME = SnooScreens
SnooScreens_FILES = SnooScreens.xm
SnooScreens_FRAMEWORKS = UIKit CoreGraphics
SnooScreens_PRIVATE_FRAMEWORKS = PhotoLibrary SpringBoardFoundation
SnooScreens_LDFLAGS = -lactivator

include $(THEOS_MAKE_PATH)/tweak.mk

after-stage::
	$(ECHO_NOTHING)find $(FW_STAGING_DIR) -iname '*.plist' -or -iname '*.strings' -exec plutil -convert binary1 {} \;$(ECHO_END)
	$(ECHO_NOTHING)find $(FW_STAGING_DIR) -iname '*.png' -exec pincrush -i {} \;$(ECHO_END)

after-install::
	install.exec "killall SpringBoard"

SUBPROJECTS += preferences
include $(THEOS_MAKE_PATH)/aggregate.mk
