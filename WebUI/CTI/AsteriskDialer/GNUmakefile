# GNUstep makefile

include ../common.make

BUNDLE_NAME        = AsteriskDialer
BUNDLE_EXTENSION   = .cti
BUNDLE_INSTALL_DIR = $(GNUSTEP_BUNDLES)

AsteriskDialer_OBJC_FILES = \
	AsteriskDialer.m	\
	AsteriskConnection.m	\

AsteriskDialer_RESOURCE_FILES = \
	bundle-info.plist	\

TOOL_NAME		= ogoasterisk
ogoasterisk_OBJC_FILES = ogoasterisk.m AsteriskConnection.m
ogoasterisk_TOOL_LIBS  += -lNGStreams

# OS dependend stuff
ifeq ($(findstring openbsd, $(GNUSTEP_TARGET_OS)), openbsd)
ogoasterisk_TOOL_LIBS += -liconv
endif

-include GNUmakefile.preamble
include $(GNUSTEP_MAKEFILES)/bundle.make
include $(GNUSTEP_MAKEFILES)/tool.make
-include GNUmakefile.postamble

after-all ::
	@(cd $(BUNDLE_NAME)$(BUNDLE_EXTENSION);\
	  cp ../bundle-info.plist .)
