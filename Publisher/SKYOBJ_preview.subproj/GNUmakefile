# $Id$

include $(GNUSTEP_MAKEFILES)/common.make

SUBPROJECT_NAME = PreviewSKYOBJ

ADDITIONAL_CPPFLAGS += -pipe -Wall

PreviewSKYOBJ_OBJC_FILES += \
	SkyPubPreviewSKYOBJ.m	\
	_list.m			\
	_insert_anchor.m	\
	_condition.m		\
	_insert_template.m	\

ADDITIONAL_INCLUDE_DIRS += \
	-I.		\
	-I..		\
	-I../..		\

-include GNUmakefile.preamble
include $(GNUSTEP_MAKEFILES)/subproject.make
-include GNUmakefile.postamble
