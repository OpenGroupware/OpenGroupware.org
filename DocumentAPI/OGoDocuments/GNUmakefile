# $Id: GNUmakefile 1 2004-08-20 11:17:52Z znek $

include ../common.make

LIBRARY_NAME = libOGoDocuments

libOGoDocuments_HEADER_FILES = \
	SkyDocuments.h			\
	SkyContext.h			\
	SkyDocument.h			\
	SkyDocumentType.h		\
	SkyDocumentFileManager.h	\
	SkyDocumentManager.h		\
	SkyDocument+JS.h		\
	NGLocalFileManager.h		\
	NGLocalFileDocument.h		\
	NGLocalFileDataSource.h		\
	NGLocalFileGlobalID.h		\
	\
	LSCommandContext+Doc.h		\

libOGoDocuments_OBJC_FILES = \
	SkyDocument.m			\
	SkyDocumentType.m		\
	SkyURLHandle.m			\
	SkyDocument+JS.m		\
	NGCustomFileManager+Docs.m	\
	NGLocalFileManager.m		\
	NGLocalFileDocument+DOM.m	\
	NGLocalFileDocument.m		\
	NGLocalFileDataSource.m		\
	NGLocalFileGlobalID.m		\
	NGFileManager+DocJS.m		\
	SkyDocument+XmlRpcCoding.m	\
	\
	LSCommandContext+Doc.m		\
	SkyDocumentManagerImp.m		\
	SkyDocumentManagerImp+JS.m	\

libOGoDocuments_HEADER_FILES_DIR         = .
libOGoDocuments_HEADER_FILES_INSTALL_DIR = /OGoDocuments
FHS_HEADER_DIRS = OGoDocuments

libOGoDocuments_SOVERSION=$(MAJOR_VERSION).$(MINOR_VERSION)
libOGoDocuments_VERSION=$(MAJOR_VERSION).$(MINOR_VERSION).$(SUBMINOR_VERSION)

-include GNUmakefile.preamble
include $(GNUSTEP_MAKEFILES)/library.make
-include GNUmakefile.postamble
-include ../fhslib.make
