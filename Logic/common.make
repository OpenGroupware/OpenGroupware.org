# common makefile

OGoROOT=..

include $(GNUSTEP_MAKEFILES)/common.make
include $(OGoROOT)/Version
include ./Version

BUNDLE_INSTALL_DIR = $(OGO_COMMANDS)

ADDITIONAL_CPPFLAGS     += -pipe -Wall -Wno-protocol
ADDITIONAL_LIB_DIRS     += -L../LSFoundation/$(GNUSTEP_OBJ_DIR)
ADDITIONAL_INCLUDE_DIRS += -I../LSFoundation -I..

SYSTEM_LIB_DIR += $(CONFIGURE_SYSTEM_LIB_DIR)
