# GNUstep makefile

-include ../../config.make

WEBSERVER_RESOURCES_INSTALLATION_DIR = \
		$(GNUSTEP_INSTALLATION_DIR)/WebServerResources

Skyrix_LANGUAGE_Projects = \
	English.lproj		\
	German.lproj		\
	Danish.lproj		\
	Italian.lproj		\
	Spanish.lproj		\
	Polish.lproj		\
	\
	English_blue.lproj	\
	German_blue.lproj	\
	English_kde.lproj	\
	English_OOo.lproj	\
	German_OOo.lproj	\
	English_orange.lproj	\
	German_orange.lproj

install :: ${WEBSERVER_RESOURCES_INSTALLATION_DIR}
	-cp -RPp ${Skyrix_LANGUAGE_Projects} ${WEBSERVER_RESOURCES_INSTALLATION_DIR}

${WEBSERVER_RESOURCES_INSTALLATION_DIR}	::
	if (test ! -d ${WEBSERVER_RESOURCES_INSTALLATION_DIR});		\
		then mkdir ${WEBSERVER_RESOURCES_INSTALLATION_DIR}; fi;	\

