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

-include GNUmakefile.preamble
include ../commandbundle.make
-include GNUmakefile.postamble
