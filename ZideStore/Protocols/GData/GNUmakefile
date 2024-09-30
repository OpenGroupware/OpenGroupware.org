# GNUstep makefile

-include ../../../config.make
include $(GNUSTEP_MAKEFILES)/common.make
include ../../Version
include ./Version

OGO_LIBDIR=${GNUSTEP_LIBRARY}
OGO_ZIDESTORE=${OGO_LIBDIR}/ZideStore-${MAJOR_VERSION}.${MINOR_VERSION}

BUNDLE_NAME        = GData
BUNDLE_EXTENSION   = .zsp
BUNDLE_INSTALL_DIR = $(OGO_ZIDESTORE)

GData_PRINCIPAL_CLASS = GDataProduct

GData_OBJC_FILES = \
	GDataProduct.m		\
	\
	GDataAccounts.m		\
	GCalEntryPoint.m	\
	GCalCalendar.m		\
	GCalEvent.m		\
	GCalComments.m		\
	GCalComment.m		\

GData_RESOURCE_FILES += \
	bundle-info.plist	\
	Version			\
	product.plist

-include GNUmakefile.preamble
include $(GNUSTEP_MAKEFILES)/bundle.make
-include GNUmakefile.postamble
-include ../../fhsbundle.make
