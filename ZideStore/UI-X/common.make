# common makefile for UI-X bundles

include $(GNUSTEP_MAKEFILES)/common.make
include ./Version
include ../../Version

OGoROOT=../../..


BUNDLE_EXTENSION   = .zsp
BUNDLE_INSTALL_DIR = $(GNUSTEP_INSTALLATION_DIR)/Library/ZideStore-$(MAJOR_VERSION).$(MINOR_VERSION)/


ADDITIONAL_INCLUDE_DIRS += -I. -I.. -I../..


ADDITIONAL_LIB_DIRS += \
	-L../../ZSFrontend/$(GNUSTEP_OBJ_DIR)	\
	-L../../ZSBackend/$(GNUSTEP_OBJ_DIR)	\
	-L./$(GNUSTEP_OBJ_DIR)

SYSTEM_LIB_DIR += -L/usr/local/lib -L/usr/lib
