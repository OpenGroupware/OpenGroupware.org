# $Id$

include ../common.make

TOOL_NAME   = skyjobd
BUNDLE_NAME = SkyJob

SkyJob_PRINCIPAL_CLASS = SkyJobAction

SkyJob_RESOURCE_FILES =	\
	Version			\
	INTERFACE.xml		\
	SkyJobActionMap.plist	\
	commands.plist		\

SkyJob_OBJC_FILES = 			\
	SkyJobApplication.m		\
	Job.m				\
	JobHistory.m			\
					\
	ObjectPool.m			\
	JobPool.m			\
	JobHistoryPool.m		\
					\
	SkyJobAction.m			\
	SkyJobAction+PrivateMethods.m	\
	SkyJobQualifier.m		\
					\
	LSNewJobCommand.m		\
	LSDeleteJobCommand.m		\
	LSGetJobsForGlobalIDs.m		\
	LSFetchPrivateJobsCommand.m	\
	LSFetchArchivedJobsCommand.m	\
	LSFetchControlJobsCommand.m	\
	LSFetchDelegatedJobsCommand.m	\
	LSFetchToDoJobsCommand.m	\
	LSJobActionCommand.m		\
					\
	NSObject+Transaction.m		\

skyjobd_OBJC_FILES = 			\
	skyjobd.m			\

-include GNUmakefile.preamble
include ../xmlrpcd.make
include $(GNUSTEP_MAKEFILES)/tool.make
-include GNUmakefile.postamble
