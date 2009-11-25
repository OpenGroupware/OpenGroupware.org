# GNUstep makefile

include ../../config.make
include ../common.make

COMMAND_BUNDLE = LSBase

LSBase_PCH_FILE = common.h

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
	LSQueryLogsSince.m		\
	LSIncrementCTagCommand.m	\
	LSGetCTagForEntityCommand.m

LSBase_RESOURCE_FILES += Defaults.plist Version

-include GNUmakefile.preamble
include commandbundle.make
-include GNUmakefile.postamble
