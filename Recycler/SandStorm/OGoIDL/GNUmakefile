# $Id$

include ../common.make

LIBRARY_NAME = libOGoIDL
TOOL_NAME    = ogoidl

libOGoIDL_SOVERSION=$(MAJOR_VERSION).$(MINOR_VERSION)
libOGoIDL_HEADER_FILES_DIR         = .
libOGoIDL_HEADER_FILES_INSTALL_DIR = /OGoIDL

libOGoIDL_HEADER_FILES = \
	SkyIDL.h			\
	\
	SkyIDLSaxBuilder.h		\
	SkyIDLTag.h			\
	\
	SkyIDLInterface.h		\
	SkyIDLImport.h			\
	SkyIDLMethod.h			\
	SkyIDLDocumentation.h		\
	SkyIDLSignature.h		\
	SkyIDLFault.h			\
	SkyIDLInput.h			\
	SkyIDLOutput.h			\
	SkyIDLExample.h			\
	SkyIDLThrow.h			\
	\
	SOAPWSDLEncoder.h		\
	\
	NGXmlRpcAction+Introspection.h	\

libOGoIDL_OBJC_FILES = \
	SkyIDLSaxBuilder.m		\
	SkyIDLTag.m			\
	\
	SkyIDLInterface.m		\
	SkyIDLImport.m			\
	SkyIDLMethod.m			\
	SkyIDLDocumentation.m		\
	SkyIDLSignature.m		\
	SkyIDLFault.m			\
	SkyIDLInput.m			\
	SkyIDLOutput.m			\
	SkyIDLExample.m			\
	SkyIDLThrow.m			\
	\
	SOAPWSDLEncoder.m		\
					\
	NGXmlRpcAction+Introspection.m	\

libOGoIDL_LIBRARIES_DEPEND_UPON += -lSaxObjC -lNGObjWeb

ogoidl_OBJC_FILES = skyidl.m

ogoidl_LIB_DIRS     += \
	-L../SaxObjC/$(GNUSTEP_OBJ_DIR) \
	-L../NGExtensions/$(GNUSTEP_OBJ_DIR) \
	-L./$(GNUSTEP_OBJ_DIR)

ADDITIONAL_TOOL_LIBS := -lSaxObjC -lSkyIDL

ADDITIONAL_INCLUDE_DIRS += -I.. -I../..

SYSTEM_LIB_DIR += -L/usr/local/lib -L/usr/lib

include $(GNUSTEP_MAKEFILES)/library.make

ifeq ($(tests),yes)
include $(GNUSTEP_MAKEFILES)/tool.make
endif
