# GNUstep makefile

include $(GNUSTEP_MAKEFILES)/common.make

WOBUNDLE_NAME        = MyNews
WOBUNDLE_EXTENSION   = .lso
WOBUNDLE_INSTALL_DIR = $(GNUSTEP_USER_ROOT)/Library/OpenGroupware.org

# the source files for the bundle
MyNews_OBJC_FILES = \
	MyNewsPage.m

# the components in this bundle
MyNews_COMPONENTS = \
	MyNewsPage.wo

# let the gnu-make stuff do it's work
-include GNUmakefile.preamble
include $(GNUSTEP_MAKEFILES)/wobundle.make
-include GNUmakefile.postamble
include fhsbundle.make
