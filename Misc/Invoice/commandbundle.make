# $Id$

$(COMMAND_BUNDLE)_OBJC_FILES += $(COMMAND_BUNDLE)Commands.m

BUNDLE_NAME        = $(COMMAND_BUNDLE)
BUNDLE_EXTENSION   = .cmd
BUNDLE_INSTALL_DIR = $(GNUSTEP_USER_ROOT)/Library/OpenGroupware.org

$(COMMAND_BUNDLE)_RESOURCE_FILES  += commands.plist
$(COMMAND_BUNDLE)_PRINCIPAL_CLASS = $(COMMAND_BUNDLE)Commands

$(COMMAND_BUNDLE)_BUNDLE_LIBS += \
	-lLSFoundation	\
	-lGDLAccess	\
	-lNGStreams -lNGExtensions -lEOControl

$(COMMAND_BUNDLE)_LIB_DIRS += \
	-L../LSFoundation/$(GNUSTEP_OBJ_DIR)	\
	-L/usr/local/lib	\
	-L/usr/lib

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
