# $Id$

$(COMMAND_BUNDLE)_OBJC_FILES += $(COMMAND_BUNDLE)Commands.m

SUBPROJECT_NAME  = sub$(COMMAND_BUNDLE)
sub$(COMMAND_BUNDLE)_OBJC_FILES = $($(COMMAND_BUNDLE)_OBJC_FILES)

BUNDLE_NAME        = $(COMMAND_BUNDLE)
BUNDLE_EXTENSION   = .cmd
BUNDLE_INSTALL_DIR = $(GNUSTEP_LOCAL_ROOT)/Library/OpenGroupware.org

$(COMMAND_BUNDLE)_RESOURCE_FILES  += commands.plist
$(COMMAND_BUNDLE)_PRINCIPAL_CLASS = $(COMMAND_BUNDLE)Commands

$(COMMAND_BUNDLE)_BUNDLE_LIBS += \
	-lLSFoundation	\
	-lGDLAccess	\
	-lNGStreams -lNGExtensions -lEOControl

ifeq ($(GNUSTEP_TARGET_OS),cygwin32)
$(COMMAND_BUNDLE)_BUNDLE_LIBS += -lFoundation -lobjc
endif
ifeq ($(GNUSTEP_TARGET_OS),mingw32)
$(COMMAND_BUNDLE)_BUNDLE_LIBS += -lFoundation -lobjc
endif

# set compile flags and go

ADDITIONAL_INCLUDE_DIRS += \
	-I../.. -I.. \
	-I/usr/local/sybase/include \
	-I/usr/local/include

# System files

include $(GNUSTEP_MAKEFILES)/bundle.make

ifeq ($(GNUSTEP_TARGET_OS),mingw32)

after-all ::
	@(cd $(BUNDLE_NAME)$(BUNDLE_EXTENSION);\
	  cp ../bundle-info.plist .)

else # mingw32

ifeq ($(GNUSTEP_TARGET_OS),cygwin32)

after-all ::
	@(cd $(BUNDLE_NAME)$(BUNDLE_EXTENSION);\
	  cp ../bundle-info.plist .)
else

after-all ::
	@(cd $(BUNDLE_NAME)$(BUNDLE_EXTENSION);\
	  ln -sf ../bundle-info.plist .)
endif
endif # mingw32
