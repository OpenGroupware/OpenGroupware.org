# $Id$

include ../common.make

COMMAND_BUNDLE = LSPerson

LSPerson_OBJC_FILES += \
	LSExtendedSearchPersonCommand.m			\
	LSFetchTelsForPersonCommand.m			\
	LSFullSearchPersonCommand.m			\
	LSGetAssignedProjectIdsForPersonCommand.m	\
	LSGetEnterpriseForPersonCommand.m		\
	LSGetPersonCommand.m				\
	LSGetProjectForPersonCommand.m			\
	LSNewPersonCommand.m				\
	LSSetPersonCommand.m				\
	LSGetPersonsForGlobalIDs.m			\
	LSPersonToAccountCommand.m			\

LSPerson_RESOURCE_FILES += Version

LSPerson_INCLUDE_DIRS += -I../LSAddress/Headers
LSPerson_BUNDLE_LIBS  += -lLSSearch -lLSFoundation -lLSAddress

LSPerson_LIB_DIRS += \
	-L../LSSearch/$(GNUSTEP_OBJ_DIR)	\
	-L../LSAddress/$(GNUSTEP_OBJ_DIR)

include ../commandbundle.make
