# $Id$

OGoROOT=../..

include $(GNUSTEP_MAKEFILES)/common.make
include ../Version
include ./Version

WOBUNDLE_NAME        = OGoPalm
WOBUNDLE_EXTENSION   = .lso
WOBUNDLE_INSTALL_DIR = $(GNUSTEP_USER_ROOT)/Library/OpenGroupware.org

OGoPalm_PRINCIPAL_CLASS = SkyPalmModule
ADDITIONAL_WOBUNDLE_LIBS += 		\
	-lOGoFoundation -lNGObjWeb  	\
	-lOGoScheduler 			\
	-lOGoRawDatabase		\
	-lOGoProject			\

OGoPalm_OBJC_FILES = \
	SkyPalmModule.m			\
	SkyPalmPage.m			\
	WODirectAction+PalmViews.m	\
	SkyPalmPreferences.m		\
	\
	SkyPalmAddressViewer.m		\
	SkyPalmDateViewer.m		\
	SkyPalmMemoViewer.m		\
	SkyPalmJobViewer.m		\
	SkyPalmDateCopyViewer.m		\
	\
	SkyPalmAddressEditor.m		\
	SkyPalmDateEditor.m		\
	SkyPalmMemoEditor.m		\
	SkyPalmJobEditor.m		\
	\
	SkyPalmRecordList.m		\
	SkyPalmJobList.m		\
	SkyPalmAddressList.m		\
	SkyPalmDateList.m		\
	SkyPalmMemoList.m		\
	SkyPalmDateWeekOverview.m	\
	SkyPalmEntryListHeader.m	\
	SkyPalmEntryListContent.m	\
	SkyPalmCategoryPopUp.m		\
	\
	SkyPalmStringAttribute.m	\
	SkyPalmInlineDateViewer.m	\
	\
	SkyPalmSelectableListing.m	\
	SkyPalmProjectListing.m		\
	SkyPalmFileListing.m		\
	SkyPalmCompanyListing.m		\
	SkyPalmJobListing.m		\
	SkyPalmAppointmentListing.m	\
	\
	SkyPalmAssignAddress.m		\
	SkyPalmAssignDate.m		\
	SkyPalmAssignMemo.m		\
	SkyPalmAssignJob.m		\

OGoPalm_COMPONENTS = \
	SkyPalmPage.wo			\
	SkyPalmPreferences.wo		\
	\
	SkyPalmAddressViewer.wo		\
	SkyPalmDateViewer.wo		\
	SkyPalmMemoViewer.wo		\
	SkyPalmJobViewer.wo		\
	SkyPalmDateCopyViewer.wo	\
	\
	SkyPalmDateEditor.wo		\
	SkyPalmAddressEditor.wo		\
	SkyPalmMemoEditor.wo		\
	SkyPalmJobEditor.wo		\
	\
	SkyPalmRecordList.wo		\
	SkyPalmJobList.wo		\
	SkyPalmAddressList.wo		\
	SkyPalmDateList.wo		\
	SkyPalmMemoList.wo		\
	SkyPalmDateWeekOverview.wo	\
	SkyPalmEntryListHeader.wo	\
	SkyPalmEntryListContent.wo	\
	SkyPalmCategoryPopUp.wo		\
	\
	SkyPalmStringAttribute.wo	\
	SkyPalmInlineDateViewer.wo	\
	SkyPalmProjectListing.wo	\
	SkyPalmFileListing.wo		\
	SkyPalmCompanyListing.wo	\
	SkyPalmJobListing.wo		\
	SkyPalmAppointmentListing.wo	\
	\
	SkyPalmAssignAddress.wo		\
	SkyPalmAssignDate.wo		\
	SkyPalmAssignMemo.wo		\
	SkyPalmAssignJob.wo		\

OGoPalm_LANGUAGES = English German

ADDITIONAL_INCLUDE_DIRS += -I../OGoPalm/ -I..
ADDITIONAL_LIB_DIRS += -L../OGoPalm/$(GNUSTEP_OBJ_DIR)
ADDITIONAL_LIB_DIRS += -L../OGoPalmUI/$(GNUSTEP_OBJ_DIR)
ADDITIONAL_WOBUNDLE_LIBS += -lOGoPalm -lOGoPalmUI

OGoPalm_RESOURCE_FILES += Defaults.plist	\

-include GNUmakefile.preamble
include $(GNUSTEP_MAKEFILES)/wobundle.make
-include GNUmakefile.postamble
