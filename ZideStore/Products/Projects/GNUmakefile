# $Id$

include $(GNUSTEP_MAKEFILES)/common.make

BUNDLE_NAME = Projects

Projects_PRINCIPAL_CLASS = ProjectsProduct

Projects_OBJC_FILES = \
	Product.m		\
	SxProjectFolder.m	\
	SxProjectsFolder.m	\
	SxDocumentFolder.m	\
	SxDocument.m		\
	SxProjectNotesFolder.m	\
	SxNote.m		\
	\
	SxDocumentFolder+Perf.m	\

Projects_RESOURCE_FILES += 	\
	bundle-info.plist	\
	Version			\
	product.plist

-include GNUmakefile.preamble
include $(GNUSTEP_MAKEFILES)/bundle.make
-include GNUmakefile.postamble
