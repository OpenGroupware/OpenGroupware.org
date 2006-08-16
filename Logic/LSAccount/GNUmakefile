# GNUstep makefile

-include ../../config.make
include ../common.make

COMMAND_BUNDLE = LSAccount

LSAccount_PCH_FILE = common.h
LSAccount_OBJC_FILES = \
	LSNewAccountCommand.m              	\
	LSSetAccountCommand.m              	\
	LSGetAccountByLoginCommand.m       	\
	LSGetTeamForAccountCommand.m       	\
	LSLoginAccountCommand.m			\
	LSGetAccountCommand.m              	\
	LSExtendedSearchAccountCommand.m	\
	LSDeleteAccountCommand.m		\
	LSGetAccountsForGlobalIDsCommand.m	\
	LSAccountToPersonCommand.m		\
	LSChangePasswordCommand.m		\

LSAccount_RESOURCE_FILES += Defaults.plist Version

-include GNUmakefile.preamble
include ../commandbundle.make
-include GNUmakefile.postamble
