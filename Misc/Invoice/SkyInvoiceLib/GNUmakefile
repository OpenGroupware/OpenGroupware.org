# $Id$

include $(GNUSTEP_MAKEFILES)/common.make

GNUSTEP_INSTALLATION_DIR = $(GNUSTEP_USER_ROOT)

LIBRARY_NAME       = libSkyInvoice
BUNDLE_NAME        = SkyInvoiceDS
BUNDLE_EXTENSION   = .ds
BUNDLE_INSTALL_DIR = $(GNUSTEP_USER_ROOT)/Library/OpenGroupware.org

libSkyInvoice_HEADER_FILES = \
	SkyInvoiceDataSource.h		\
	SkyInvoiceDocument.h		\

libSkyInvoice_OBJC_FILES = \
	SkyInvoiceDataSource.m		\
	SkyInvoiceDocument.m		\

libSkyInvoice_INCLUDE_DIRS              = -I..
libSkyInvoice_HEADER_FILES_DIR		= .
libSkyInvoice_HEADER_FILES_INSTALL_DIR	= /SkyInvoice

libSkyInvoice_LIBRARIES_DEPEND_UPON += \
	-lNGExtensions		\
	-lOGoDocuments		\

SkyInvoiceDS_OBJC_FILES = dummy.m
SkyInvoiceDS_LIB_DIRS    += -L./$(GNUSTEP_OBJ_DIR)
SkyInvoiceDS_BUNDLE_LIBS += -lSkyInvoice

ADDITIONAL_CPP_FLAGS    += -Wall
ADDITIONAL_INCLUDE_DIRS += -I..

-include GNUmakefile.preamble
include $(GNUSTEP_MAKEFILES)/library.make
include $(GNUSTEP_MAKEFILES)/bundle.make
-include GNUmakefile.postamble

after-SkyInvoiceDS-all ::
	@(cd $(BUNDLE_NAME)$(BUNDLE_EXTENSION);\
	  $(LN_S) -f ../bundle-info.plist .)
