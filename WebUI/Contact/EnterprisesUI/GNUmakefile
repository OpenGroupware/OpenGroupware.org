# $Id: GNUmakefile 1 2004-08-20 11:17:52Z znek $

include ../common.make

WOBUNDLE_NAME = EnterprisesUI

EnterprisesUI_PRINCIPAL_CLASS = SkyEnterprisesModule

EnterprisesUI_OBJC_FILES = 			\
	SkyEnterprisesModule.m			\
	LSWEnterpriseAdvancedSearch.m		\
	LSWEnterprises.m			\
	LSWEnterpriseMailPage.m			\
	LSWEnterpriseSearchPage.m		\
	SkyWizardEnterpriseViewer.m		\
	SkyEnterpriseProjectList.m      	\
	SkyEnterpriseList.m			\
	SkyEnterpriseEditor.m			\
	SkyEnterpriseAttributesEditor.m		\
	SkyEnterpriseViewer.m			\
	SkyAssignPersonSubEditor.m		\
	SkyAssignPersonEditor.m			\

EnterprisesUI_COMPONENTS = \
	LSWEnterpriseAdvancedSearch.wo		\
	LSWEnterprises.wo			\
	LSWEnterpriseHtmlMailPage.wo		\
	LSWEnterpriseTextMailPage.wo		\
	LSWEnterpriseSearchPage.wo		\
	SkyWizardEnterpriseViewer.wo		\
	SkyEnterpriseProjectList.wo     	\
	SkyEnterpriseList.wo			\
	SkyEnterpriseEditor.wo			\
	SkyEnterpriseAttributesEditor.wo	\
	SkyEnterpriseViewer.wo			\
	SkyAssignPersonSubEditor.wo		\

EnterprisesUI_RESOURCE_FILES += \
	SkyAssignPersonEditor.wox

-include GNUmakefile.preamble
include $(GNUSTEP_MAKEFILES)/wobundle.make
-include GNUmakefile.postamble
-include ../../fhsbundle.make
