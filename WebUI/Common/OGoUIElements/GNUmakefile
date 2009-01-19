# GNUstep makefile

include ../common.make

WOBUNDLE_NAME = OGoUIElements

OGoUIElements_PRINCIPAL_CLASS = SkyUIElementsModule

OGoUIElements_PCH_FILE = common.h

OGoUIElements_OBJC_FILES = 		\
	SkyUIElementsModule.m         	\
	SkyFileManagerTreeView.m	\
	SkyTabView.m                  	\
        SkyTabFontAssociation.m		\
	SkyTabAssociation.m		\
	SkyTableView.m                	\
	SkyTreeView.m                 	\
	SkyCollapsibleContent.m       	\
	SkyLicenseConditional.m       	\
	SkyRichString.m               	\
	SkyTextEditor.m			\
	SkyTextEditor+ValidateXML.m	\
	SkyTextEditor+ValidateHTML.m	\
	SkyDateField.m			\
	SkyNoTakeValues.m		\
	SkyProfileTemplate.m		\
	SkyAccessList.m			\
	SkySimpleTabItem.m		\
	SkyDialNumber.m			\
	SkyCalendarScript.m		\
	SkyCalendarPopUp.m		\
	SkyExternalLink.m		\
	OGoPageButton.m			\
	OGoUIElementsBuilder.m		\
	OGoEmbedExternalLink.m		\
	OGoFieldSet.m			\
	OGoField.m			\
	OGoAddressMapLinks.m		\

OGoUIElements_LANGUAGES = English German

OGoUIElements_RESOURCE_FILES += \
	Defaults.plist Version	\
	\
	SkyTableView_SelectAllCheckboxesScript.js\
	SkyTableView_ShiftClickScript.js	\

-include GNUmakefile.preamble
include $(GNUSTEP_MAKEFILES)/wobundle.make
-include GNUmakefile.postamble
-include ../../fhsbundle.make
