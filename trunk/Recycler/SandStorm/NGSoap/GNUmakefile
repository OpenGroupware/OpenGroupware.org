# $Id$

include ../common.make

TOOL_NAME    = soapClientTest
LIBRARY_NAME = libNGSoap

libNGSoap_HEADER_FILES_DIR         = .
libNGSoap_HEADER_FILES_INSTALL_DIR = /NGSoap
libNGSoap_SOVERSION=$(MAJOR_VERSION).$(MINOR_VERSION)

libNGSoap_HEADER_FILES = \
	NGSoap.h			\
	NGSoapClient.h			\

libNGSoap_OBJC_FILES = \
	NGSoapClient.m			\
	SOAPBody+DocumentStyle.m	\

soapClientTest_OBJC_FILES = \
	soapClientTest.m		\

ADDITIONAL_TOOL_LIBS += -lFoundation	\
			-lSOAP		\
			-lNGObjWeb	\
			-lNGSoap	\
			-lXmlSchema     \

-include GNUmakefile.preamble
include $(GNUSTEP_MAKEFILES)/library.make
ifeq ($(with_tool),yes)
include $(GNUSTEP_MAKEFILES)/tool.make
endif
-include GNUmakefile.postamble
