# $Id$

include ../common.make

WOBUNDLE_NAME = PropertiesUI

PropertiesUI_PRINCIPAL_CLASS = PropertiesUI

PropertiesUI_OBJC_FILES = \
	PropertiesUI.m			\
	SkyObjectPropertyViewer.m	\
	SkyObjectPropertyEditor.m

PropertiesUI_COMPONENTS = \
	SkyObjectPropertyViewer.wo	\
	SkyObjectPropertyEditor.wo

PropertiesUI_RESOURCE_FILES += Version

-include GNUmakefile.preamble
include $(GNUSTEP_MAKEFILES)/wobundle.make
-include GNUmakefile.postamble
