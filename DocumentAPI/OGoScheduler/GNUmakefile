# GNUstep makefile

include ../../config.make
include ../common.make
include ./Version

LIBRARY_NAME       = libOGoScheduler
BUNDLE_NAME        = OGoScheduler
BUNDLE_EXTENSION   = .ds

# does not work yet, OGoScheduler_PCH_FILE = common.h
libOGoScheduler_PCH_FILE = common.h

RESOURCES_DIR=$(OGO_SHARED)

libOGoScheduler_CPPFLAGS += \
  -DRESOURCES_DIR="$(RESOURCES_DIR)"

libOGoScheduler_INTERFACE_VERSION=$(MAJOR_VERSION).$(MINOR_VERSION)
libOGoScheduler_INSTALL_DIR=$(OGO_SYSLIBDIR)
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

libOGoScheduler_RESOURCES = \
	Holidays.plist

OGoScheduler_PRINCIPAL_CLASS = SkySchedulerBundleManager
OGoScheduler_OBJC_FILES      = SkySchedulerBundleManager.m

OGoScheduler_RESOURCE_FILES += Defaults.plist

-include GNUmakefile.preamble
ifneq ($(FHS_INSTALL_ROOT),)
GNUSTEP_HEADERS=$(DESTDIR)$(FHS_INSTALL_ROOT)/include
endif
include $(GNUSTEP_MAKEFILES)/library.make
include $(GNUSTEP_MAKEFILES)/bundle.make
-include GNUmakefile.postamble
