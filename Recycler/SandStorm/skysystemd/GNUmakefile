# $Id$

include ../common.make

BUNDLE_NAME = SkySystem
TOOL_NAME   = skysystemd

# Sources

skysystemd_OBJC_FILES = skysystemd.m

SkySystem_OBJC_FILES =	\
	SkySystemApplication.m	\
	SkySystemAction.m	\
        TaskComponent.m		\
        TaskMethod.m		\
        TaskMethodSignature.m	\
	TaskMethodInvocation.m	\

SkySystem_RESOURCE_FILES += Version

-include GNUmakefile.preamble
include ../xmlrpcd.make
include $(GNUSTEP_MAKEFILES)/tool.make
-include GNUmakefile.postamble
