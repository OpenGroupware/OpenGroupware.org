# $Id$

include ../common.make
include ./Version

LIBRARY_NAME       = libOGoBase
BUNDLE_NAME        = OGoBase
BUNDLE_EXTENSION   = .ds

libOGoBase_SOVERSION=$(MAJOR_VERSION).$(MINOR_VERSION)

libOGoBase_HEADER_FILES = \
	SkyLogDataSource.h	\
	SkyLogDocument.h	\
	LSCommandContext+Doc.h	\

libOGoBase_OBJC_FILES = \
	SkyLogDataSource.m	\
	SkyLogDocument.m	\

libOGoBase_HEADER_FILES_DIR         = .
libOGoBase_HEADER_FILES_INSTALL_DIR = /OGoBase

libOGoBase_LIBRARIES_DEPEND_UPON += \
	-lOGoDocuments			\
	-lLSFoundation -lNGExtensions 	\
	-lEOControl

OGoBase_PRINCIPAL_CLASS = SkyBaseBundleManager

OGoBase_OBJC_FILES = 	\
	SkyBaseBundleManager.m \

OGoBase_LIB_DIRS    += -L./$(GNUSTEP_OBJ_DIR)
OGoBase_BUNDLE_LIBS += -lOGoBase

ADDITIONAL_CPP_FLAGS += -Wall

ADDITIONAL_INCLUDE_DIRS += -I..	-I../OGoDocuments/

ADDITIONAL_LIB_DIRS += -L../OGoDocuments/$(GNUSTEP_OBJ_DIR) \

ifeq ($(FOUNDATION_LIB),nx)
ADDITIONAL_LDFLAGS += -framework Foundation
endif

-include GNUmakefile.preamble
include $(GNUSTEP_MAKEFILES)/library.make
include $(GNUSTEP_MAKEFILES)/bundle.make
-include GNUmakefile.postamble

after-OGoBase-all ::
	@(cd $(BUNDLE_NAME)$(BUNDLE_EXTENSION);\
	  $(LN_S) -f ../bundle-info.plist .)
