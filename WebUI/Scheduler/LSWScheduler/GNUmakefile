# $Id$

include ../common.make

WOBUNDLE_NAME = LSWScheduler

LSWScheduler_PRINCIPAL_CLASS = LSWSchedulerModule

LSWScheduler_OBJC_FILES = 			\
	LSWSchedulerModule.m			\
	LSWSchedulerDateTitle.m			\
	LSWSchedulerDateCell.m			\
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

LSWScheduler_COMPONENTS = 			\
	LSWAppointmentEditor.wo			\
	LSWAppointmentViewer.wo			\
	LSWAppointmentHtmlMailPage.wo		\
	LSWAppointmentTextMailPage.wo		\
	LSWSchedulerPreferences.wo		\
	LSWAppointmentProposal.wo		\
	SkyParticipantsSelection.wo		\
	SkyAptParticipantsList.wo		\
	SkyResourceSelection.wo			\
	LSWAppointmentMove.wo			\
	SkyAptDateSelection.wo			\
	SkyAppointmentPrintViewer.wo            \
	SkyAptTypeSelection.wo			\

LSWScheduler_RESOURCE_FILES += Defaults.plist Version

-include GNUmakefile.preamble
include $(GNUSTEP_MAKEFILES)/wobundle.make
-include GNUmakefile.postamble
