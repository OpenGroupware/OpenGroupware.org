# GNUstep makefile

include $(GNUSTEP_MAKEFILES)/common.make

# the name for this webui bundle
WOBUNDLE_NAME        = HelloWorld
# webui bundles must be of type .lsa
WOBUNDLE_EXTENSION   = .lso
# where all the bundles go on install
WOBUNDLE_INSTALL_DIR = $(GNUSTEP_USER_ROOT)/Library/OpenGroupware.org

# the source files for the bundle
HelloWorld_OBJC_FILES = \
	HelloWorld.m	\

# the components in this bundle
HelloWorld_COMPONENTS = \
	HelloWorld.wo	\

# let the gnu-make stuff do it's work
-include GNUmakefile.preamble
include $(GNUSTEP_MAKEFILES)/wobundle.make
-include GNUmakefile.postamble
include fhsbundle.make
