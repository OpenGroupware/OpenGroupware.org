# GNUstep makefile

include $(GNUSTEP_MAKEFILES)/common.make

BUNDLE_NAME        = WCAP
BUNDLE_EXTENSION   = .zsp
BUNDLE_INSTALL_DIR = $(GNUSTEP_USER_ROOT)/Library/ZideStore-1.3

WCAP_PRINCIPAL_CLASS = WCAPProduct

WCAP_OBJC_FILES = \
	WCAPProduct.m		\
	SoWCAPRenderer.m	\
	SxUserFolder+WCAP.m	\
	SoApplication+WCAP.m	\
	WCAPEvent.m		\
	WCAPResultSet.m		\
	WCAPToDo.m		\

WCAP_RESOURCE_FILES += \
	bundle-info.plist	\
	Version			\
	product.plist

-include GNUmakefile.preamble
include $(GNUSTEP_MAKEFILES)/bundle.make
-include GNUmakefile.postamble
