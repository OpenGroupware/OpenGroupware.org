# $Id$

include ../common.make

LIBRARY_NAME       = libOGoRawDatabase
BUNDLE_NAME        = OGoRawDatabase
BUNDLE_EXTENSION   = .ds

libOGoRawDatabase_HEADER_FILES_DIR         = .
libOGoRawDatabase_HEADER_FILES_INSTALL_DIR = /OGoRawDatabase
libOGoRawDatabase_SOVERSION=$(MAJOR_VERSION).$(MINOR_VERSION)

libOGoRawDatabase_HEADER_FILES = 	\
	SkyDBDocument.h		\
	SkyDBDataSource.h	\
	SkyAdaptorDataSource.h	\

libOGoRawDatabase_OBJC_FILES = 	\
	SkyDBDocument.m		\
	SkyDBDataSource.m	\
	SkyDBDocumentType.m	\
	SkyDBDocument+JS.m	\
	SkyAdaptorDataSource.m	\

OGoRawDatabase_OBJC_FILES = \
	OGoRawDatabaseModule.m

OGoRawDatabase_PRINCIPAL_CLASS = OGoRawDatabaseModule

TOOL_NAME = testdb

testdb_OBJC_FILES = testdb.m

-include GNUmakefile.preamble
include $(GNUSTEP_MAKEFILES)/library.make
include $(GNUSTEP_MAKEFILES)/bundle.make

ifeq ($(tests),yes)
include $(GNUSTEP_MAKEFILES)/tool.make
endif

-include GNUmakefile.postamble
