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

# compile PDA manually on OSX if you are sure that you have a working libpisock
ifneq ($(FOUNDATION_LIB),apple)
SUBPROJECTS += \
	PDA
endif

-include GNUmakefile.preamble
include $(GNUSTEP_MAKEFILES)/aggregate.make
-include GNUmakefile.postamble
