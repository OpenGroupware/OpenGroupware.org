# $Id: GNUmakefile 1 2004-08-20 11:17:52Z znek $

include $(GNUSTEP_MAKEFILES)/common.make

BUNDLE_NAME        = WCAP
BUNDLE_EXTENSION   = .zsp
BUNDLE_INSTALL_DIR = $(GNUSTEP_USER_ROOT)/Library/ZideStore12

WCAP_PRINCIPAL_CLASS = WCAPProduct

WCAP_OBJC_FILES = \
	WCAPProduct.m		\
	SoWCAPRenderer.m	\
	SxUserFolder+WCAP.m	\
	SoApplication+WCAP.m	\
	WCAPEvent.m		\
	WCAPResultSet.m		\
	WCAPToDo.m		\

WCAP_BUNDLE_LIBS += -lNGObjWeb

WCAP_RESOURCE_FILES += \
	bundle-info.plist	\
	Version			\
	product.plist

ADDITIONAL_INCLUDE_DIRS += -I. -I../Frontend -I..

# make

-include GNUmakefile.preamble
include $(GNUSTEP_MAKEFILES)/bundle.make
-include GNUmakefile.postamble

after-all ::
	@(cd $(BUNDLE_NAME)$(BUNDLE_EXTENSION);\
	  cp ../bundle-info.plist .)
