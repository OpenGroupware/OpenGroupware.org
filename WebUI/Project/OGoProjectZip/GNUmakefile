# GNUstep makefile

include ../common.make

WOBUNDLE_NAME        = OGoProjectZip

OGoProjectZip_PRINCIPAL_CLASS = SkyP4ZipModule

OGoProjectZip_OBJC_FILES = \
	SkyP4ZipModule.m		\
	SkyP4ZipPanel.m			\
	SkyP4UnzipPanel.m		\
	SkyDocZipInlineViewer.m		\
	SkyDocTarInlineViewer.m		\
	NGFileManagerZipTool.m		\
	NGFileManagerTarTool.m		\

OGoProjectZip_COMPONENTS = \
	SkyP4ZipPanel.wo		\
	SkyP4UnzipPanel.wo		\
	SkyDocZipInlineViewer.wo	\
	SkyDocTarInlineViewer.wo	\

# resources

OGoProjectZip_RESOURCE_FILES += Defaults.plist Version

OGoProjectZip_LANGUAGES = English German

-include GNUmakefile.preamble
include $(GNUSTEP_MAKEFILES)/wobundle.make
-include GNUmakefile.postamble
