# GNUstep makefile

include ../common.make

WOBUNDLE_NAME = LSWScheduler

LSWScheduler_PRINCIPAL_CLASS = LSWSchedulerModule

LSWScheduler_PCH_FILE = common.h

LSWScheduler_OBJC_FILES = 			\
	LSWSchedulerModule.m			\
	LSWSchedulerDateTitle.m			\
	LSWAppointmentEditor.m			\
	LSWAppointmentEditor+Fetches.m		\
	LSWAppointmentViewer.m			\
	LSWAppointmentMailPage.m		\
	LSWSchedulerPreferences.m		\
	LSWAppointmentProposal.m		\
	SkyParticipantsSelection.m		\
	SkyAptParticipantsList.m		\
	SkyResourceSelection.m			\
	LSWAppointmentMove.m			\
	SkyAptDateSelection.m			\
	SkyAppointmentPrintViewer.m             \
	NSCalendarDate+UnitAdder.m		\
	SkyAptTypeSelection.m			\
	OGoAppointmentDateFormatter.m		\
	OGoUserSelectionComponent.m		\
	OGoAttendeeSelection.m			\

LSWScheduler_RESOURCE_FILES += Defaults.plist Version

-include GNUmakefile.preamble
include $(GNUSTEP_MAKEFILES)/wobundle.make
-include GNUmakefile.postamble
-include ../../fhsbundle.make
