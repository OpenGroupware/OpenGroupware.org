# GNUstep makefile

-include ../../config.make
include $(GNUSTEP_MAKEFILES)/common.make
-include ../../Version
-include ./Version

WOBUNDLE_NAME = OGoProjectForms

OGoProjectForms_PRINCIPAL_CLASS = SkyP4FormsModule

OGoProjectForms_OBJC_FILES = \
	SkyP4FormsModule.m		\
	SkyFormComponent+P4.m		\
	SkyP4AppFormComponent.m		\
	SkyP4ProjectResourceManager.m	\
	SkyP4ViewerFormComponent.m	\
	SkyJSProcess.m			\
	SkyP4FormPage.m			\
	ODR_sky_selectpopup.m		\
	ODR_sky_selectproject.m		\
	ODR_sky_selectaccount.m		\
	ODR_sky_selectenterprise.m	\

OGoProjectForms_COMPONENTS = \
	SkyP4FormPage.wo		\

# resources

OGoProjectForms_RESOURCE_FILES += Version

-include GNUmakefile.preamble
include $(GNUSTEP_MAKEFILES)/wobundle.make
-include GNUmakefile.postamble
