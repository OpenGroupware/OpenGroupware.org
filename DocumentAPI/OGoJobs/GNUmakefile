# $Id: GNUmakefile 1 2004-08-20 11:17:52Z znek $

include ../common.make
include ./Version

LIBRARY_NAME       = libOGoJobs
BUNDLE_NAME        = OGoJobs
BUNDLE_EXTENSION   = .ds

libOGoJobs_SOVERSION=$(MAJOR_VERSION).$(MINOR_VERSION)
libOGoJobs_VERSION=$(MAJOR_VERSION).$(MINOR_VERSION).$(SUBMINOR_VERSION)

libOGoJobs_HEADER_FILES = 				\
	SkyPersonJobDataSource.h			\
	SkyProjectJobDataSource.h			\
	SkyJobDocument.h				\
	SkyJobHistoryDataSource.h			\
	SkyJobHistoryDocument.h				\

libOGoJobs_OBJC_FILES = 				\
	SkyProjectJobDataSource.m			\
	SkyPersonJobDataSource.m			\
	SkyJobDocument.m				\
	SkyJobDocument+JS.m				\
	SkyJobHistoryDataSource.m			\
	SkyJobHistoryDocument.m				\
	SkyJobHistoryDocument+JS.m			\
	SkySchedulerJobDataSource.m			\

libOGoJobs_HEADER_FILES_DIR         = .
libOGoJobs_HEADER_FILES_INSTALL_DIR = /OGoJobs

OGoJobs_OBJC_FILES = \
	SkyJobsBundleManager.m 	\
	SkyJobGlobalIDResolver.m\

-include GNUmakefile.preamble
include $(GNUSTEP_MAKEFILES)/library.make
include $(GNUSTEP_MAKEFILES)/bundle.make
-include GNUmakefile.postamble

after-OGoJobs-all ::
	@(cd $(BUNDLE_NAME)$(BUNDLE_EXTENSION);\
	  $(LN_S) -f ../bundle-info.plist .)
