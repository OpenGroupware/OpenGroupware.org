# GNUstep makefile

include ../common.make

WOBUNDLE_NAME = GroupsUI

GroupsUI_PRINCIPAL_CLASS = GroupsUIModule

GroupsUI_OBJC_FILES += \
	GroupsUIModule.m	\
	OGoGroupsPage.m		\

GroupsUI_RESOURCE_FILES += Defaults.plist Version

-include GNUmakefile.preamble
include $(GNUSTEP_MAKEFILES)/wobundle.make
-include GNUmakefile.postamble
-include ../fhsbundle.make
