# $Id$

OGoROOT=..

include $(GNUSTEP_MAKEFILES)/common.make
include ../Version

GNUSTEP_INSTALLATION_DIR = $(GNUSTEP_LOCAL_ROOT)

ADDITIONAL_INCLUDE_DIRS += 		\
	-I.. 				\
	-I../../Logic/LSFoundation	\
	-I../../DocumentAPI		\

ADDITIONAL_LIB_DIRS     += -L../OGoFoundation/$(GNUSTEP_OBJ_DIR)

ADDITIONAL_BUNDLE_LIBS += \
	-lOGoFoundation -lOGoDocuments	\
	-lLSFoundation	\
	-lNGObjWeb	\
	-lNGLdap -lNGMime -lNGStreams -lNGExtensions -lEOControl \
	-lXmlRpc

ADDITIONAL_CPPFLAGS += -Wall -pipe -Wno-protocol
