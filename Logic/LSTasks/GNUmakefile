# GNUstep makefile

-include ../../config.make
include ../common.make

COMMAND_BUNDLE = LSTasks

LSTasks_PCH_FILE = common.h

LSTasks_OBJC_FILES = \
	LSAllSubJobsDoneJobCommand.m		\
	LSAssignProjectToJobCommand.m		\
	LSDeleteJobCommand.m			\
	LSDeleteJobHistoryCommand.m		\
	LSDetachProjectFromJobCommand.m		\
	LSFetchArchivedJobsCommand.m		\
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

LSTasks_RESOURCE_FILES += Defaults.plist Version

include ../commandbundle.make
