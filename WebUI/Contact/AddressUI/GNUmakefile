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

AddressUI_COMPONENTS = \
	LSWAddressViewer.wo		\
	LSWAddressEditor.wo		\
	LSWAddressPreferences.wo   	\
	SkyWizardAddressViewer.wo	\
	SkyBusinessCardGathering.wo	\
	SkyAddressesViewer.wo           \
	SkyTelephoneViewer.wo           \
	SkyTelephoneEditor.wo           \
	SkyCompanyAttributesViewer.wo   \
	SkyPersonalAttributesViewer.wo  \
	SkyPersonalViewerConfig.wo      \
	SkyAddressEditor.wo	 	\
	SkyAddressSubEditor.wo 		\
	SkyPhoneSubEditor.wo		\
	SkyContactSubEditor.wo		\
	SkyCategorySubEditor.wo		\
	SkyCommentSubEditor.wo		\
	SkyCompanyFlagSubEditor.wo	\
	SkyContactImportUploadPage.wo	\
	SkyContactImportPage.wo		\
	SkyCompanySavedSearchPopUp.wo	\

AddressUI_RESOURCE_FILES += \
	LSWFullSearch.wox		\
	SkyExtendedAttrsSubEditor.wox	\
	LSWFormLetterComponent.wox	\

AddressUI_LANGUAGES = English German

AddressUI_RESOURCE_FILES += \
	Defaults.plist                   \
	SkyCompanyAttributesViewer.plist \
	Version

-include GNUmakefile.preamble
include $(GNUSTEP_MAKEFILES)/wobundle.make
-include GNUmakefile.postamble
-include ../../fhsbundle.make
