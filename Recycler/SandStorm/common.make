# GNUstep makefile, common settings

OGoROOT=../../..

include $(OGoROOT)/config.make
include $(GNUSTEP_MAKEFILES)/common.make
#include $(OGoROOT)/Version
-include ./Version

GNUSTEP_INSTALLATION_DIR = $(GNUSTEP_LOCAL_ROOT)

ADDITIONAL_CPPFLAGS     += -pipe -Wall -Wno-protocol
ADDITIONAL_INCLUDE_DIRS += -I.. -I.
ADDITIONAL_TOOL_LIBS    += -lOGoDaemon -lOGoIDL -lXmlRpc

ADDITIONAL_LIB_DIRS += \
	-L./$(GNUSTEP_OBJ_DIR)	\
	-L../OGoDaemon/$(GNUSTEP_OBJ_DIR)	\
	-L../OGoIDL/$(GNUSTEP_OBJ_DIR)		\
	-L../XmlSchema/$(GNUSTEP_OBJ_DIR)

ifeq ($(FOUNDATION_LIB),nx)
ADDITIONAL_TOOL_LIBS += -lFoundationExt
ADDITIONAL_LDFLAGS += -framework Foundation
endif

TEMPLATE_INSTALL_DIR=$(GNUSTEP_SYSTEM_ROOT)/config/skymasterd/
INSTANCE_INSTALL_DIR=$(GNUSTEP_SYSTEM_ROOT)/config/skymasterd-instances/
