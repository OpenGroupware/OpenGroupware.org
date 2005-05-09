# GNUstep makefile

-include ../config.make
include $(GNUSTEP_MAKEFILES)/common.make

SUBPROJECTS += \
	LSFoundation	\
	LSBase		\
	LSSearch	\

# Basic

SUBPROJECTS += \
	LSAddress	\
	LSPerson	\
	LSAccount	\
	LSTeam		\
	LSEnterprise	\
	LSNews		\

# more

SUBPROJECTS += \
	LSMail		\
	LSProject	\
	LSScheduler	\
	LSTasks		\
	LSDocuments	\

-include GNUmakefile.preamble
include $(GNUSTEP_MAKEFILES)/aggregate.make
-include GNUmakefile.postamble
