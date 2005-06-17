# shared makefile settings

OGoROOT=..

include $(GNUSTEP_MAKEFILES)/common.make
include $(OGoROOT)/Version
include ./Version

GNUSTEP_INSTALLATION_DIR = $(GNUSTEP_LOCAL_ROOT)

BUNDLE_INSTALL_DIR = $(GNUSTEP_INSTALLATION_DIR)/Library/OpenGroupware.org-1.1/DataSources/

ADDITIONAL_CPPFLAGS += -pipe -Wall -Wno-protocol

ADDITIONAL_INCLUDE_DIRS += \
	-I../../Logic	\
	-I../

ADDITIONAL_LIB_DIRS += \
	-L../../Logic/LSFoundation/$(GNUSTEP_OBJ_DIR)

SYSTEM_LIB_DIR += -L/usr/local/lib -L/usr/lib
