# GNUstep makefile

include ../common.make

WOBUNDLE_NAME = OGoScheduler

OGoScheduler_PRINCIPAL_CLASS = SkySchedulerModule

OGoScheduler_OBJC_FILES = \
	SkySchedulerModule.m		\
	NSCalendarDate+OGoScheduler.m	\
	SkyAptDeletePanel.m		\
	SkyAptResourceEditor.m		\
	SkyAptResourceViewer.m		\
	SkySchedulerConflictPage.m	\
	SkySchedulerPage.m		\
	SkySchedulerSelectPanel.m	\
	SkySchedulerSelectPopUp.m	\
	WODirectAction+SchedulerViews.m	\

OGoScheduler_RESOURCE_FILES += Defaults.plist Version

-include GNUmakefile.preamble
include $(GNUSTEP_MAKEFILES)/wobundle.make
-include GNUmakefile.postamble
-include ../../fhsbundle.make
