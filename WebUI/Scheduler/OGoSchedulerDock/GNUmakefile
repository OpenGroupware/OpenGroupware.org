# $Id: GNUmakefile 1 2004-08-20 11:17:52Z znek $

include ../common.make

WOBUNDLE_NAME = OGoSchedulerDock

OGoSchedulerDock_PRINCIPAL_CLASS = SkySchedulerDockModule

OGoSchedulerDock_OBJC_FILES = \
	SkySchedulerDockModule.m	\
	SkySchedulerDockView.m		\

OGoSchedulerDock_COMPONENTS = SkySchedulerDockView.wo

-include SKYRIX.make
-include OGo.make

-include GNUmakefile.preamble
include $(GNUSTEP_MAKEFILES)/wobundle.make
-include GNUmakefile.postamble
-include ../../fhsbundle.make
