# $Id$

OGoROOT=..

include $(GNUSTEP_MAKEFILES)/common.make
include $(OGoROOT)/Version
include ./Version

GNUSTEP_INSTALLATION_DIR = $(GNUSTEP_LOCAL_ROOT)

BUNDLE_INSTALL_DIR = $(GNUSTEP_INSTALLATION_DIR)/Library/OpenGroupware.org

ADDITIONAL_CPPFLAGS     += -pipe -Wall -Wno-protocol
ADDITIONAL_LIB_DIRS     += -L../LSFoundation/$(GNUSTEP_OBJ_DIR)
ADDITIONAL_INCLUDE_DIRS += -I../LSFoundation -I..
