#$Id$

include $(GNUSTEP_MAKEFILES)/common.make
include ../Version
include ./Version

GNUSTEP_INSTALLATION_DIR = $(GNUSTEP_LOCAL_ROOT)

LIBRARY_NAME  = libSkyExport

libSkyExport_INCLUDE_DIRS += \
	-INGLdap	\
	-IGDLAccess	\

libSkyExport_HEADER_FILES = 	\
	SkyExporter.h			\
	SkyLDAPExporter.h		\
	SkyAccountExporter.h		\
	SkyGroupExporter.h		\
	SkyResourceGroupExporter.h	\
	SkyResourceExporter.h		\
	SkyPersonExporter.h 		\
	SkyPublicPersonExporter.h 	\
	SkyPrivatePersonExporter.h 	\
	SkyDBExporter.h			\
	SkyAppExporter.h		\
	SkyJobExporter.h		\

libSkyExport_OBJC_FILES = 	\
	SkyExporter.m			\
	SkyLDAPExporter.m		\
	SkyAccountExporter.m		\
	SkyGroupExporter.m		\
	SkyResourceGroupExporter.m	\
	SkyResourceExporter.m		\
	SkyPersonExporter.m 		\
	SkyPublicPersonExporter.m 	\
	SkyPrivatePersonExporter.m 	\
	SkyDBExporter.m			\
	SkyAppExporter.m		\
	SkyJobExporter.m		\

TOOL_NAME = skyexport

skyexport_OBJC_FILES  += skyexport.m $(libSkyExport_OBJC_FILES)

skyexport_LIB_DIRS  +=
skyexport_TOOL_LIBS += -lNGLdap -lGDLAccess

-include GNUmakefile.preamble
#include $(GNUSTEP_SYSTEM_ROOT)/Makefiles/library.make
include $(GNUSTEP_SYSTEM_ROOT)/Makefiles/tool.make
-include GNUmakefile.postamble
