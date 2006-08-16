# GNUstep makefile

-include ../../config.make
include ../common.make
include ./Version

LIBRARY_NAME       = libOGoBase
BUNDLE_NAME        = OGoBase
BUNDLE_EXTENSION   = .ds

libOGoBase_PCH_FILE = common.h
OGoBase_PCH_FILE = common.h
libOGoBase_SOVERSION=$(MAJOR_VERSION).$(MINOR_VERSION)
libOGoBase_VERSION=$(MAJOR_VERSION).$(MINOR_VERSION).$(SUBMINOR_VERSION)

libOGoBase_HEADER_FILES = \
	SkyLogDataSource.h	\
	SkyLogDocument.h	\
	LSCommandContext+Doc.h	\

libOGoBase_OBJC_FILES = \
	SkyLogDataSource.m	\
	SkyLogDocument.m	\

libOGoBase_HEADER_FILES_DIR         = .
libOGoBase_HEADER_FILES_INSTALL_DIR = /OGoBase
FHS_HEADER_DIRS = OGoBase

OGoBase_PRINCIPAL_CLASS = SkyBaseBundleManager

OGoBase_OBJC_FILES = 	\
	SkyBaseBundleManager.m \

-include GNUmakefile.preamble
include $(GNUSTEP_MAKEFILES)/library.make
include $(GNUSTEP_MAKEFILES)/bundle.make
-include GNUmakefile.postamble
-include ../fhslib.make
