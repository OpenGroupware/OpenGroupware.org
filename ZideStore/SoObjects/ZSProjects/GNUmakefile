# GNUstep makefile

include ../common.make

BUNDLE_NAME  = Projects
LIBRARY_NAME = libZSProjects

Projects_PRINCIPAL_CLASS = ProjectsProduct
Projects_OBJC_FILES      = Product.m

libZSProjects_SOVERSION=$(MAJOR_VERSION).$(MINOR_VERSION)
libZSProjects_VERSION=$(MAJOR_VERSION).$(MINOR_VERSION).$(SUBMINOR_VERSION)

libZSProjects_OBJC_FILES = \
	SxProjectFolder.m	\
	SxProjectsFolder.m	\
	SxDocumentFolder.m	\
	SxDocument.m		\
	SxProjectNotesFolder.m	\
	SxNote.m		\
	SxTmpDocument.m		\
	\
	SxProjectNotesRSS.m	\
	\
	SxDocumentFolder+Perf.m	\

Projects_RESOURCE_FILES += 	\
	bundle-info.plist	\
	Version			\
	product.plist

-include GNUmakefile.preamble
include $(GNUSTEP_MAKEFILES)/library.make
include $(GNUSTEP_MAKEFILES)/bundle.make
-include GNUmakefile.postamble
-include ../../fhsbundle.make
-include ../../fhslib.make
