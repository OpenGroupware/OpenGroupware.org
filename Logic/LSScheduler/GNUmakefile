# $Id: GNUmakefile 1 2004-08-20 11:17:52Z znek $

include $(GNUSTEP_MAKEFILES)/common.make
-include ../Version
-include ./Version

COMMAND_BUNDLE = LSScheduler

GNUSTEP_INSTALLATION_DIR = $(GNUSTEP_LOCAL_ROOT)

LIBRARY_NAME = libOGoSchedulerTools
libOGoSchedulerTools_SOVERSION=$(MAJOR_VERSION).$(MINOR_VERSION)
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
	LSNewAppointmentCommand.m      			\
	LSGetAppointmentCommand.m      			\
	LSDeleteAppointmentCommand.m   			\
	LSGetDateForAWeekCommand.m     			\
	LSGetDateForADayCommand.m      			\
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

LSScheduler_RESOURCE_FILES += Version

LSScheduler_BUNDLE_LIBS += -lLSFoundation -lOGoSchedulerTools -lNGiCal

ADDITIONAL_LIB_DIRS += -L./$(GNUSTEP_OBJ_DIR)


-include GNUmakefile.preamble
include $(GNUSTEP_MAKEFILES)/library.make
include ../commandbundle.make
-include GNUmakefile.postamble
-include fhs.make
