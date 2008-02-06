# $Id: GNUmakefile 1 2004-08-20 11:17:52Z znek $

include ../common.make

WOBUNDLE_NAME = OGoProjectInfo

OGoProjectInfo_PRINCIPAL_CLASS = SkyP4InfoModule

OGoProjectInfo_OBJC_FILES = SkyP4InfoModule.m SkyDockedProjects.m
OGoProjectInfo_COMPONENTS = SkyDockedProjects.wo

-include OGo.make

before-all :: $(OGoProjectInfo_DERIVED_RESOURCES)

clean ::
	rm -f $(OGoProjectInfo_DERIVED_RESOURCES)

-include GNUmakefile.preamble
include $(GNUSTEP_MAKEFILES)/wobundle.make
-include GNUmakefile.postamble
