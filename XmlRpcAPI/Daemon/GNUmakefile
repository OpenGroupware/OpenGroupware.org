# $Id$

include $(GNUSTEP_MAKEFILES)/common.make
include ./Version

XMLRPCD_NAME = ogo-xmlrpcd-1.0a

TOOL_NAME = $(XMLRPCD_NAME)

$(XMLRPCD_NAME)_OBJC_FILES = \
	xmlrpcd.m			\
	Application.m			\
	XmlRpcApplication.m		\
	Session.m			\
	\
	NGFileManagerZipTool.m		\
	NGFileManagerZipTool+Project.m	\
	NGUnixTool.m			\
	\
	EOControl+XmlRpcDirectAction.m	\
	NSObject+EKVC.m			\

$(XMLRPCD_NAME)_SUBPROJECTS = \
	Actions.subproj		\
	XmlRpcCoding.subproj	\

-include GNUmakefile.preamble
include $(GNUSTEP_MAKEFILES)/tool.make
-include GNUmakefile.postamble
-include fhs.make
