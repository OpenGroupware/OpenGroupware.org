# GNUstep makefile

-include ../../config.make
include ../common.make

COMMAND_BUNDLE = LSResource

$(COMMAND_BUNDLE)_OBJC_FILES =              \
    LSNewResourceCommand.m                  \
    LSSetResourceCommand.m                  \
    LSExtendedSearchSingleResourceCommand.m \
    LSSetResourceAssignmentCommand.m        \
    LSGetSubResourcesCommand.m              \
    LSGetSuperResourcesCommand.m            \
    LSDeleteResourceCommand.m               \

LSResource_RESOURCE_FILES += ./Version

LSResource_BUNDLE_LIBS += -lLSSearch
ADDITIONAL_LIB_DIRS += -L../LSSearch/$(GNUSTEP_OBJ_DIR)

include ../commandbundle.make
