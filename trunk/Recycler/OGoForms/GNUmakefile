# GNUstep makefile

-include ../../config.make
include $(GNUSTEP_MAKEFILES)/common.make
-include ../../Version
include ./Version

LIBRARY_NAME = libOGoForms

libOGoForms_SOVERSION=$(MAJOR_VERSION).$(MINOR_VERSION)

libOGoForms_HEADER_FILES_DIR         = .
libOGoForms_HEADER_FILES_INSTALL_DIR = /OGoForms

libOGoForms_HEADER_FILES += \
	SkyComponentDefinition.h	\
	SkyFormNamespaces.h		\
	SkyForms.h			\
	SkyFormComponent.h		\
	WOComponent+Forms.h		\
	SkyJSSendMail.h			\

libOGoForms_OBJC_FILES += \
	SkyComponentDefinition.m	\
	SkyFormComponent.m		\
	WOComponent+Forms.m		\
	SkyNodeRendererSet.m		\
	ODR_sky_objectlink.m		\
	ODR_sky_tableview.m		\
	ODR_sky_tabview.m		\
	ODR_sky_collapsible.m		\
	ODR_sky_viewertitle.m		\
	ODR_sky_fieldset.m		\
	ODR_XHTML_html.m		\
	ODR_XHTML_body.m		\
	ODR_sky_objectsearch.m		\
	SkyJSSendMail.m			\
	WOComponent+JS.m		\

-include GNUmakefile.preamble
include $(GNUSTEP_MAKEFILES)/library.make
-include GNUmakefile.postamble
