# $Id$

include ../common.make

WOBUNDLE_NAME = OGoProjectInfo

OGoProjectInfo_PRINCIPAL_CLASS = SkyP4InfoModule

OGoProjectInfo_OBJC_FILES = SkyP4InfoModule.m SkyDockedProjects.m
OGoProjectInfo_COMPONENTS = SkyDockedProjects.wo

-include OGo.make
-include SKYRIX.make

before-all :: $(OGoProjectInfo_DERIVED_RESOURCES)

clean ::
	rm -f $(OGoProjectInfo_DERIVED_RESOURCES)

-include GNUmakefile.preamble
include $(GNUSTEP_MAKEFILES)/wobundle.make
-include GNUmakefile.postamble
