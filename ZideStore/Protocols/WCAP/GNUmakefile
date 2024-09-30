# GNUstep makefile

-include ../../../config.make
include $(GNUSTEP_MAKEFILES)/common.make
include ../../Version
include ./Version

OGO_LIBDIR=${GNUSTEP_LIBRARY}
OGO_ZIDESTORE=${OGO_LIBDIR}/ZideStore-${MAJOR_VERSION}.${MINOR_VERSION}

BUNDLE_NAME        = WCAP
BUNDLE_EXTENSION   = .zsp
BUNDLE_INSTALL_DIR = $(OGO_ZIDESTORE)

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
-include ../../fhsbundle.make
