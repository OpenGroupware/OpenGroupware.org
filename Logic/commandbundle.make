# CommandBundle Makefile

$(COMMAND_BUNDLE)_OBJC_FILES += $(COMMAND_BUNDLE)Commands.m

BUNDLE_NAME        = $(COMMAND_BUNDLE)
BUNDLE_EXTENSION   = .cmd
#hh: 2024-09-04
#BUNDLE_INSTALL_DIR = $(GNUSTEP_INSTALLATION_DIR)/Library/OpenGroupware.org-5.5/Commands/
BUNDLE_INSTALL_DIR = $(OGO_COMMANDS)

$(COMMAND_BUNDLE)_RESOURCE_FILES  += commands.plist
$(COMMAND_BUNDLE)_PRINCIPAL_CLASS = $(COMMAND_BUNDLE)Commands

$(COMMAND_BUNDLE)_BUNDLE_LIBS += \
	-lLSFoundation	\
	-lGDLAccess	\
	-lNGMime	\
	-lNGStreams -lNGExtensions -lEOControl \
	-lXmlRpc -lDOM -lSaxObjC

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
	-I../.. -I.. -I../LSFoundation

SYSTEM_LIB_DIR += -I/usr/local/include

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


# FHS support (this is a hack and is going to be done by gstep-make!)

ifneq ($(FHS_INSTALL_ROOT),)

FHS_LIB_DIR=$(CONFIGURE_FHS_INSTALL_LIBDIR)
FHS_CMD_DIR=$(FHS_LIB_DIR)opengroupware.org-5.5/commands/

fhs-command-dirs ::
	$(MKDIRS) $(FHS_CMD_DIR)

move-bundles-to-fhs :: fhs-command-dirs
	@echo "moving bundles $(BUNDLE_INSTALL_DIR) to $(FHS_CMD_DIR) .."
	for i in $(BUNDLE_NAME); do \
          j="$(FHS_CMD_DIR)/$${i}$(BUNDLE_EXTENSION)"; \
	  if test -d $$j; then rm -r $$j; fi; \
	  mv "$(BUNDLE_INSTALL_DIR)/$${i}$(BUNDLE_EXTENSION)" $$j; \
	done

move-to-fhs :: move-bundles-to-fhs

after-install :: move-to-fhs

endif

SYSTEM_LIB_DIR += -L/usr/local/lib -L/usr/lib
