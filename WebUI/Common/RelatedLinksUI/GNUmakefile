# $Id: GNUmakefile 1 2004-08-20 11:17:52Z znek $

include ../common.make

WOBUNDLE_NAME = RelatedLinksUI

RelatedLinksUI_PRINCIPAL_CLASS = RelatedLinksUI

RelatedLinksUI_PCH_FILE = common.h

RelatedLinksUI_OBJC_FILES = \
	RelatedLinksUI.m	\
	OGoObjectLinkList.m	\

RelatedLinksUI_RESOURCE_FILES += \
	Version			\
	Defaults.plist		\

-include GNUmakefile.preamble
include $(GNUSTEP_MAKEFILES)/wobundle.make
-include GNUmakefile.postamble
-include ../../fhsbundle.make
