# GNUstep makefile

include ../../config.make
include ../common.make
include ./Version

LIBRARY_NAME     = libOGoRawDatabase
BUNDLE_NAME      = OGoRawDatabase
BUNDLE_EXTENSION = .ds

OGoRawDatabase_PCH_FILE = common.h
libOGoRawDatabase_PCH_FILE = common.h

libOGoRawDatabase_HEADER_FILES_DIR         = .
libOGoRawDatabase_HEADER_FILES_INSTALL_DIR = /OGoRawDatabase
FHS_HEADER_DIRS = OGoRawDatabase

libOGoRawDatabase_INTERFACE_VERSION=$(MAJOR_VERSION).$(MINOR_VERSION)
libOGoRawDatabase_INSTALL_DIR=$(OGO_SYSLIBDIR)
libOGoRawDatabase_VERSION=$(MAJOR_VERSION).$(MINOR_VERSION).$(SUBMINOR_VERSION)

libOGoRawDatabase_HEADER_FILES = 	\
	SkyDBDocument.h		\
	SkyDBDataSource.h	\
	SkyAdaptorDataSource.h	\

libOGoRawDatabase_OBJC_FILES = 	\
	SkyDBDocument.m		\
	SkyDBDataSource.m	\
	SkyDBDocumentType.m	\
	SkyAdaptorDataSource.m	\

OGoRawDatabase_OBJC_FILES = \
	OGoRawDatabaseModule.m

OGoRawDatabase_PRINCIPAL_CLASS = OGoRawDatabaseModule

ifeq ($(tests),yes)
TOOL_NAME = testdb
endif

testdb_OBJC_FILES = testdb.m

-include GNUmakefile.preamble
ifneq ($(FHS_INSTALL_ROOT),)
GNUSTEP_HEADERS=$(DESTDIR)$(FHS_INSTALL_ROOT)/include
endif
include $(GNUSTEP_MAKEFILES)/library.make
include $(GNUSTEP_MAKEFILES)/bundle.make

ifeq ($(tests),yes)
include $(GNUSTEP_MAKEFILES)/tool.make
endif

-include GNUmakefile.postamble
