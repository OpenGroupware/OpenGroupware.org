# GNUstep makefile

include ../../config.make
include ../common.make
-include ../Version
-include ./Version

COMMAND_BUNDLE = LSScheduler

LSScheduler_PCH_FILE = common.h
libOGoSchedulerTools_PCH_FILE = common.h

LIBRARY_NAME = libOGoSchedulerTools
libOGoSchedulerTools_INTERFACE_VERSION=$(MAJOR_VERSION).$(MINOR_VERSION)
libOGoSchedulerTools_INSTALL_DIR=$(OGO_SYSLIBDIR)
libOGoSchedulerTools_VERSION=$(MAJOR_VERSION).$(MINOR_VERSION).$(SUBMINOR_VERSION)

libOGoSchedulerTools_HEADER_FILES = \
	OGoCycleDateCalculator.h \

libOGoSchedulerTools_OBJC_FILES = \
	OGoCycleDateCalculator.m \
	OGoCycleDateDelegate.m   \

libOGoSchedulerTools_HEADER_FILES_DIR         = .
libOGoSchedulerTools_HEADER_FILES_INSTALL_DIR = /OGoSchedulerTools

LSScheduler_OBJC_FILES = \
	LSAptAccessCommand.m				\
	LSQueryAppointments.m				\
	LSGetAppointmentsForGlobalIDs.m			\
	LSConvertTimeZoneCommand.m     			\
	LSSetAppointmentCommand.m      			\
	LSSetResourcesCommand.m				\
	LSNewAppointmentCommand.m      			\
	LSGetAppointmentCommand.m      			\
	LSDeleteAppointmentCommand.m   			\
	LSGetDateWithConflictCommand.m 			\
	LSDateAssignmentCommand.m      			\
	LSGetCompanyForDateCommand.m   			\
	LSFilterAMWeekDaysCommand.m    			\
	LSFilterPMWeekDaysCommand.m    			\
	LSFilterWeekDaysCommand.m      			\
	LSFilterSeveralDaysCommand.m   			\
	LSFilterAbsenceCommand.m       			\
	LSFilterStaffCommand.m         			\
	LSMondaysOfYearCommand.m      	 		\
	LSCyclicAppointmentsCommand.m  			\
	LSMonthCommand.m               			\
	LSParticipantsIntersectionCommand.m		\
	LSFetchCyclicAppointmentCommand.m		\
	LSAppointmentProposalCommand.m     		\
	LSFilterAttendanceCommand.m			\
	LSAppointment+Filters.m				\
	LSGetAppointmentsOfAccountCommand.m		\
	LSGetAccessTeamInfoCommand.m			\
	LSGetCommentForAppointmentsCommand.m		\
	LSGetResourcesForGlobalIDs.m			\
	LSResourceCategories.m				\
	LSUsedResourcesCommand.m			\
	LSListParticipantsCommand.m			\
	LSMoveAppointmentCommand.m			\
	LSUpdateAppointmentWithVEventCommand.m     	\
	LSGetAppointmentsForSourceUrls.m		\
	LSNewAppointmentFromVEventCommand.m		\
	LSGetICalForAppointmentsCommand.m		\
	NSString+ICal.m					\
	OGoAptAccessHandler.m				\
	LSChangeAttendeeStatusCommand.m			\
	LSAddOrRemoveMeCommand.m			\

LSScheduler_RESOURCE_FILES += Version

-include GNUmakefile.preamble
ifneq ($(FHS_INSTALL_ROOT),)
GNUSTEP_HEADERS=$(DESTDIR)$(FHS_INSTALL_ROOT)/include
endif
include $(GNUSTEP_MAKEFILES)/library.make
include ../commandbundle.make
-include GNUmakefile.postamble
