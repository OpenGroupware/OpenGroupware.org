# GNUstep makefile

include ../../config.make
include ../common.make
include ./Version

BUNDLE_NAME        = LSSearch
BUNDLE_EXTENSION   = .cmd
LIBRARY_NAME	   = libLSSearch

LSSearch_PCH_FILE = common.h
libLSSearch_PCH_FILE = common.h

libLSSearch_INTERFACE_VERSION=$(MAJOR_VERSION).$(MINOR_VERSION)
libLSSearch_INSTALL_DIR=$(OGO_SYSLIBDIR)
libLSSearch_VERSION=$(MAJOR_VERSION).$(MINOR_VERSION).$(SUBMINOR_VERSION)

LSSearch_RESOURCE_FILES  += commands.plist \
	Version \
	Defaults.plist

LSSearch_PRINCIPAL_CLASS =  LSSearchCommands

LSSearch_OBJC_FILES = LSSearchCommands.m

libLSSearch_OBJC_FILES = \
	LSGenericSearchRecord.m		\
	LSBaseSearch.m			\
	LSFullSearch.m			\
	LSExtendedSearch.m		\
	LSNewSearchRecordCommand.m	\
	LSExtendedSearchCommand.m	\
	LSFullSearchCommand.m		\
	OGoSQLGenerator.m		\
	LSQualifierSearchCommand.m	\

-include GNUmakefile.preamble
ifneq ($(FHS_INSTALL_ROOT),)
GNUSTEP_HEADERS=$(DESTDIR)$(FHS_INSTALL_ROOT)/include
endif
include $(GNUSTEP_MAKEFILES)/library.make
include $(GNUSTEP_MAKEFILES)/bundle.make
-include GNUmakefile.postamble
