# $Id$

include $(GNUSTEP_MAKEFILES)/common.make

BUNDLE_NAME        = CommonUI
BUNDLE_EXTENSION   = .zsp
BUNDLE_INSTALL_DIR = $(GNUSTEP_USER_ROOT)/Library/ZideStore12

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
	-I$(ZIDESTORE)/Frontend -I$(ZIDESTORE)/Backend -I$(ZIDESTORE)

# make

-include GNUmakefile.preamble
include $(GNUSTEP_MAKEFILES)/bundle.make
-include GNUmakefile.postamble

after-all ::
	@(cd $(BUNDLE_NAME)$(BUNDLE_EXTENSION);\
	  cp ../bundle-info.plist .)
