# $Id: GNUmakefile 1 2004-08-20 11:17:52Z znek $

include ../common.make
include ./Version

LIBRARY_NAME     = libOGoFileSystemProject
BUNDLE_NAME      = OGoFileSystemProject
BUNDLE_EXTENSION = .ds

libOGoFileSystemProject_SOVERSION=$(MAJOR_VERSION).$(MINOR_VERSION)
libOGoFileSystemProject_VERSION=$(MAJOR_VERSION).$(MINOR_VERSION).$(SUBMINOR_VERSION)

libOGoFileSystemProject_HEADER_FILES = 	\
	SkyFSFileManager.h		\
	SkyFSDataSource.h		\
	SkyFSFolderDataSource.h		\
	SkyFSDocument.h			\
	SkyFSGlobalID.h			\

libOGoFileSystemProject_OBJC_FILES =	\
	SkyFSFileManager.m		\
	SkyFSFileManager+Internals.m	\
	SkyFSDataSource.m		\
	SkyFSFolderDataSource.m		\
	SkyFSDocument.m			\
	SkyFSDocument+DOM.m		\
	SkyFSGlobalID.m			\
	SkyFSException.m		\

libOGoFileSystemProject_HEADER_FILES_DIR         = .
libOGoFileSystemProject_HEADER_FILES_INSTALL_DIR = /OGoFileSystemProject
FHS_HEADER_DIRS = OGoFileSystemProject

OGoFileSystemProject_PRINCIPAL_CLASS = SkyFSProjectModule

OGoFileSystemProject_OBJC_FILES += \
	SkyFSProjectModule.m	\

OGoFileSystemProject_BUNDLE_LIBS  += -lLSFoundation -lOGoFileSystemProject

ADDITIONAL_BUNDLE_LIBS += -lOGoFileSystemProject

-include GNUmakefile.preamble
include $(GNUSTEP_MAKEFILES)/library.make
include $(GNUSTEP_MAKEFILES)/bundle.make
-include GNUmakefile.postamble
-include ../fhslib.make
