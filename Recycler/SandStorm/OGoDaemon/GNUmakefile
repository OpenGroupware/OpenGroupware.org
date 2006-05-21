# GNUstep makefile

include ../common.make

LIBRARY_NAME = libOGoDaemon
TOOL_NAME    = skyrund

libOGoDaemon_SOVERSION=$(MAJOR_VERSION).$(MINOR_VERSION)
libOGoDaemon_HEADER_FILES_DIR         = .
libOGoDaemon_HEADER_FILES_INSTALL_DIR = /OGoDaemon

libOGoDaemon_HEADER_FILES = \
	SkyDaemon.h				\
	SDApplication.h				\
	WODirectAction+SkyDaemon.h		\
	SDXmlRpcAction.h			\
	SDXmlRpcFault.h				\
	SkyCacheResult.h			\
	SkyCacheManager.h			\

libOGoDaemon_OBJC_FILES = \
	SDApplication.m				\
	WODirectAction+SkyDaemon.m		\
	SDXmlRpcAction.m			\
	SDXmlRpcFault.m				\
	SkyCacheManager.m			\
	SkyCacheResult.m			\

skyrund_OBJC_FILES = skyrund.m

-include GNUmakefile.preamble
include $(GNUSTEP_MAKEFILES)/library.make
include $(GNUSTEP_MAKEFILES)/tool.make
-include GNUmakefile.postamble
