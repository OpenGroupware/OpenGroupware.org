# $Id$

include ../common.make

TOOL_NAME   = skygreetingd
BUNDLE_NAME = SkyGreetingCard

SkyGreetingCard_PRINCIPAL_CLASS = SkyGreetingCardAction

FONT_TTFS = Arial.ttf

SkyGreetingCard_RESOURCE_FILES += \
	Version				\
	INTERFACE.xml			\
	SkyGreetingCardActionMap.plist	\
	Resources/Stamp.jpg 		\
	$(FONT_TTFS)

SkyGreetingCard_OBJC_FILES += \
	SkyGreetingCardAction.m		\
	GDImage.m			\

skygreetingd_OBJC_FILES += \
	skygreetingd.m

-include GNUmakefile.preamble
include ../xmlrpcd.make
include $(GNUSTEP_MAKEFILES)/tool.make
-include GNUmakefile.postamble
