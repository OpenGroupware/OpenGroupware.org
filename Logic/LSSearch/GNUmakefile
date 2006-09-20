# GNUstep makefile

-include ../../config.make
include ../common.make
include ./Version

GNUSTEP_INSTALLATION_DIR = $(GNUSTEP_LOCAL_ROOT)

BUNDLE_NAME        = LSSearch
BUNDLE_EXTENSION   = .cmd
LIBRARY_NAME	   = libLSSearch

LSSearch_PCH_FILE = common.h
libLSSearch_PCH_FILE = common.h

libLSSearch_SOVERSION=$(MAJOR_VERSION).$(MINOR_VERSION)
libLSSearch_VERSION=$(MAJOR_VERSION).$(MINOR_VERSION).$(SUBMINOR_VERSION)

LSSearch_RESOURCE_FILES  += commands.plist Version
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

LSSearch_RESOURCE_FILES += Defaults.plist

-include GNUmakefile.preamble
include $(GNUSTEP_MAKEFILES)/library.make
include $(GNUSTEP_MAKEFILES)/bundle.make
-include GNUmakefile.postamble
-include fhs.make
