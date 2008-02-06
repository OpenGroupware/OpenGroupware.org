# $Id: GNUmakefile 1 2004-08-20 11:17:52Z znek $

include ../common.make

WOBUNDLE_NAME        = NewsUI
WOBUNDLE_EXTENSION   = .lso

NewsUI_PRINCIPAL_CLASS = LSWNewsModule

NewsUI_OBJC_FILES = \
	LSWNewsModule.m		\
	LSWNewsArticleViewer.m \
	LSWNewsArticleEditor.m \
	SkyNews.m              \
	SkyNewsPreferences.m   \

NewsUI_COMPONENTS = \
	LSWNewsArticleViewer.wo \
	LSWNewsArticleEditor.wo \
        SkyNews.wo              \
        SkyNewsPreferences.wo   \

NewsUI_RESOURCE_FILES += Defaults.plist Version

-include GNUmakefile.preamble
include $(GNUSTEP_MAKEFILES)/wobundle.make
-include GNUmakefile.postamble
