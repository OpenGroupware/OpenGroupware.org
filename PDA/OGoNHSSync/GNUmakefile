# $Id$

GNUSTEP_INSTALLATION_DIR = $(GNUSTEP_USER_ROOT)

include $(GNUSTEP_SYSTEM_ROOT)/Makefiles/common.make
include ../Version
include ./Version

LIBRARY_NAME = libOGoNHS

libOGoNHS_SOVERSION=$(MAJOR_VERSION).$(MINOR_VERSION)

libOGoNHS_HEADER_FILES = \
	OGoNHSDeviceDataSource.h	\

libOGoNHS_OBJC_FILES = \
	OGoNHSDeviceDataSource.m	\

libOGoNHS_HEADER_FILES_DIR         = .
libOGoNHS_HEADER_FILES_INSTALL_DIR = /OGoNHS

libOGoNHS_INCLUDE_DIRS += -I../OGoPalm/ -I..

BUNDLE_NAME        = OpenGroupwareNHS
BUNDLE_EXTENSION   = .conduit
BUNDLE_INSTALL_DIR = $(GNUSTEP_USER_ROOT)/Library/OpenGroupware.org

OpenGroupwareNHS_OBJC_FILES = \
	OGoNHSConduit.m			\
	TestConduit.m			\

OpenGroupwareNHS_PRINCIPAL_CLASS = OpenGroupwareNHSConduitBundle

OpenGroupwareNHS_INCLUDE_DIRS += -I../OGoPalm/ -I..
OpenGroupwareNHS_LIB_DIRS     += -L../PPSync/$(GNUSTEP_OBJ_DIR)
OpenGroupwareNHS_LIB_DIRS     += -L../OGoPalm/$(GNUSTEP_OBJ_DIR)
OpenGroupwareNHS_LIB_DIRS     += -L./$(GNUSTEP_OBJ_DIR)

OpenGroupwareNHS_BUNDLE_LIBS += \
	-lLSFoundation	\
	-lGDLAccess	\
	-lFoundation	\
	-lPPSync	\
	-lEOControl	\
	-lOGoPalm	\
	-lNGExtensions	\
	-lOGoScheduler	\
	-lOGoRawDatabase	\
	-lOGoNHS	\

ADDITIONAL_OBJCCFLAGS += -Wall

-include GNUmakefile.preamble
include $(GNUSTEP_MAKEFILES)/library.make
include $(GNUSTEP_MAKEFILES)/bundle.make
-include GNUmakefile.postamble

after-all ::
	@(cd $(BUNDLE_NAME)$(BUNDLE_EXTENSION);\
	  ln -sf ../bundle-info.plist .)
