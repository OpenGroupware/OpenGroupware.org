# $Id: GNUmakefile 1 2004-08-20 11:17:52Z znek $

include $(GNUSTEP_MAKEFILES)/common.make
include ../Version
include ./Version

GNUSTEP_INSTALLATION_DIR = $(GNUSTEP_LOCAL_ROOT)

LIBRARY_NAME       = libOGoPalm
BUNDLE_NAME        = OGoPalmDS
BUNDLE_EXTENSION   = .ds
BUNDLE_INSTALL_DIR = $(GNUSTEP_INSTALLATION_DIR)/Library/OpenGroupware.org-1.0a/DataSources/

libOGoPalm_SOVERSION=$(MAJOR_VERSION).$(MINOR_VERSION)
libOGoPalm_VERSION=$(MAJOR_VERSION).$(MINOR_VERSION).$(SUBMINOR_VERSION)

libOGoPalm_HEADER_FILES = \
	SkyPalmCategoryDocument.h	\
	SkyPalmDocument.h		\
	SkyPalmAddressDocument.h	\
	SkyPalmDateDocument.h		\
	SkyPalmDateDocumentCopy.h	\
	SkyPalmJobDocument.h		\
	SkyPalmMemoDocument.h		\
	\
	SkyPalmDocumentDataSource.h	\
	SkyPalmEntryDataSource.h	\
	SkyPalmCategoryDataSource.h	\
	SkyPalmDateDataSource.h		\
	\
	SkyPalmConstants.h		\
	SkyPalmSyncMachine.h		\
	SkyPalmPreSync.h		\
	SkyPalmPostSync.h		\

libOGoPalm_OBJC_FILES = \
	SkyPalmCategoryDocument.m	\
	SkyPalmDocument.m		\
	SkyPalmAddressDocument.m	\
	SkyPalmAddressDocument+SkyrixSync.m	\
	SkyPalmDateDocument.m		\
	SkyPalmDateDocumentCopy.m	\
	SkyPalmJobDocument.m		\
	SkyPalmMemoDocument.m		\
	\
	SkyPalmDocumentDataSource.m	\
	SkyPalmEntryDataSource.m	\
	SkyPalmCategoryDataSource.m	\
	SkyPalmDateDataSource.m		\
	\
	SkyPalmSyncMachine.m		\
	SkyPalmPreSync.m		\
	SkyPalmPostSync.m		\
	NGMD5Generator.m		\

libOGoPalm_HEADER_FILES_DIR         = ./OGoPalm
libOGoPalm_HEADER_FILES_INSTALL_DIR = /OGoPalm
FHS_HEADER_DIRS = OGoPalm

OGoPalmDS_OBJC_FILES = SkyPalmBundleManager.m

-include GNUmakefile.preamble
include $(GNUSTEP_MAKEFILES)/library.make
include $(GNUSTEP_MAKEFILES)/bundle.make
-include GNUmakefile.postamble
-include ../../DocumentAPI/fhslib.make
