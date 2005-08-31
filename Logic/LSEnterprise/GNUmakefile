# GNUstep makefile

-include ../../config.make
include ../common.make

COMMAND_BUNDLE = LSEnterprise

LSEnterprise_PCH_FILE = common.h

LSEnterprise_OBJC_FILES += \
        LSExtendedSearchEnterpriseCommand.m     \
        LSFullSearchEnterpriseCommand.m         \
        LSGetEnterpriseCommand.m                \
        LSGetFakeProjectForEnterpriseCommand.m  \
        LSGetMemberForEnterpriseCommand.m       \
        LSGetProjectForEnterpriseCommand.m      \
        LSNewEnterpriseCommand.m                \
        LSSetEnterpriseCommand.m                \
        LSGetEnterprisesForGlobalIDs.m          \

LSEnterprise_RESOURCE_FILES += Version

LSEnterprise_INCLUDE_DIRS += -I../LSAddress/Headers
LSEnterprise_BUNDLE_LIBS  += -lLSSearch -lLSAddress

LSEnterprise_LIB_DIRS += \
	-L../LSSearch/$(GNUSTEP_OBJ_DIR)	\
	-L../LSAddress/$(GNUSTEP_OBJ_DIR)

include ../commandbundle.make
