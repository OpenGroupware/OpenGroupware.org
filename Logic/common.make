# common makefile

OGoROOT=..

include $(GNUSTEP_MAKEFILES)/common.make
include $(OGoROOT)/Version
include ./Version

# TODO: fix me when we know how to make 5.3 to 1.1 => 5-4 = 1
BUNDLE_INSTALL_DIR = $(OGO_COMMANDS)

ADDITIONAL_CPPFLAGS     += -pipe -Wall -Wno-protocol
ADDITIONAL_LIB_DIRS     += -L../LSFoundation/$(GNUSTEP_OBJ_DIR)
ADDITIONAL_INCLUDE_DIRS += -I../LSFoundation -I..

SYSTEM_LIB_DIR += $(CONFIGURE_SYSTEM_LIB_DIR)
