# $Id: GNUmakefile 1 2004-08-20 11:17:52Z znek $

include $(GNUSTEP_MAKEFILES)/common.make
GNUSTEP_INSTALLATION_DIR = $(GNUSTEP_LOCAL_ROOT)
include ../Version
include ./Version

LIBRARY_NAME       = libPPSync
TOOL_NAME          = nhsd ppls
# PYEXTMODULE_NAME   = PPSyncInternal

libPPSync_SOVERSION=$(MAJOR_VERSION).$(MINOR_VERSION)

ppls_OBJC_FILES = \
	ppls.m			\
	NHSNameServiceDaemon.m	\

nhsd_OBJC_FILES = \
	nhsd.m			\
	NHSNameServiceDaemon.m	\

libPPSync_HEADER_FILES = \
	PPAddressDatabase.h	\
	PPClassDescription.h	\
	PPDataStore.h		\
	PPDatabase.h		\
	PPDatebookDatabase.h	\
	PPGlobalID.h		\
	PPMemoDatabase.h	\
	PPRecordDatabase.h	\
	PPResourceDatabase.h	\
	PPSyncContext.h		\
	PPSyncPort.h		\
	PPToDoDatabase.h	\
	PPTransaction.h		\
	PPPostSync.h		\

libPPSync_OBJC_FILES = \
	PPAddressDatabase.m	\
	PPAddressPacker.m	\
	PPClassDescription.m	\
	PPDataStore.m		\
	PPDatabase.m		\
	PPDatebookDatabase.m	\
	PPDatebookPacker.m	\
	PPGlobalID.m		\
	PPMemoDatabase.m	\
	PPMemoPacker.m		\
	PPRecordDatabase.m	\
	PPRecordFaultHandler.m	\
	PPResourceDatabase.m	\
	PPSyncContext.m		\
	PPSyncPort.m		\
	PPToDoDatabase.m	\
	PPToDoPacker.m		\
	PPTransaction.m		\
	PPPostSync.m		\

libPPSync_HEADER_FILES_DIR = .
libPPSync_HEADER_FILES_INSTALL_DIR = /PPSync

-include GNUmakefile.preamble
include $(GNUSTEP_MAKEFILES)/library.make
include $(GNUSTEP_MAKEFILES)/tool.make
-include GNUmakefile.postamble
-include fhs.make
