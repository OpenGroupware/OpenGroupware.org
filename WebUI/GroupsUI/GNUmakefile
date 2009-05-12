# GNUstep makefile

include ../common.make

WOBUNDLE_NAME        = GroupsUI
WOBUNDLE_EXTENSION   = .lso
WOBUNDLE_INSTALL_DIR = \
  $(GNUSTEP_INSTALLATION_DIR)/Library/OpenGroupware.org-1.2/WebUI/

GroupsUI_PRINCIPAL_CLASS = GroupsUIModule

GroupsUI_OBJC_FILES += \
	GroupsUIModule.m	\
	OGoGroupsPage.m		\

GroupsUI_RESOURCE_FILES += Defaults.plist Version

-include GNUmakefile.preamble
include $(GNUSTEP_MAKEFILES)/wobundle.make
-include GNUmakefile.postamble
-include ../fhsbundle.make
