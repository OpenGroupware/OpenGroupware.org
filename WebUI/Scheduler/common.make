# $Id$

OGoROOT  =../../..
WebUIROOT=../..

include $(GNUSTEP_MAKEFILES)/common.make
include $(WebUIROOT)/Version

GNUSTEP_INSTALLATION_DIR = $(GNUSTEP_LOCAL_ROOT)

WOBUNDLE_INSTALL_DIR = $(GNUSTEP_INSTALLATION_DIR)/Library/OpenGroupware.org-1.0a/WebUI/
WOBUNDLE_EXTENSION   = .lso

SCHEDULER_LIBS += \
	-lOGoScheduler -lOGoSchedulerTools \
	-lOGoFoundation	-lOGoDocuments \
	-lLSFoundation		\
	-lGDLAccess		\
	-lNGObjWeb		\
	-lNGLdap -lNGMime	\
	-lNGStreams -lNGExtensions -lEOControl \
	-lXmlRpc

ADDITIONAL_INCLUDE_DIRS += \
	-I.. -I../..		\
	-I$(OGoROOT)/Logic	\
	-I$(OGoROOT)/DocumentAPI

ADDITIONAL_LIB_DIRS += \
	-L$(WebUIROOT)/OGoFoundation/$(GNUSTEP_OBJ_DIR) \
	-L$(OGoROOT)/DocumentAPI/OGoScheduler/$(GNUSTEP_OBJ_DIR) \
	-L$(OGoROOT)/DocumentAPI/OGoDocuments/$(GNUSTEP_OBJ_DIR) \
	-L$(OGoROOT)/Logic/LSScheduler/$(GNUSTEP_OBJ_DIR) \
	-L$(OGoROOT)/Logic/LSFoundation/$(GNUSTEP_OBJ_DIR)

#ADDITIONAL_WOBUNDLE_LIBS += $(SCHEDULER_LIBS)
ADDITIONAL_BUNDLE_LIBS += $(SCHEDULER_LIBS)

ADDITIONAL_CPPFLAGS += -Wall

SYSTEM_LIB_DIR += -L/usr/local/lib -L/usr/lib
