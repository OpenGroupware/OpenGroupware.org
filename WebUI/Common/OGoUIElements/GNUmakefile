# $Id: GNUmakefile 1 2004-08-20 11:17:52Z znek $

include ../common.make

WOBUNDLE_NAME = OGoUIElements

OGoUIElements_PRINCIPAL_CLASS = SkyUIElementsModule

OGoUIElements_OBJC_FILES = 		\
	SkyUIElementsModule.m         	\
	SkyFileManagerTreeView.m	\
	SkyTabView.m                  	\
        SkyTabFontAssociation.m		\
	SkyTabAssociation.m		\
	SkyTabItem.m			\
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

OGoUIElements_COMPONENTS = 		\
	SkyFileManagerTreeView.wo	\
	SkyTableView.wo			\
	SkyCollapsibleContent.wo	\
	SkyTextEditor.wo		\
	SkyAccessList.wo		\

OGoUIElements_LANGUAGES = English German

OGoUIElements_RESOURCE_FILES += \
	Defaults.plist Version	\
	\
	SkyTableView_SelectAllCheckboxesScript.js\
	SkyTableView_ShiftClickScript.js	\
	\
	SkyCalendarScript.wox			\
	SkyCalendarPopUp.wox			\

-include GNUmakefile.preamble
include $(GNUSTEP_MAKEFILES)/wobundle.make
-include GNUmakefile.postamble
-include ../../fhsbundle.make
