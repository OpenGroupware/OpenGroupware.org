# $Id: GNUmakefile 1 2004-08-20 11:17:52Z znek $

include ../common.make

WOBUNDLE_NAME = OGoMailInfo

OGoMailInfo_PRINCIPAL_CLASS = SkyMailInfoModule

OGoMailInfo_OBJC_FILES = 	\
	SkyMailInfoModule.m		\
	LSWMailsDockView.m		\
	LSWImapDockView.m		\
	LSWImapTextDockView.m		\
	SkyImapMailPopUp.m		\
	WODirectAction+SkyMailInfo.m	\

OGoMailInfo_COMPONENTS = \
	LSWMailsDockView.wo	 	\
	LSWImapDockView.wo		\
	LSWImapTextDockView.wo		\
	SkyImapMailPopUp.wo		\

-include OGo.make
-include SKYRIX.make

-include GNUmakefile.preamble
include $(GNUSTEP_MAKEFILES)/wobundle.make
-include GNUmakefile.postamble
-include ../../fhsbundle.make
