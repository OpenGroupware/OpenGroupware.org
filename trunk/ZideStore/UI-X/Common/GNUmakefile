# GNUstep makefile

include $(GNUSTEP_MAKEFILES)/common.make
include ../../Version
include ./Version

BUNDLE_NAME        = CommonUI
BUNDLE_EXTENSION   = .zsp
BUNDLE_INSTALL_DIR = $(GNUSTEP_INSTALLATION_DIR)/Library/ZideStore-$(MAJOR_VERSION).$(MINOR_VERSION)

CommonUI_PRINCIPAL_CLASS = CommonUIProduct

CommonUI_OBJC_FILES = \
	CommonUIProduct.m	\
	OGoPageFrame.m		\
	OGoAppFrame.m		\
	OGoAppHeader.m		\
	OGoAppNavigation.m	\

CommonUI_RESOURCE_FILES += \
	Version			\
	product.plist		\
	OGoPageFrame.wox	\
	OGoAppFrame.wox		\
	OGoAppHeader.wox	\
	OGoAppNavigation.wox	\
	\
	zidestoreui.css		\
	calendar.css		\
	images/OGoLogo.gif	\

ZIDESTORE=../..

ADDITIONAL_INCLUDE_DIRS += \
	-I. \
	-I$(ZIDESTORE)/ZSFrontend -I$(ZIDESTORE)/ZSBackend -I$(ZIDESTORE)

# make

-include GNUmakefile.preamble
include $(GNUSTEP_MAKEFILES)/bundle.make
-include GNUmakefile.postamble
-include ../../fhsbundle.make

after-all ::
	@(cd $(BUNDLE_NAME)$(BUNDLE_EXTENSION);\
	  cp ../bundle-info.plist .)
