# $Id: GNUmakefile 1 2004-08-20 11:17:52Z znek $

include ../common.make

BUNDLE_NAME = Tasks

Tasks_PRINCIPAL_CLASS = TasksProduct

Tasks_OBJC_FILES = \
	Product.m		\
	SxTask.m		\
	SxTaskStatus.m		\
	SxTaskFolder.m		\
	SxTaskRenderer.m	\
	\
	SxDavTaskAction.m	\
	SxDavTaskCreate.m	\
	SxDavTaskChange.m	\

Tasks_BUNDLE_LIBS += -lNGObjWeb

Tasks_RESOURCE_FILES += \
	bundle-info.plist	\
	Version			\
	product.plist

-include GNUmakefile.preamble
include $(GNUSTEP_MAKEFILES)/bundle.make
-include GNUmakefile.postamble
