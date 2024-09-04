# shared makefile settings

OGoROOT=..

include $(GNUSTEP_MAKEFILES)/common.make
include $(OGoROOT)/Version
include ./Version

# hh: 2024-09-04                                                                                                              
OGO_LIBDIR=${GNUSTEP_LIBRARY}
OGO_DATASOURCES=${OGO_LIBDIR}/DataSources-${MAJOR_VERSION}.${MINOR_VERSION}
#GNUSTEP_INSTALLATION_DIR = $(GNUSTEP_LOCAL_ROOT)
#BUNDLE_INSTALL_DIR = $(GNUSTEP_INSTALLATION_DIR)/Library/OpenGroupware.org-5.5/DataSources/

ADDITIONAL_CPPFLAGS += -pipe -Wall -Wno-protocol

ADDITIONAL_INCLUDE_DIRS += \
	-I../../Logic	\
	-I../

ADDITIONAL_LIB_DIRS += \
	-L../../Logic/LSFoundation/$(GNUSTEP_OBJ_DIR)

SYSTEM_LIB_DIR += $(CONFIGURE_SYSTEM_LIB_DIR)
