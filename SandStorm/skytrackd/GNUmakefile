# $Id$

include ../common.make

TOOL_NAME  = skytrackd

# Sources

skytrackd_OBJC_FILES =			\
	skytrackd.m			\
	Application.m			\
                                        \
	SkyTrackAction.m		\
        SkyProjectFileManager+MD5.m     \
                                        \
        Channel.m			\
	ProjectChannel.m		\
        ChannelRegistry.m               \
                                        \
	Change.m			\
	Action.m			\
	ShellAction.m			\
	XmlRpcAction.m			\

-include GNUmakefile.preamble
include $(GNUSTEP_MAKEFILES)/tool.make
-include GNUmakefile.postamble
