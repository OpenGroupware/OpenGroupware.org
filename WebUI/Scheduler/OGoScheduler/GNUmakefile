# $Id$

include ../common.make

WOBUNDLE_NAME = OGoScheduler

OGoScheduler_PRINCIPAL_CLASS = SkySchedulerModule

OGoScheduler_OBJC_FILES = \
	SkySchedulerModule.m		\
	SkySchedulerPage.m		\
	SkyAptResourceEditor.m		\
	WODirectAction+SchedulerViews.m	\
	SkySchedulerSelectPopUp.m	\
	SkyAptResourceViewer.m		\
	SkySchedulerSelectPanel.m	\
	SkySchedulerConflictPage.m	\
	SkyAptDeletePanel.m		\

OGoScheduler_COMPONENTS = \
	SkySchedulerPage.wo		\
	SkyAptResourceEditor.wo		\
	SkyAptResourceViewer.wo		\
	SkySchedulerSelectPanel.wo	\
	SkySchedulerConflictPage.wo	\

OGoScheduler_RESOURCE_FILES += \
	Defaults.plist Version	\
	\
	SkyAptDeletePanel.wox		\
	SkySchedulerSelectPopUp.wox	\

OGoScheduler_LANGUAGES      =  English German

-include GNUmakefile.preamble
include $(GNUSTEP_MAKEFILES)/wobundle.make
-include GNUmakefile.postamble
