# $Id$

include ../common.make

WOBUNDLE_NAME = OGoNote

OGoNote_PRINCIPAL_CLASS = SkyNoteModule

OGoNote_OBJC_FILES = \
	SkyNoteModule.m	\
	SkyNoteList.m	\
	SkyNoteEditor.m	\

OGoNote_COMPONENTS = \
	SkyNoteEditor.wo \

OGoNote_RESOURCE_FILES += \
	Version		\
	SkyNoteList.wox	\

-include GNUmakefile.preamble
include $(GNUSTEP_MAKEFILES)/wobundle.make
-include GNUmakefile.postamble
