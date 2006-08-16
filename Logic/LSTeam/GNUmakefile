# GNUstep makefile

-include ../../config.make
include ../common.make

COMMAND_BUNDLE = LSTeam

LSTeam_PCH_FILE = common.h

LSTeam_OBJC_FILES = \
	LSNewTeamCommand.m                 	\
	LSSetTeamCommand.m                 	\
	LSGetTeamByLoginCommand.m           	\
	LSGetMemberForTeamCommand.m        	\
	LSResolveAccountsCommand.m	   	\
	LSCheckPermissionCompanyCommand.m 	\
	LSGetTeamsForGlobalIDsCommand.m		\
	LSGetAllTeamsCommand.m			\
	LSDeleteTeamCommand.m 			\
	LSExtendedSearchTeamCommand.m		\
	LSGetTeamCommand.m         		\

LSTeam_RESOURCE_FILES += Defaults.plist Version

-include GNUmakefile.preamble
include ../commandbundle.make
-include GNUmakefile.postamble
