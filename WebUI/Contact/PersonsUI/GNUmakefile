# GNUstep makefile

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
	EOQualifier+PersonUI.m		\

PersonsUI_RESOURCE_FILES += Defaults.plist Version

-include GNUmakefile.preamble
include $(GNUSTEP_MAKEFILES)/wobundle.make
-include GNUmakefile.postamble
-include ../../fhsbundle.make
