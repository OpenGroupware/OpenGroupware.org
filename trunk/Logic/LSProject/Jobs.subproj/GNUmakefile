# $Id$

include $(GNUSTEP_MAKEFILES)/common.make

SUBPROJECT_NAME = Jobs

Jobs_OBJC_FILES = \
	LSAllSubJobsDoneJobCommand.m		\
	LSAssignProjectToJobCommand.m		\
	LSControlJobCommand.m			\
	LSDeleteJobCommand.m			\
	LSDeleteJobHistoryCommand.m		\
	LSDetachProjectFromJobCommand.m		\
	LSFetchArchivedJobsCommand.m		\
	LSFetchControlJobsCommand.m		\
	LSFetchDelegatedJobsCommand.m		\
	LSFetchJobCommand.m			\
	LSFetchJobExecutantCommand.m		\
	LSFetchJobsForExecutantCommand.m	\
	LSFetchPrivateJobsCommand.m		\
	LSFetchProjectJobsCommand.m		\
	LSFetchProjectToJobCommand.m		\
	LSFetchProjectToRootJobCommand.m	\
	LSFetchToDoJobsCommand.m		\
	LSFilterArchivedJobCommand.m		\
	LSFilterControlJobCommand.m		\
	LSFilterDelegatedJobCommand.m		\
	LSFilterJobCommand.m			\
	LSFilterToDoListJobCommand.m		\
	LSGetJobsForGlobalIDs.m			\
	LSGetParentJobsCommand.m		\
	LSImportJobCommand.m			\
	LSJobActionCommand.m			\
	LSNewJobCommand.m			\
	LSNewJobHistoryCommand.m		\
	LSRemoveWasteJobsCommand.m		\
	LSSetJobCommand.m			\

ADDITIONAL_INCLUDE_DIRS += 	\
	-I. -I.. -I../..	\
	-I../../LSSearch/ 	\
	-I../../LSFoundation	\

include $(GNUSTEP_MAKEFILES)/subproject.make
