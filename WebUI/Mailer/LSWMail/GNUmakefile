# $Id$

include ../common.make

WOBUNDLE_NAME = LSWMail

LSWMail_PRINCIPAL_CLASS = LSWMailModule

LSWMail_OBJC_FILES = \
        LSWMailModule.m			\
        LSWMailRenderPage.m		\
        LSWObjectHtmlMailPage.m		\
        LSWObjectTextMailPage.m		\
	LSWDeletedObjectViewer.m	\

LSWMail_COMPONENTS = \
        LSWMailHtmlRenderPage.wo	\
        LSWMailTextRenderPage.wo	\
        LSWObjectHtmlMailPage.wo	\
        LSWObjectTextMailPage.wo	\
        LSWDeletedObjectViewer.wo	\

LSWMail_LANGUAGES = English German 
LSWMail_LOCALIZED_RESOURCE_FILES = LSWMail.ccfg

LSWMail_RESOURCE_FILES += Version

LSWMail_DERIVED_RESOURCES = \
	German.lproj/LSWMail.ccfg	\

German.lproj/LSWMail.ccfg : English.lproj/LSWMail.ccfg
	echo "// generated from $(<), do not modify !" >$@
	cat $< >>$@

-include GNUmakefile.preamble
include $(GNUSTEP_MAKEFILES)/wobundle.make
-include GNUmakefile.postamble

before-all :: $(LSWMail_DERIVED_RESOURCES)

clean ::
	rm -f $(LSWMail_DERIVED_RESOURCES)
