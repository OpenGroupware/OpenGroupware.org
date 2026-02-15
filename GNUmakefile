# global makefile for OGo

-include ./config.make

ifeq ($(wildcard $(GNUSTEP_MAKEFILES)/common.make),)

$(warning Note: GNUstep makefiles not found.)
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

-include GNUmakefile.preamble
include $(GNUSTEP_MAKEFILES)/aggregate.make
-include GNUmakefile.postamble

endif


# Docker local build

DOCKER_TAG  = ogo-local-dev:latest
DOCKER_FILE = docker/OGoLocalBuild.dockerfile

docker-build:
	docker build -t $(DOCKER_TAG) -f $(DOCKER_FILE) .

docker-run:
	docker compose up

docker-clean:
	docker rmi $(DOCKER_TAG) 2>/dev/null || true


distclean ::
	if test -f config.make; then rm config.make; fi
	if test -d .makeenv;    then rm -r .makeenv; fi
	rm -f config-*.log install-*.log
