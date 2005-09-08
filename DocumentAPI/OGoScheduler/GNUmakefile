# GNUstep makefile

-include ../../config.make
include ../common.make
include ./Version

LIBRARY_NAME       = libOGoScheduler
BUNDLE_NAME        = OGoScheduler
BUNDLE_EXTENSION   = .ds

# does not work yet, OGoScheduler_PCH_FILE = common.h
libOGoScheduler_PCH_FILE = common.h

# TODO: this should rather check the makefile version!
ifeq ($(FHS_INSTALL_ROOT),)
ifeq ($(FOUNDATION_LIB),fd)
RESOURCES_DIR=$(GNUSTEP_LOCAL_ROOT)/Libraries/Resources/OGoScheduler
else
RESOURCES_DIR=$(GNUSTEP_LOCAL_ROOT)/Library/Libraries/Resources/OGoScheduler
endif
else
RESOURCES_DIR=$(FHS_INSTALL_ROOT)/share/opengroupware.org-1.1
endif

libOGoScheduler_CPPFLAGS += \
  -DRESOURCES_DIR="$(RESOURCES_DIR)"

libOGoScheduler_SOVERSION=$(MAJOR_VERSION).$(MINOR_VERSION)
libOGoScheduler_VERSION=$(MAJOR_VERSION).$(MINOR_VERSION).$(SUBMINOR_VERSION)

libOGoScheduler_HEADER_FILES = \
	SkyAppointmentQualifier.h		\
	SkyAptDataSource.h			\
	SkyAptCompoundDataSource.h		\
	SkyHolidayCalculator.h			\
	SkySchedulerConflictDataSource.h	\
	SkyAppointmentDocument.h		\
	SkyAppointmentDataSource.h		\

libOGoScheduler_OBJC_FILES = \
	SkyAppointmentQualifier.m		\
	SkyAptDataSource.m			\
	SkyAptCompoundDataSource.m		\
	SkyHolidayCalculator.m			\
	SkySchedulerConflictDataSource.m	\
	SkyAppointmentDocument.m		\
	SkyAppointmentDataSource.m		\
	SkyAppointmentDocumentGlobalIDResolver.m\

libOGoScheduler_HEADER_FILES_DIR         = .
libOGoScheduler_HEADER_FILES_INSTALL_DIR = /OGoScheduler
FHS_HEADER_DIRS = OGoScheduler

libOGoScheduler_RESOURCES = \
	Holidays.plist

OGoScheduler_PRINCIPAL_CLASS = SkySchedulerBundleManager
OGoScheduler_OBJC_FILES      = SkySchedulerBundleManager.m

OGoScheduler_RESOURCE_FILES += Defaults.plist

-include GNUmakefile.preamble
include $(GNUSTEP_MAKEFILES)/library.make
include $(GNUSTEP_MAKEFILES)/bundle.make
-include GNUmakefile.postamble
-include ../fhslib.make
