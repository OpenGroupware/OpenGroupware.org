# GNUstep makefile

include $(GNUSTEP_MAKEFILES)/common.make

LIBRARY_NAME = libSOGoUI

libSOGoUI_HEADER_FILES_DIR         = .
libSOGoUI_HEADER_FILES_INSTALL_DIR = /SOGoUI

libSOGoUI_HEADER_FILES +=	\
	UIxComponent.h		\
	SOGoDateFormatter.h	\
	SOGoAptFormatter.h	\
	SOGoJSStringFormatter.h	\

libSOGoUI_OBJC_FILES +=		\
	UIxComponent.m		\
	SOGoDateFormatter.m	\
	SOGoAptFormatter.m	\
	SOGoJSStringFormatter.m \

# make

-include GNUmakefile.preamble
include $(GNUSTEP_MAKEFILES)/library.make
-include GNUmakefile.postamble
