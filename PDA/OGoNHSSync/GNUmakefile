# GNUstep makefile

GNUSTEP_INSTALLATION_DIR = $(GNUSTEP_USER_ROOT)

include $(GNUSTEP_SYSTEM_ROOT)/Makefiles/common.make
include ../Version
include ./Version

LIBRARY_NAME = libOGoNHS

libOGoNHS_SOVERSION=$(MAJOR_VERSION).$(MINOR_VERSION)
libOGoNHS_VERSION=$(MAJOR_VERSION).$(MINOR_VERSION).$(SUBMINOR_VERSION)

libOGoNHS_HEADER_FILES = OGoNHSDeviceDataSource.h
libOGoNHS_OBJC_FILES   = OGoNHSDeviceDataSource.m

libOGoNHS_HEADER_FILES_DIR         = .
libOGoNHS_HEADER_FILES_INSTALL_DIR = /OGoNHS
FHS_HEADER_DIRS = OGoNHS

BUNDLE_NAME        = OpenGroupwareNHS
BUNDLE_EXTENSION   = .conduit
BUNDLE_INSTALL_DIR = $(GNUSTEP_USER_ROOT)/Library/OpenGroupware.org-1.0a

OpenGroupwareNHS_OBJC_FILES = \
	OGoNHSConduit.m	\
	TestConduit.m

OpenGroupwareNHS_PRINCIPAL_CLASS = OpenGroupwareNHSConduitBundle

-include GNUmakefile.preamble
include $(GNUSTEP_MAKEFILES)/library.make
include $(GNUSTEP_MAKEFILES)/bundle.make
-include GNUmakefile.postamble
-include fhs.make
