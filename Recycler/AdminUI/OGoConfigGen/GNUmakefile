# $Id$

include $(GNUSTEP_MAKEFILES)/common.make
include ../Version
include ./Version

LIBRARY_NAME = libOGoConfigGen

libOGoConfigGen_OBJC_FILES = \
	OGoConfigDatabase.m		\
	OGoConfigFile.m			\
	OGoConfigDataSource.m		\
	OGoConfigEntryGlobalID.m	\
	\
	OGoCyrusConfigFile.m		\
	OGoPostfixConfigFile.m		\
	OGoQuotaTabConfigFile.m		\
	\
	OGoVirtualConfigFile.m		\
	OGoAccountsVirtualConfigFile.m	\
	OGoTeamsVirtualConfigFile.m	\
	\
	OGoConfigExporter.m		\
	OGoConfigEntryExporter.m	\
	OGoVirtualFileExporter.m	\
	OGoQuotaTabExporter.m		\
	\
	OGoConfigGenTransaction.m	\
	OGoConfigGenTarget.m		\

libOGoConfigGen_LIBRARIES_DEPEND_UPON += \
	-lLSFoundation	\
	-lNGExtensions

include $(GNUSTEP_MAKEFILES)/library.make
