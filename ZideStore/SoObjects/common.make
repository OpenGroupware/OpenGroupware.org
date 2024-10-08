# common makefile for bundles

OGoROOT=../../..

-include $(OGoROOT)/config.make
include $(GNUSTEP_MAKEFILES)/common.make
include ./Version
include ../../Version

OGO_LIBDIR=${GNUSTEP_LIBRARY}
OGO_ZIDESTORE=${OGO_LIBDIR}/ZideStore-${MAJOR_VERSION}.${MINOR_VERSION}

BUNDLE_EXTENSION   = .zsp
#BUNDLE_INSTALL_DIR = $(GNUSTEP_INSTALLATION_DIR)/Library/ZideStore-$(MAJOR_VERSION).$(MINOR_VERSION)/


ADDITIONAL_INCLUDE_DIRS += -I. -I.. -I../..

ADDITIONAL_INCLUDE_DIRS += -I$(OGoROOT)/Logic


ADDITIONAL_LIB_DIRS += \
	-L../../ZSFrontend/$(GNUSTEP_OBJ_DIR)	\
	-L../../ZSBackend/$(GNUSTEP_OBJ_DIR)	\
	-L./$(GNUSTEP_OBJ_DIR) \
	-L$(OGoROOT)/Logic/LSFoundation/$(GNUSTEP_OBJ_DIR)

SYSTEM_LIB_DIR += $(CONFIGURE_SYSTEM_LIB_DIR)
