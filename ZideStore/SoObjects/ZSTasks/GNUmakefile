# $Id: GNUmakefile 1 2004-08-20 11:17:52Z znek $

include ../common.make

BUNDLE_NAME  = Tasks
LIBRARY_NAME = libZSTasks

Tasks_PRINCIPAL_CLASS = TasksProduct
Tasks_OBJC_FILES      = Product.m

libZSTasks_OBJC_FILES = \
	SxTask.m		\
	SxTaskStatus.m		\
	SxTaskFolder.m		\
	SxTaskRenderer.m	\
	\
	SxDavTaskAction.m	\
	SxDavTaskCreate.m	\
	SxDavTaskChange.m	\

Tasks_RESOURCE_FILES += \
	bundle-info.plist	\
	Version			\
	product.plist

-include GNUmakefile.preamble
include $(GNUSTEP_MAKEFILES)/library.make
include $(GNUSTEP_MAKEFILES)/bundle.make
-include GNUmakefile.postamble
-include ../../fhsbundle.make
