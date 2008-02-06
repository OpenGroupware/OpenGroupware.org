# GNUstep makefile

include ../common.make

BUNDLE_NAME  = Tasks
LIBRARY_NAME = libZSTasks


libZSTasks_INTERFACE_VERSION=$(MAJOR_VERSION).$(MINOR_VERSION)
libZSTasks_INSTALL_DIR=$(OGO_SYSLIBDIR)
libZSTasks_VERSION=$(MAJOR_VERSION).$(MINOR_VERSION).$(SUBMINOR_VERSION)


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
	\
	SxTask+ZL.m		\
	SxTaskFolder+ZL.m	\

Tasks_RESOURCE_FILES += \
	bundle-info.plist	\
	Version			\
	product.plist

BUNDLE_INSTALL_DIR = $(ZIDESTORE_WEBUIDIR)

-include GNUmakefile.preamble
ifneq ($(FHS_INSTALL_ROOT),)
GNUSTEP_HEADERS=$(DESTDIR)$(FHS_INSTALL_ROOT)/include
endif
include $(GNUSTEP_MAKEFILES)/library.make
include $(GNUSTEP_MAKEFILES)/bundle.make
-include GNUmakefile.postamble
