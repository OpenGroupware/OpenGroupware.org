# GNUstep makefile

-include ../../config.make
include $(GNUSTEP_MAKEFILES)/common.make
include ../Version
include ./Version

BUNDLE_NAME        = PrefsUI
BUNDLE_EXTENSION   = .zsp
BUNDLE_INSTALL_DIR = $(GNUSTEP_INSTALLATION_DIR)/Library/ZideStore-$(MAJOR_VERSION).$(MINOR_VERSION)

PrefsUI_PRINCIPAL_CLASS = PrefsUIProduct

PrefsUI_OBJC_FILES = \
	PrefsUIProduct.m	\
	SxFrame.m		\
	SxMissingLicensePage.m	\
	SxPage.m		\
	SxRootPage.m		\
	SxUserHomePage.m	\
	SxUserSettingsPage.m	\

PrefsUI_RESOURCE_FILES += \
	bundle-info.plist	\
	Version			\
	product.plist		\
	\
	SxFrame.wox		\
	SxMissingLicensePage.wox\
	SxRootPage.wox		\
	SxUserHomePage.wox	\
	SxUserSettingsPage.wox	\
	\
	English.lproj/*.gif 	\
	English.lproj/*.jpg 	\
	English.lproj/*.ico	\
	English.lproj/*.css	\

# make

-include GNUmakefile.preamble
include $(GNUSTEP_MAKEFILES)/bundle.make
-include GNUmakefile.postamble
-include ../fhsbundle.make
