# common makefile for bundles

include $(GNUSTEP_MAKEFILES)/common.make
include ./Version
include ../../Version

OGoROOT=../../..


BUNDLE_EXTENSION   = .zsp
BUNDLE_INSTALL_DIR = $(GNUSTEP_USER_ROOT)/Library/ZideStore-1.3/


ADDITIONAL_INCLUDE_DIRS += -I. -I.. -I../..

ADDITIONAL_INCLUDE_DIRS += \
	-I$(OGoROOT)/Logic/LSFoundation/


ADDITIONAL_LIB_DIRS += \
	-L../../ZSFrontend/$(GNUSTEP_OBJ_DIR)	\
	-L../../ZSBackend/$(GNUSTEP_OBJ_DIR)	\
	-L./$(GNUSTEP_OBJ_DIR)
