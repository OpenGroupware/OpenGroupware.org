# ZideStore makefile

-include ../config.make
include $(GNUSTEP_MAKEFILES)/common.make

# aggregate

SUBPROJECTS = \
	ZSBackend	\
	ZSFrontend	\
	SoObjects	\
	Main		\
	\
	PrefsUI		\

# some products do not yet compile with Cocoa Foundation
ifneq ($(FOUNDATION_LIB),apple)
SUBPROJECTS += Protocols
endif

-include ZLConnect.make

-include GNUmakefile.preamble
include $(GNUSTEP_MAKEFILES)/aggregate.make
-include GNUmakefile.postamble
