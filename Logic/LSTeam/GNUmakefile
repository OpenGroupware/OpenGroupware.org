# $Id$

include ../common.make

COMMAND_BUNDLE = LSTeam

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

LSTeam_INCLUDE_DIRS = -IHeaders -I../LSAddress/Headers

LSTeam_BUNDLE_LIBS += -lLSSearch -lLSAddress -lldap
LSTeam_LIB_DIRS    += -L../LSSearch/$(GNUSTEP_OBJ_DIR) -L../LSAddress/$(GNUSTEP_OBJ_DIR)
# The BSD's definitely need this
LSTeam_LIB_DIRS += -L/usr/local/lib

include ../commandbundle.make
