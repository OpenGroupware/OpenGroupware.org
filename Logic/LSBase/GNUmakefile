# $Id$

include $(GNUSTEP_MAKEFILES)/common.make

COMMAND_BUNDLE = LSBase

LSBase_OBJC_FILES =               	\
	LSCryptCommand.m              	\
	LSSystemCtxLogCommand.m		\
	LSSystemCtxTransferCommand.m	\
	LSGetObjectTypeCommand.m	\
	LSAddLogCommand.m		\
	LSGetLogsCommand.m            	\
	LSRemoveLogsCommand.m		\
	LSIncreaseVersionCommand.m	\
	LSGetCurrentLogCommand.m	\
	LSAddSessionLogCommand.m	\
	LSQuerySessionLogs.m		\
	LSGetSessionLogsForGlobalIDs.m	\
	LSGetObjectByGlobalID.m		\
	LSSuperUserCommand.m		\

LSBase_RESOURCE_FILES += Defaults.plist Version

-include GNUmakefile.preamble
include commandbundle.make
-include GNUmakefile.postamble
