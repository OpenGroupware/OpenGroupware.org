# $Id$

include $(GNUSTEP_MAKEFILES)/common.make

BUNDLE_NAME        = PrefsUI
BUNDLE_EXTENSION   = .zsp
BUNDLE_INSTALL_DIR = $(GNUSTEP_USER_ROOT)/Library/ZideStore-1.3

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

# make

-include GNUmakefile.preamble
include $(GNUSTEP_MAKEFILES)/bundle.make
-include GNUmakefile.postamble
-include ../fhsbundle.make
