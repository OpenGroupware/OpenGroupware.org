# $Id$

$(COMMAND_BUNDLE)_OBJC_FILES += $(COMMAND_BUNDLE)Commands.m

SUBPROJECT_NAME  = sub$(COMMAND_BUNDLE)
sub$(COMMAND_BUNDLE)_OBJC_FILES = $($(COMMAND_BUNDLE)_OBJC_FILES)

BUNDLE_NAME        = $(COMMAND_BUNDLE)
BUNDLE_EXTENSION   = .cmd
BUNDLE_INSTALL_DIR = $(GNUSTEP_INSTALLATION_DIR)/Library/OpenGroupware.org-1.0a/Commands/

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


# FHS support (this is a hack and is going to be done by gstep-make!)

ifneq ($(FHS_INSTALL_ROOT),)

FHS_LIB_DIR=$(FHS_INSTALL_ROOT)/lib/
FHS_CMD_DIR=$(FHS_LIB_DIR)opengroupware.org-1.0a/commands/

fhs-sax-dirs ::
	$(MKDIRS) $(FHS_CMD_DIR)

move-bundles-to-fhs :: fhs-sax-dirs
	@echo "moving bundles $(BUNDLE_INSTALL_DIR) to $(FHS_CMD_DIR) .."
	for i in $(BUNDLE_NAME); do \
          j="$(FHS_CMD_DIR)/$${i}$(BUNDLE_EXTENSION)"; \
	  if test -d $$j; then rm -r $$j; fi; \
	  mv "$(BUNDLE_INSTALL_DIR)/$${i}$(BUNDLE_EXTENSION)" $$j; \
	done

move-to-fhs :: move-bundles-to-fhs

after-install :: move-to-fhs

endif
