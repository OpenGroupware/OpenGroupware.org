# GNUstep makefile

-include ../../config.make
include $(GNUSTEP_MAKEFILES)/common.make
GNUSTEP_INSTALLATION_DIR = $(GNUSTEP_LOCAL_ROOT)
include ../Version
include ./Version

OGO_NHSD_NAME = ogo-nhsd-1.1
OGO_PPLS_NAME = ogo-ppls-1.1
FHS_DAEMONS   = $(OGO_NHSD_NAME)
FHS_TOOLS     = $(OGO_PPLS_NAME)

LIBRARY_NAME = libPPSync
TOOL_NAME    = $(OGO_NHSD_NAME) $(OGO_PPLS_NAME)

libPPSync_PCH_FILE = common.h
libPPSync_SOVERSION=$(MAJOR_VERSION).$(MINOR_VERSION)
libPPSync_VERSION=$(MAJOR_VERSION).$(MINOR_VERSION).$(SUBMINOR_VERSION)

# tools

$(OGO_PPLS_NAME)_OBJC_FILES += ppls.m NHSNameServiceDaemon.m
$(OGO_NHSD_NAME)_OBJC_FILES += nhsd.m NHSNameServiceDaemon.m

# library

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
