# $Id$

include $(GNUSTEP_MAKEFILES)/common.make

TOOL_NAME = ogocfggen

ogocfggen_OBJC_FILES = \
	OGoLogicTool.m	\
	ogocfggen.m	\

ADDITIONAL_INCLUDE_DIRS += -I. -I..

ADDITIONAL_LIB_DIRS += \
	-L../OGoConfigGen/$(GNUSTEP_OBJ_DIR)

ADDITIONAL_TOOL_LIBS += \
	-lOGoConfigGen	\
	-lLSFoundation	\
	-lNGExtensions

include $(GNUSTEP_MAKEFILES)/tool.make
