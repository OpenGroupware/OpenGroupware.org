# $Id$

OGoROOT   =../../..
WebUIROOT =../..

include $(GNUSTEP_MAKEFILES)/common.make
include $(WebUIROOT)/Version

GNUSTEP_INSTALLATION_DIR = $(GNUSTEP_LOCAL_ROOT)

WOBUNDLE_INSTALL_DIR = $(GNUSTEP_INSTALLATION_DIR)/Library/OpenGroupware.org
WOBUNDLE_EXTENSION   = .lso

ADDITIONAL_INCLUDE_DIRS += 		\
	-I.. -I../.. 			\
	-I../../../Logic/LSFoundation	\
	-I../../../DocumentAPI		\

ADDITIONAL_LIB_DIRS     += -L../../OGoFoundation/$(GNUSTEP_OBJ_DIR)

ADDITIONAL_BUNDLE_LIBS += \
	-lOGoFoundation	\
	-lLSFoundation	\
	-lNGObjWeb	\
	-lNGLdap -lNGMime -lNGStreams -lNGExtensions -lEOControl\
	-lXmlRpc

ADDITIONAL_CPPFLAGS += -Wall -pipe -Wno-protocol
