# $Id$

$(COMMAND_BUNDLE)_OBJC_FILES += $(COMMAND_BUNDLE)Commands.m

BUNDLE_NAME        = $(COMMAND_BUNDLE)
BUNDLE_EXTENSION   = .cmd
BUNDLE_INSTALL_DIR = $(GNUSTEP_LOCAL_ROOT)/Library/OpenGroupware.org

$(COMMAND_BUNDLE)_RESOURCE_FILES  += commands.plist
$(COMMAND_BUNDLE)_PRINCIPAL_CLASS = $(COMMAND_BUNDLE)Commands

ifeq ($(GNUSTEP_TARGET_OS),mingw32)
$(COMMAND_BUNDLE)_BUNDLE_LIBS += \
	-lLSFoundation	\
	-lGDLAccess -lGDLExtensions	\
	-lNGStreams -lNGExtensions -lEOControl \
	-lFoundation -lobjc
else
$(COMMAND_BUNDLE)_BUNDLE_LIBS += \
	-lLSFoundation	\
	-lGDLAccess -lGDLExtensions	\
	-lNGStreams -lNGExtensions -lEOControl
endif

ifeq ($(FOUNDATION_LIB),nx)
$(COMMAND_BUNDLE)_BUNDLE_LIBS += -lFoundationExt
ADDITIONAL_LDFLAGS            += -framework Foundation
endif

ifeq ($(FOUNDATION_LIB),apple)
$(COMMAND_BUNDLE)_BUNDLE_LIBS += -lNGLdap -lNGMime -lDOM -lSaxObjC
ADDITIONAL_LDFLAGS            += -framework Foundation
endif

$(COMMAND_BUNDLE)_LIB_DIRS += -L../LSFoundation/$(GNUSTEP_OBJ_DIR)

# set compile flags and go

ADDITIONAL_INCLUDE_DIRS += \
	-I../.. -I.. -I../LSFoundation \
	-I/usr/local/sybase/include \
	-I/usr/local/include

ADDITIONAL_CPPFLAGS += -Wall

# System files

-include GNUmakefile.preamble
include $(GNUSTEP_MAKEFILES)/bundle.make
-include GNUmakefile.postamble

ifeq ($(GNUSTEP_TARGET_OS),mingw32)
after-all ::
	@(cd $(BUNDLE_NAME)$(BUNDLE_EXTENSION);\
	  cp ../bundle-info.plist .)
else
after-all ::
	@(cd $(BUNDLE_NAME)$(BUNDLE_EXTENSION);\
	  $(LN_S) -f ../bundle-info.plist .)
endif
