# $Id: GNUmakefile 1 2004-08-20 11:17:52Z znek $

include ../common.make

WOBUNDLE_NAME = LSWMail

LSWMail_PRINCIPAL_CLASS = LSWMailModule

LSWMail_OBJC_FILES = \
        LSWMailModule.m			\
        LSWMailRenderPage.m		\
        LSWObjectHtmlMailPage.m		\
        LSWObjectTextMailPage.m		\
	LSWDeletedObjectViewer.m	\

LSWMail_LANGUAGES = English German 

LSWMail_RESOURCE_FILES += Version

-include GNUmakefile.preamble
include $(GNUSTEP_MAKEFILES)/wobundle.make
-include GNUmakefile.postamble
-include ../../fhsbundle.make
