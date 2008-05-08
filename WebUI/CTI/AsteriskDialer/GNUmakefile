# $Id: GNUmakefile,v 1.1.1.1 2002/11/14 10:50:58 jan Exp $

include $(GNUSTEP_MAKEFILES)/common.make

BUNDLE_NAME        = AsteriskDialer
BUNDLE_EXTENSION   = .cti
BUNDLE_INSTALL_DIR = $(GNUSTEP_INSTALLATION_DIR)/Library/Bundles

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
