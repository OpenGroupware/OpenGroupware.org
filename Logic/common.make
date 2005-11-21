# common makefile

OGoROOT=..

include $(GNUSTEP_MAKEFILES)/common.make
include $(OGoROOT)/Version
include ./Version

GNUSTEP_INSTALLATION_DIR = $(GNUSTEP_LOCAL_ROOT)

# TODO: fix me when we know how to make 5.3 to 1.1 => 5-4 = 1
BUNDLE_INSTALL_DIR = $(GNUSTEP_INSTALLATION_DIR)/Library/OpenGroupware.org-1.1/Commands/

ADDITIONAL_CPPFLAGS     += -pipe -Wall -Wno-protocol
ADDITIONAL_LIB_DIRS     += -L../LSFoundation/$(GNUSTEP_OBJ_DIR)
ADDITIONAL_INCLUDE_DIRS += -I../LSFoundation -I..
