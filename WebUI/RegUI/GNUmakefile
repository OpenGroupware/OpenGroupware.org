# GNUstep makefile

include ../common.make

WOBUNDLE_NAME        = RegUI
WOBUNDLE_EXTENSION   = .lso
WOBUNDLE_INSTALL_DIR = \
  $(GNUSTEP_INSTALLATION_DIR)/Library/OpenGroupware.org-1.1/WebUI/

RegUI_PRINCIPAL_CLASS = RegUIModule

RegUI_OBJC_FILES += \
	RegUIModule.m	\
	OGoRegPage.m	\

RegUI_RESOURCE_FILES += Defaults.plist Version

-include GNUmakefile.preamble
include $(GNUSTEP_MAKEFILES)/wobundle.make
-include GNUmakefile.postamble
-include ../fhsbundle.make
