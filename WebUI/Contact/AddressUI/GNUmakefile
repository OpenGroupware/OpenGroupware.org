# $Id: GNUmakefile 1 2004-08-20 11:17:52Z znek $

include ../common.make

WOBUNDLE_NAME = AddressUI

AddressUI_PRINCIPAL_CLASS = LSWAddressModule

AddressUI_OBJC_FILES = \
	LSWAddressModule.m		\
	LSWFullSearch.m		 	\
	LSWAddressViewer.m	 	\
	LSWAddressEditor.m	 	\
	LSWAddressEditor+Wizard.m	\
	LSWAddressPreferences.m   	\
	SkyWizardAddressViewer.m	\
	SkyBusinessCardGathering.m	\
	LSWFormLetterComponent.m	\
	SkyAddressesViewer.m            \
	SkyTelephoneViewer.m            \
	SkyTelephoneEditor.m            \
	SkyCompanyAttributesViewer.m    \
	SkyPersonalAttributesViewer.m   \
	SkyPersonalViewerConfig.m       \
	SkyAddressEditor.m	 	\
	SkyAddressSubEditor.m 		\
	SkyPhoneSubEditor.m		\
	SkyExtendedAttrsSubEditor.m	\
	SkyContactSubEditor.m		\
	SkyCategorySubEditor.m		\
	SkyCommentSubEditor.m		\
	SkyCompanyFlagSubEditor.m	\
	SkyContactImportUploadPage.m	\
	SkyContactImportPage.m		\
	SkyCompanySavedSearchPopUp.m	\
	OGoFormLetterAction.m		\
	OGoPrintCompanyList.m		\

AddressUI_LANGUAGES = English German

AddressUI_RESOURCE_FILES += \
	Defaults.plist                   \
	SkyCompanyAttributesViewer.plist \
	Version

-include GNUmakefile.preamble
include $(GNUSTEP_MAKEFILES)/wobundle.make
-include GNUmakefile.postamble
-include ../../fhsbundle.make
