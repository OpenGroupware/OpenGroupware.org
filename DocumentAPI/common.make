# shared makefile settings

OGoROOT=..

include $(GNUSTEP_MAKEFILES)/common.make
include $(OGoROOT)/Version
include ./Version

BUNDLE_INSTALL_DIR = $(OGO_DATASOURCES)

ADDITIONAL_CPPFLAGS += -pipe -Wall -Wno-protocol

ADDITIONAL_INCLUDE_DIRS += \
	-I../../Logic	\
	-I../

ADDITIONAL_LIB_DIRS += \
	-L../../Logic/LSFoundation/$(GNUSTEP_OBJ_DIR)

SYSTEM_LIB_DIR += $(CONFIGURE_SYSTEM_LIB_DIR)
