# global makefile for OGo

-include ./config.make
include $(GNUSTEP_MAKEFILES)/common.make

SUBPROJECTS += \
	Logic		\
	Database	\
	DocumentAPI	\
	WebUI		\
	Tools		\
	XmlRpcAPI	\
	ZideStore

ifneq ($(libpisock),no)
SUBPROJECTS += PDA
endif

-include GNUmakefile.preamble
include $(GNUSTEP_MAKEFILES)/aggregate.make
-include GNUmakefile.postamble
