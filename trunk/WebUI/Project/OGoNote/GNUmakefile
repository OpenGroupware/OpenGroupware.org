# $Id: GNUmakefile 1 2004-08-20 11:17:52Z znek $

include ../common.make

WOBUNDLE_NAME = OGoNote

OGoNote_PRINCIPAL_CLASS = SkyNoteModule

OGoNote_OBJC_FILES = \
	SkyNoteModule.m	\
	SkyNoteList.m	\
	SkyNoteEditor.m	\

OGoNote_RESOURCE_FILES += \
	Version		\

-include GNUmakefile.preamble
include $(GNUSTEP_MAKEFILES)/wobundle.make
-include GNUmakefile.postamble
-include ../../fhsbundle.make
