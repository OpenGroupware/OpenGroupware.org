# GNUstep makefile

include $(GNUSTEP_MAKEFILES)/common.make

# the name for this webui bundle
WOBUNDLE_NAME        = HelloDB
# webui bundles must be of type .lsa
WOBUNDLE_EXTENSION   = .lso
# where all the bundles go on install
WOBUNDLE_INSTALL_DIR = $(GNUSTEP_USER_ROOT)/Library/OpenGroupware.org

# the source files for the bundle
HelloDB_OBJC_FILES = \
	HelloDB.m	\

# the components in this bundle
HelloDB_COMPONENTS = \
	HelloDB.wo	\

# other files we use in the bundle, the Defaults.plist is loaded automagically
HelloDB_RESOURCE_FILES = \
	Defaults.plist

# let the gnu-make stuff do it's work
-include GNUmakefile.preamble
include $(GNUSTEP_MAKEFILES)/wobundle.make
-include GNUmakefile.postamble
include fhsbundle.make
