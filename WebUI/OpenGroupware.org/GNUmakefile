# GNUstep Makefile

include $(GNUSTEP_MAKEFILES)/common.make
include ../Version
include ./Version

WEBUID_NAME = ogo-webui-$(MAJOR_VERSION)$(MINOR_VERSION)

TOOL_NAME = $(WEBUID_NAME)

$(WEBUID_NAME)_OBJC_FILES = \
	OpenGroupware.m			\
	OpenGroupware+CTI.m		\
	DirectAction.m			\
	WODirectAction+LoginAction.m	\
	SoOGoAuthenticator.m

-include GNUmakefile.preamble
include $(GNUSTEP_MAKEFILES)/tool.make
-include GNUmakefile.postamble
-include fhs.make
