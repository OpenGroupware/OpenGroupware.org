# GNUstep makefile

-include ../../config.make
include ../common.make
include ./Version

LIBRARY_NAME = libOGoDocuments

libOGoDocuments_PCH_FILE = common.h

libOGoDocuments_HEADER_FILES = \
	SkyDocuments.h			\
	SkyContext.h			\
	SkyDocument.h			\
	SkyDocumentType.h		\
	SkyDocumentFileManager.h	\
	SkyDocumentManager.h		\
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
	NGCustomFileManager+Docs.m	\
	NGLocalFileManager.m		\
	NGLocalFileDocument+DOM.m	\
	NGLocalFileDocument.m		\
	NGLocalFileDataSource.m		\
	NGLocalFileGlobalID.m		\
	SkyDocument+XmlRpcCoding.m	\
	\
	LSCommandContext+Doc.m		\
	SkyDocumentManagerImp.m		\

libOGoDocuments_HEADER_FILES_DIR         = .
libOGoDocuments_HEADER_FILES_INSTALL_DIR = /OGoDocuments
FHS_HEADER_DIRS = OGoDocuments

libOGoDocuments_SOVERSION=$(MAJOR_VERSION).$(MINOR_VERSION)
libOGoDocuments_VERSION=$(MAJOR_VERSION).$(MINOR_VERSION).$(SUBMINOR_VERSION)

-include GNUmakefile.preamble
include $(GNUSTEP_MAKEFILES)/library.make
-include GNUmakefile.postamble
-include ../fhslib.make
