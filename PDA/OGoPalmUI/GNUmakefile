# GNUstep Makefile

include $(GNUSTEP_MAKEFILES)/common.make
include ../Version
include ./Version

LIBRARY_NAME = libOGoPalmUI

libOGoPalmUI_SOVERSION=$(MAJOR_VERSION).$(MINOR_VERSION)
libOGoPalmUI_VERSION=$(MAJOR_VERSION).$(MINOR_VERSION).$(SUBMINOR_VERSION)

libOGoPalmUI_HEADER_FILES = \
	SkyPalmDataSourceViewer.h	\
	SkyPalmEntryList.h		\
	SkyPalmEntryViewer.h		\
	SkyPalmEntryEditor.h		\
	SkyPalmDataSourceViewerState.h	\
	SkyPalmEntryListState.h		\
	SkyPalmAssignEntry.h		\

libOGoPalmUI_OBJC_FILES = \
	SkyPalmDataSourceViewer.m	\
	SkyPalmDataSourceViewerState.m	\
	SkyPalmEntryList.m		\
	SkyPalmEntryViewer.m		\
	SkyPalmEntryEditor.m		\
	SkyPalmEntryListState.m		\
	SkyPalmAssignEntry.m		\


libOGoPalmUI_HEADER_FILES_DIR         = .
libOGoPalmUI_HEADER_FILES_INSTALL_DIR = /OGoPalmUI
FHS_HEADER_DIRS = OGoPalmUI


-include GNUmakefile.preamble
include $(GNUSTEP_MAKEFILES)/library.make
-include GNUmakefile.postamble
-include ../../DocumentAPI/fhslib.make
