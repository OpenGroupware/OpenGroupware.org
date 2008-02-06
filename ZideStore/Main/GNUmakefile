# ZideStore makefile

include ../../config.make
include $(GNUSTEP_MAKEFILES)/common.make
include ../Version
include ./Version

ZIDESTORE = ogo-zidestore-$(MAJOR_VERSION).$(MINOR_VERSION)
TOOL_NAME = $(ZIDESTORE)
$(ZIDESTORE)_INSTALL_DIR = $(OGO_ADMIN_TOOLS)

$(ZIDESTORE)_OBJC_FILES += \
	ZideStore.m		\
	SxAuthenticator.m	\

$(ZIDESTORE)_HEADER_FILES += \
	SxAuthenticator.h	\

-include GNUmakefile.preamble
include $(GNUSTEP_MAKEFILES)/tool.make
-include GNUmakefile.postamble
