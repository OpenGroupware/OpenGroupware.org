# GNUstep makefile

include ../../config.make
include ../common.make

COMMAND_BUNDLE = LSNews

LSNews_PCH_FILE = common.h

LSNews_OBJC_FILES = \
	LSNewNewsArticleCommand.m     \
	LSDeleteNewsArticleCommand.m  \
	LSSetNewsArticleCommand.m     \
	LSGetRelatedArticlesCommand.m \
	LSSetRelatedArticlesCommand.m \

LSNews_RESOURCE_FILES += Version

include ../commandbundle.make
