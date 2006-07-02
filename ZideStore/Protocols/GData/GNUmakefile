# GNUstep makefile

-include ../../../config.make
include $(GNUSTEP_MAKEFILES)/common.make
include ../../Version
include ./Version

BUNDLE_NAME        = GData
BUNDLE_EXTENSION   = .zsp
BUNDLE_INSTALL_DIR = $(GNUSTEP_INSTALLATION_DIR)/Library/ZideStore-$(MAJOR_VERSION).$(MINOR_VERSION)

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
