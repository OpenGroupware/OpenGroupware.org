# GNUstep makefile

-include ../../config.make
include ../common.make

COMMAND_BUNDLE = LSProject

LSProject_OBJC_FILES += \
	LSArchiveProjectCommand.m		\
	LSCheckGetPermissionProjectCommand.m	\
	LSCheckPermissionProjectCommand.m	\
	LSCheckWritePermissionProjectCommand.m	\
	LSDeleteProjectCommand.m		\
	LSFetchAccountRelationCommand.m		\
	LSFetchEnterpriseRelationCommand.m	\
	LSFetchPersonRelationCommand.m		\
	LSFetchTeamRelationCommand.m		\
	LSGetProjectCommand.m			\
	LSGetProjectForGlobalIDs.m		\
	LSGetResourcesCommand.m			\
	LSNewNoteCommand.m			\
	LSNewProjectCommand.m			\
	LSProjectAssignmentCommand.m		\
	LSProjectStatusCommand.m		\
	LSSetNoteCommand.m			\
	LSSetPersonsForProjectCommand.m		\
	LSSetProjectCommand.m			\
	LSGetFavoriteProjectIdsCommand.m	\

LSProject_RESOURCE_FILES += Defaults.plist Version

LSProject_BUNDLE_LIBS += -lLSSearch
LSProject_LIB_DIRS    += -L../LSSearch/$(GNUSTEP_OBJ_DIR)

include ../commandbundle.make
