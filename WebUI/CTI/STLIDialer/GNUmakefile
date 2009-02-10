# GNUstep makefile

include ../common.make
include ../../../config.make

BUNDLE_NAME        = STLIDialer
BUNDLE_EXTENSION   = .cti
BUNDLE_INSTALL_DIR = $(GNUSTEP_BUNDLES)

STLIDialer_OBJC_FILES = \
	STLIDialer.m		\
	STLIConnection.m	\

STLIDialer_RESOURCE_FILES = \
	bundle-info.plist	\
	STLIEventKeys.plist	\

TOOL_NAME	= stli
stli_OBJC_FILES = stli.m STLIConnection.m
stli_TOOL_LIBS  += -lNGStreams
stli_INSTALL_DIR = $(OGO_TOOLS)

-include GNUmakefile.preamble
include $(GNUSTEP_MAKEFILES)/bundle.make
include $(GNUSTEP_MAKEFILES)/tool.make
-include GNUmakefile.postamble

after-all ::
	@(cd $(BUNDLE_NAME)$(BUNDLE_EXTENSION);\
	  cp ../bundle-info.plist .)
