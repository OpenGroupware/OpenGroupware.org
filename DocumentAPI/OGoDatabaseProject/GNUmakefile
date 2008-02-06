# GNUstep makefile

include ../../config.make
include ../common.make
include ./Version

LIBRARY_NAME       = libOGoDatabaseProject
BUNDLE_NAME        = OGoDatabaseProject
BUNDLE_EXTENSION   = .ds

libOGoDatabaseProject_PCH_FILE = common.h
OGoDatabaseProject_PCH_FILE = common.h

libOGoDatabaseProject_INTERFACE_VERSION=$(MAJOR_VERSION).$(MINOR_VERSION)
libOGoDatabaseProject_INSTALL_DIR=$(OGO_SYSLIBDIR)
libOGoDatabaseProject_VERSION=$(MAJOR_VERSION).$(MINOR_VERSION).$(SUBMINOR_VERSION)

libOGoDatabaseProject_HEADER_FILES = \
	SkyProjectDocument.h			\
	SkyProjectFileManager.h			\
	SkyProjectFolderDataSource.h		\
	SkyDocumentDataSource.h			\
	SkyProjectFileManagerCache.h		\
	SkyProjectDocumentDataSource.h		\
	SkyDocumentIdHandler.h			\
	SkyDocumentHistoryDataSource.h		\

libOGoDatabaseProject_OBJC_FILES = \
	SkyProjectDocument.m			\
	SkyProjectFolderDataSource.m		\
	SkyDocumentDataSource.m			\
	SkyDocumentHistoryDataSource.m		\
	SkyProjectFileManager+Documents.m       \
	SkyProjectFileManager+Extensions.m	\
	SkyProjectFileManager+Internals.m	\
	SkyProjectFileManager+Locking.m		\
	SkyProjectFileManager+Notifications.m	\
	SkyProjectFileManager+DeleteDocument.m	\
	SkyProjectFileManager+Qualifier.m	\
	SkyProjectFileManager+FileAttributes.m	\
	SkyProjectFileManager+ContentHandler.m	\
	SkyProjectFileManager.m			\
	SkyProjectFileManagerCache+Caching.m	\
	SkyProjectFileManagerCache+Internals.m	\
	SkyProjectFileManagerCache+Settings.m	\
	SkyProjectFileManagerCache.m		\
	SkyProjectDocument+DOM.m		\
	SkyProjectDocument+Log.m		\
	SkyProjectDocumentDataSource.m		\
	SkyDocumentIdHandler.m			\
	FMContext.m				\
	SkySimpleProjectFolderDataSource.m	\

libOGoDatabaseProject_HEADER_FILES_DIR         = .
libOGoDatabaseProject_HEADER_FILES_INSTALL_DIR = /OGoDatabaseProject
FHS_HEADER_DIRS = OGoDatabaseProject

# datasource/accesshandler bundle

OGoDatabaseProject_PRINCIPAL_CLASS = SkyDBProjectBundleManager

OGoDatabaseProject_OBJC_FILES += 	\
	SkyDBProjectBundleManager.m	\
	SkyDocumentAccessHandler.m	\

-include GNUmakefile.preamble
ifneq ($(FHS_INSTALL_ROOT),)
GNUSTEP_HEADERS=$(DESTDIR)$(FHS_INSTALL_ROOT)/include
endif
include $(GNUSTEP_MAKEFILES)/library.make
include $(GNUSTEP_MAKEFILES)/bundle.make
-include GNUmakefile.postamble
