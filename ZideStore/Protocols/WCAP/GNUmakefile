# GNUstep makefile

include ../../../config.make
include $(GNUSTEP_MAKEFILES)/common.make
include ../../Version
include ./Version

BUNDLE_NAME        = WCAP
BUNDLE_EXTENSION   = .zsp
BUNDLE_INSTALL_DIR = $(ZIDESTORE_WEBUIDIR)

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
