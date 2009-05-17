# GNUstep makefile

include ../common.make

WOBUNDLE_NAME        = SoOGo
WOBUNDLE_EXTENSION   = .lso
WOBUNDLE_INSTALL_DIR = $(GNUSTEP_INSTALLATION_DIR)/Library/OpenGroupware.org-5.4/WebUI/

SoOGo_PRINCIPAL_CLASS = SoOGoModule

SoOGo_OBJC_FILES += \
	SoOGoModule.m

SoOGo_RESOURCE_FILES += product.plist

-include GNUmakefile.preamble
include $(GNUSTEP_MAKEFILES)/wobundle.make
-include GNUmakefile.postamble
-include ../fhsbundle.make
