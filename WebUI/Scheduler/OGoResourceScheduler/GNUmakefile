# $Id: GNUmakefile 1 2004-08-20 11:17:52Z znek $

include ../common.make

WOBUNDLE_NAME = OGoResourceScheduler

OGoResourceScheduler_PRINCIPAL_CLASS =  SkyResourceSchedulerModule

OGoResourceScheduler_OBJC_FILES = \
	SkyResourceSchedulerModule.m			\
	SkyResourceSchedulerPage.m			\
	SkySchedulerResourcePanel.m			\
	WODirectAction+ResourceSchedulerViews.m		\

OGoResourceScheduler_COMPONENTS = \
	SkyResourceSchedulerPage.wo	\
	SkySchedulerResourcePanel.wo	\

OGoResourceScheduler_RESOURCE_FILES += Defaults.plist Version

-include GNUmakefile.preamble
include $(GNUSTEP_MAKEFILES)/wobundle.make
-include GNUmakefile.postamble
-include ../../fhsbundle.make
