# $Id$

OGoROOT  =../../..
WebUIROOT=../..

include $(GNUSTEP_MAKEFILES)/common.make
include $(WebUIROOT)/Version

WOBUNDLE_EXTENSION   = .lso
WOBUNDLE_INSTALL_DIR = $(GNUSTEP_LOCAL_ROOT)/Library/OpenGroupware.org

ADDITIONAL_INCLUDE_DIRS += 		\
	-I.. -I../..			\
	-I$(OGoROOT)/Logic/LSFoundation	\
	-I$(OGoROOT)/DocumentAPI

ADDITIONAL_LIB_DIRS     += 					\
	-L$(WebUIROOT)/OGoFoundation/$(GNUSTEP_OBJ_DIR)		\
	-L$(OGoROOT)/DocumentAPI/OGoProject/$(GNUSTEP_OBJ_DIR)   \
	-L$(OGoROOT)/DocumentAPI/OGoAccounts/$(GNUSTEP_OBJ_DIR)  \
	-L$(OGoROOT)/DocumentAPI/OGoBase/$(GNUSTEP_OBJ_DIR)	 \
	-L$(OGoROOT)/DocumentAPI/OGoDocuments/$(GNUSTEP_OBJ_DIR) \
	-L$(OGoROOT)/Logic/LSFoundation/$(GNUSTEP_OBJ_DIR)

ADDITIONAL_BUNDLE_LIBS += 	\
	-lOGoFoundation -lOGoDocuments \
	-lLSFoundation		\
	-lGDLAccess		\
	-lNGObjWeb -lNGScripting\
	-lNGLdap -lNGMime -lNGStreams -lNGExtensions -lEOControl \
	-lXmlRpc -lDOM -lSaxObjC

ADDITIONAL_WOBUNDLE_LIBS += $(ADDITIONAL_BUNDLE_LIBS)

ADDITIONAL_CPPFLAGS += -Wno-protocol -Wall

ifeq ($(GNUSTEP_TARGET_OS),mingw32)
LSWAddress_BUNDLE_LIBS += \
	-lNGMime \
	-lNGStreams -lNGExtensions -lEOControl \
	-lFoundation -lobjc
endif

ifeq ($(FOUNDATION_LIB),nx)
BUNDLE_LIBS += -lFoundationExt
ADDITIONAL_LDFLAGS += -framework Foundation
endif
