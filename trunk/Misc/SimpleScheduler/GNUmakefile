# $Id$

include $(GNUSTEP_MAKEFILES)/common.make

WOAPP_NAME = SimpleScheduler

SimpleScheduler_OBJC_FILES = \
	SimpleScheduler.m	\
	Main.m			\
	Frame.m			\

SimpleScheduler_COMPONENTS = \
	Main.wo	\
	Frame.wo\

SimpleScheduler_TOOL_LIBS += \
	-lOGoScheduler	\
	-lEOControl	\
	-lGDLAccess	\
	-lLSFoundation	\
	-lWEExtensions	\
	-lWOExtensions	\

-include GNUmakefile.preamble
include $(GNUSTEP_MAKEFILES)/woapp.make
-include GNUmakefile.postamble
