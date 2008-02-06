# GNUstep makefiles

include ../common.make

WOBUNDLE_NAME = OGoDocInlineViewers

OGoDocInlineViewers_PRINCIPAL_CLASS = SkyDocInlineViewersModule

OGoDocInlineViewers_OBJC_FILES += \
	SkyDocInlineViewersModule.m	\
	SkyDocEmbedInlineViewer.m	\
	SkyDocImageInlineViewer.m	\
	\
	OGoDocPartViewer.m		\
	OGoDocAccessViewer.m		\
	OGoDocAttrsViewer.m		\
	OGoDocContentsViewer.m		\
	OGoDocLogsViewer.m		\
	OGoDocVersionsViewer.m		\

OGoDocInlineViewers_RESOURCE_FILES += Defaults.plist Version

-include GNUmakefile.preamble
include $(GNUSTEP_MAKEFILES)/wobundle.make
-include GNUmakefile.postamble
