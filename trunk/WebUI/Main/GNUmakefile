# GNUstep Makefile

-include ../../config.make
include $(GNUSTEP_MAKEFILES)/common.make
include ../Version
include ./Version

WEBUID_NAME = ogo-webui-1.0a

TOOL_NAME = $(WEBUID_NAME)

$(WEBUID_NAME)_OBJC_FILES = \
	main.m				\
	OpenGroupware.m			\
	OpenGroupware+CTI.m		\
	DirectAction.m			\
	WODirectAction+LoginAction.m	\
	SoOGoAuthenticator.m		\
	OGoWebBundleLoader.m		\

-include GNUmakefile.preamble
include $(GNUSTEP_MAKEFILES)/tool.make
-include GNUmakefile.postamble
-include fhs.make
