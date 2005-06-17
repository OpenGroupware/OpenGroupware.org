# GNUstep makefile

OGoROOT   =../../..
WebUIROOT =../..

-include $(OGoROOT)/config.make
include $(GNUSTEP_MAKEFILES)/common.make
include $(WebUIROOT)/Version

GNUSTEP_INSTALLATION_DIR = $(GNUSTEP_LOCAL_ROOT)

WOBUNDLE_INSTALL_DIR = $(GNUSTEP_INSTALLATION_DIR)/Library/OpenGroupware.org-1.1/WebUI/
WOBUNDLE_EXTENSION   = .lso

ADDITIONAL_INCLUDE_DIRS += \
	-I.. -I$(WebUIROOT)	\
	-I$(OGoROOT)/Logic	\
	-I$(OGoROOT)/DocumentAPI

ADDITIONAL_LIB_DIRS += \
	-L$(WebUIROOT)/OGoFoundation/$(GNUSTEP_OBJ_DIR)	\
	-L$(OGoROOT)/DocumentAPI/OGoDocuments/$(GNUSTEP_OBJ_DIR) \
	-L$(OGoROOT)/DocumentAPI/OGoContacts/$(GNUSTEP_OBJ_DIR)	 \
	-L$(OGoROOT)/DocumentAPI/OGoAccounts/$(GNUSTEP_OBJ_DIR)	 \
	-L$(OGoROOT)/DocumentAPI/OGoJobs/$(GNUSTEP_OBJ_DIR)	 \
	-L$(OGoROOT)/DocumentAPI/OGoScheduler/$(GNUSTEP_OBJ_DIR) \
	-L$(OGoROOT)/Logic/LSScheduler/$(GNUSTEP_OBJ_DIR)	 \
	-L$(OGoROOT)/Logic/LSFoundation/$(GNUSTEP_OBJ_DIR)

SYSTEM_LIB_DIR += -L/usr/local/lib -L/usr/lib

ADDITIONAL_BUNDLE_LIBS += \
	-lOGoFoundation		\
	-lLSFoundation		\
	-lNGObjWeb		\
	-lNGLdap -lNGMime	\
	-lNGStreams -lNGExtensions -lEOControl\
	-lXmlRpc

ADDITIONAL_CPPFLAGS += -Wall -pipe -Wno-protocol
