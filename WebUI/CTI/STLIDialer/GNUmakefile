# GNUstep makefile

include ../common.make

BUNDLE_NAME        = STLIDialer
BUNDLE_EXTENSION   = .cti
BUNDLE_INSTALL_DIR = $(GNUSTEP_USER_ROOT)/Library/Bundles

STLIDialer_OBJC_FILES = \
	STLIDialer.m		\
	STLIConnection.m	\

STLIDialer_RESOURCE_FILES = \
	bundle-info.plist	\
	STLIEventKeys.plist	\

stli_OBJC_FILES = stli.m STLIConnection.m
stli_TOOL_LIBS  += -lNGStreams

-include GNUmakefile.preamble
include $(GNUSTEP_MAKEFILES)/bundle.make
-include GNUmakefile.postamble

after-all ::
	@(cd $(BUNDLE_NAME)$(BUNDLE_EXTENSION);\
	  cp ../bundle-info.plist .)
