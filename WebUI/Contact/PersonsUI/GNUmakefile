# $Id$

include ../common.make

WOBUNDLE_NAME = PersonsUI

PersonsUI_PRINCIPAL_CLASS = SkyPersonsModule

PersonsUI_OBJC_FILES += \
	SkyPersonsModule.m              \
	LSWAddressFunctions.m           \
	LSWPersons.m                    \
	LSWPersonAdvancedSearch.m       \
	LSWPersonMailPage.m             \
	SkyWizardPersonViewer.m         \
	SkyPersonSelectPopUp.m		\
	SkyPersonProjectList.m          \
	SkyPersonEnterpriseSetViewer.m  \
	SkyPersonList.m                 \
        SkyPersonSearchPanel.m          \
	SkyPersonEditor.m		\
	SkyPersonAttributesEditor.m	\
	SkyPersonViewer.m		\
	SkyPersonLDAPViewer.m		\
	SkyPersonWizard.m		\
	OGoPersonLinkEditor.m		\

PersonsUI_COMPONENTS += \
	LSWPersons.wo                   \
	LSWPersonAdvancedSearch.wo      \
	LSWPersonHtmlMailPage.wo        \
	LSWPersonTextMailPage.wo        \
	SkyWizardPersonViewer.wo        \
	SkyPersonSelectPopUp.wo         \
	SkyPersonEnterpriseSetViewer.wo \
	SkyPersonList.wo                \
	SkyPersonEditor.wo		\
	SkyPersonAttributesEditor.wo	\
	SkyPersonLDAPViewer.wo		\

PersonsUI_RESOURCE_FILES += \
        SkyPersonSearchPanel.wox	\
	OGoPersonLinkEditor.wox

ifeq ($(wox),yes)

PersonsUI_RESOURCE_FILES += \
	SkyPersonViewer.wox	\
	SkyPersonProjectList.wox
else

PersonsUI_COMPONENTS += \
	SkyPersonViewer.wo	\
	SkyPersonProjectList.wo

endif

PersonsUI_RESOURCE_FILES += Defaults.plist Version

-include GNUmakefile.preamble
include $(GNUSTEP_MAKEFILES)/wobundle.make
-include GNUmakefile.postamble
