# common makefile

OGoROOT=..

include $(GNUSTEP_MAKEFILES)/common.make
include $(OGoROOT)/Version
include ./Version

# hh: 2024-09-04
OGO_LIBDIR=${GNUSTEP_LIBRARY}
OGO_COMMANDS=${OGO_LIBDIR}/Commands-${MAJOR_VERSION}.${MINOR_VERSION}
#GNUSTEP_INSTALLATION_DIR = $(GNUSTEP_LOCAL_ROOT)
#BUNDLE_INSTALL_DIR = $(GNUSTEP_INSTALLATION_DIR)/Library/OpenGroupware.org-5.5/Commands/

ADDITIONAL_CPPFLAGS     += -pipe -Wall -Wno-protocol 
ADDITIONAL_LIB_DIRS     += -L../LSFoundation/$(GNUSTEP_OBJ_DIR)
ADDITIONAL_INCLUDE_DIRS += -I../LSFoundation -I..

SYSTEM_LIB_DIR += $(CONFIGURE_SYSTEM_LIB_DIR)

# Otherwise explicitly linked shared libs are not requested!
ADDITIONAL_LDFLAGS += -Wl,--no-as-needed
