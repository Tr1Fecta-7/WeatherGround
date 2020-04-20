include $(THEOS)/makefiles/common.mk

ARCHS = arm64 arm64e

TWEAK_NAME = WeatherGround

WeatherGround_FILES = $(wildcard *.xm)
WeatherGround_CFLAGS = -fobjc-arc -Wno-unguarded-availability-new
WeatherGround_FRAMEWORKS = CoreLocation
WeatherGround_LIBRARIES = mryipc
WeatherGround_PRIVATE_FRAMEWORKS = SpringBoardFoundation Weather WeatherUI
WeatherGround_LDFLAGS = $(THEOS)/sdks/iPhoneOS13.3.sdk/System/Library/PrivateFrameworks/WeatherUI.framework/WeatherUI.tbd

include $(THEOS_MAKE_PATH)/tweak.mk
SUBPROJECTS += wgprefs
include $(THEOS_MAKE_PATH)/aggregate.mk

after-install::
	install.exec "sbreload"
