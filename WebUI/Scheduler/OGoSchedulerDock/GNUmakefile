# $Id$

include ../common.make

WOBUNDLE_NAME = OGoSchedulerDock

OGoSchedulerDock_PRINCIPAL_CLASS = SkySchedulerDockModule

OGoSchedulerDock_OBJC_FILES = \
	SkySchedulerDockModule.m	\
	SkySchedulerDockView.m		\

OGoSchedulerDock_COMPONENTS = SkySchedulerDockView.wo

-include SKYRIX.make
-include OGo.make

before-all :: $(OGoSchedulerDock_DERIVED_RESOURCES)

clean ::
	rm -f $(OGoSchedulerDock_DERIVED_RESOURCES)

-include GNUmakefile.preamble
include $(GNUSTEP_MAKEFILES)/wobundle.make
-include GNUmakefile.postamble
