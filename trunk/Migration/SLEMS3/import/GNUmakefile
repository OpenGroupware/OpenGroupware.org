#$Id$

include $(GNUSTEP_MAKEFILES)/common.make
include ../Version
include ./Version

GNUSTEP_INSTALLATION_DIR = $(GNUSTEP_LOCAL_ROOT)

LIBRARY_NAME  = libSkyImport

libSkyImport_INCLUDE_DIRS += \
	-I../NGLdap	\
	-I../GDLAccess	\

libSkyImport_HEADER_FILES = 		\
	SkyImport.h			\
	SkyAccountImport.h		\
	SkyGroupImport.h		\
					\
	SkyTransactionHandler.h		\
					\
	SkyUidHandler.h			\
	SkyGroupUidHandler.h		\
	SkyAccountUidHandler.h		\
	SkyResourceImport.h		\
	SkyResourceUidHandler.h		\
	SkyPersonImport.h		\
	SkyPersonUidHandler.h		\
	SkyPrivatePersonImport.h	\
	SkyAppImport.h			\
	SkyAppUidHandler.h		\
	SkyJobImport.h			\
	SkyJobUidHandler.h		\

libSkyImport_OBJC_FILES = 		\
	SkyImport.m			\
	SkyAccountImport.m		\
	SkyGroupImport.m		\
					\
	SkyTransactionHandler.m		\
					\
	SkyUidHandler.m			\
	SkyGroupUidHandler.m		\
	SkyAccountUidHandler.m		\
	SkyResourceImport.m		\
	SkyResourceUidHandler.m		\
	SkyPersonImport.m		\
	SkyPersonUidHandler.m		\
	SkyPrivatePersonImport.m	\
	SkyAppImport.m			\
	SkyAppUidHandler.m		\
	SkyJobImport.m			\
	SkyJobUidHandler.m		\

TOOL_NAME = skyimport

skyimport_OBJC_FILES  += skyimportmain.m $(libSkyImport_OBJC_FILES)

skyimport_LIB_DIRS  += 
skyimport_TOOL_LIBS += -lNGLdap	-lGDLAccess -lLSFoundation

-include GNUmakefile.preamble
#include $(GNUSTEP_SYSTEM_ROOT)/Makefiles/library.make
include $(GNUSTEP_SYSTEM_ROOT)/Makefiles/tool.make
-include GNUmakefile.postamble
