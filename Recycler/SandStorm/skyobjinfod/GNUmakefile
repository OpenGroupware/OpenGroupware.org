# $Id$

include ../common.make

TOOL_NAME   = skyobjinfod
BUNDLE_NAME = SkyObjectInfo

SkyObjectInfo_PRINCIPAL_CLASS = SkyObjectInfoAction

SkyObjectInfo_RESOURCE_FILES += \
	Version				\
	INTERFACE.xml			\
	SkyObjectInfoActionMap.plist	\

SkyObjectInfo_OBJC_FILES = \
	SkyObjectInfoAction.m			\
	SkyObjectInfoAction+PrivateMethods.m	\

skyobjinfod_OBJC_FILES = \
	skyobjinfod.m

-include GNUmakefile.preamble
include ../xmlrpcd.make
include $(GNUSTEP_MAKEFILES)/tool.make
-include GNUmakefile.postamble
