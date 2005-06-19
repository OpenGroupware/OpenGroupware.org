# global makefile for OGo

-include ./config.make

ifeq ($(GNUSTEP_MAKEFILES),)

$(warning Note: Your $(GNUSTEP_MAKEFILES) environment variable is empty!)
$(warning       Either use ./configure or source GNUstep.sh.)

else

include $(GNUSTEP_MAKEFILES)/common.make

SUBPROJECTS += \
	Logic		\
	Database	\
	DocumentAPI	\
	WebUI		\
	Tools		\
	XmlRpcAPI	\
	ZideStore

ifneq ($(libpisock),no)
SUBPROJECTS += PDA
endif

-include GNUmakefile.preamble
include $(GNUSTEP_MAKEFILES)/aggregate.make
-include GNUmakefile.postamble

endif


distclean ::
	if test -f config.make; then rm config.make; fi
	if test -d .makeenv;    then rm -r .makeenv; fi
	rm -f config-*.log install-*.log
