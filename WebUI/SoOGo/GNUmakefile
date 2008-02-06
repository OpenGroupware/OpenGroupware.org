# GNUstep makefile

include ../common.make

WOBUNDLE_NAME        = SoOGo
WOBUNDLE_EXTENSION   = .lso

SoOGo_PRINCIPAL_CLASS = SoOGoModule

SoOGo_OBJC_FILES += \
	SoOGoModule.m

SoOGo_RESOURCE_FILES += product.plist

-include GNUmakefile.preamble
include $(GNUSTEP_MAKEFILES)/wobundle.make
-include GNUmakefile.postamble
