# $Id: GNUmakefile 1 2004-08-20 11:17:52Z znek $

include ../common.make

WOBUNDLE_NAME = PropertiesUI

PropertiesUI_PRINCIPAL_CLASS = PropertiesUI

PropertiesUI_PCH_FILE = common.h

PropertiesUI_OBJC_FILES = \
	PropertiesUI.m			\
	SkyObjectPropertyViewer.m	\
	SkyObjectPropertyEditor.m

PropertiesUI_RESOURCE_FILES += Version

-include GNUmakefile.preamble
include $(GNUSTEP_MAKEFILES)/wobundle.make
-include GNUmakefile.postamble
-include ../../fhsbundle.make
