# GNUstep makefile

-include ../../config.make
include ../common.make

COMMAND_BUNDLE = LSMail

LSMail_OBJC_FILES =        \
	LSMailDeliverCommand.m      \
	LSMailFunctions.m           \

LSMail_RESOURCE_FILES += Version

LSMail_BUNDLE_LIBS += -lNGMime

ADDITIONAL_LIB_DIRS += -L../LSSearch/$(GNUSTEP_OBJ_DIR)
LSMail_BUNDLE_LIBS += -lLSSearch

include ../commandbundle.make
