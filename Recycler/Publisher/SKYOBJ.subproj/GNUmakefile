# $Id$

include $(GNUSTEP_MAKEFILES)/common.make

SUBPROJECT_NAME = SKYOBJ

ADDITIONAL_CPPFLAGS += -pipe -Wall

SKYOBJ_OBJC_FILES += \
	SkyPubSKYOBJ.m		\
	_condition.m		\
	_includetext.m		\
	_insert_anchor.m	\
	_insert_meta.m		\
	_insert_template.m	\
	_insert_var.m		\
	_insert_var_body.m	\
	_list.m			\
	_micronav.m		\
	_document.m		\

ADDITIONAL_INCLUDE_DIRS += \
	-I..		\
	-I../..		\

-include GNUmakefile.preamble
include $(GNUSTEP_MAKEFILES)/subproject.make
-include GNUmakefile.postamble
