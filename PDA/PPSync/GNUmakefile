# $Id$

include $(GNUSTEP_MAKEFILES)/common.make
GNUSTEP_INSTALLATION_DIR = $(GNUSTEP_LOCAL_ROOT)
include ../Version
include ./Version

LIBRARY_NAME       = libPPSync
TOOL_NAME          = nhsd ppls
# PYEXTMODULE_NAME   = PPSyncInternal

libPPSync_SOVERSION=$(MAJOR_VERSION).$(MINOR_VERSION)

# -------------------- ppls --------------------

ppls_OBJC_FILES = \
	ppls.m			\
	NHSNameServiceDaemon.m	\

ppls_INCLUDE_DIRS += -I../libpisock -I.. -I../NGStreams
ppls_TOOL_LIBS    += \
	-lNGStreams -lNGExtensions -lGDLAccess \
	-lPPSync -lpisock

ppls_LIB_DIRS += \
	-L$(GNUSTEP_OBJ_DIR)			\

# -------------------- nhsd --------------------

nhsd_OBJC_FILES = \
	nhsd.m			\
	NHSNameServiceDaemon.m	\

nhsd_INCLUDE_DIRS += -I../libpisock -I.. -I../NGStreams
nhsd_TOOL_LIBS    += \
	-lNGStreams -lNGExtensions -lGDLAccess  \
	-lPPSync -lpisock			\

nhsd_LIB_DIRS += \
	-L$(GNUSTEP_OBJ_DIR)			\

# -------------------- libPPSync --------------------

libPPSync_LIBRARIES_DEPEND_UPON += \
	-lEOControl	\
	-lpisock	\
	-lFoundation	\

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

libPPSync_INCLUDE_DIRS += -I.. -I../libpisock

libPPSync_HEADER_FILES_DIR = .
libPPSync_HEADER_FILES_INSTALL_DIR = /PPSync

ADDITIONAL_CPPFLAGS += -Wall

-include GNUmakefile.preamble
include $(GNUSTEP_MAKEFILES)/library.make
include $(GNUSTEP_MAKEFILES)/tool.make

-include GNUmakefile.postamble
