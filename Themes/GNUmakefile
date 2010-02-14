# GNUstep makefile

include ../config.make
include $(GNUSTEP_MAKEFILES)/common.make

WEBSERVER_RESOURCE_DIRS = WebServerResources/*lproj

all ::

install ::
	mkdir -p $(OGO_SHARED_WWW)
	cp -rf $(WEBSERVER_RESOURCE_DIRS) $(OGO_SHARED_WWW)

clean ::

distclean :: clean

uninstall ::
