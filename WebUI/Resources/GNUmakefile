# compilation settings

-include ../../config.make
include $(GNUSTEP_MAKEFILES)/common.make

RESOURCES_INSTALLATION_DIR = \
		$(GNUSTEP_INSTALLATION_DIR)/Resources

Skyrix_LANGUAGE_Projects = \
	English.lproj 		\
	German.lproj		\
	Danish.lproj		\
	Dutch.lproj		\
	French.lproj		\
	Italian.lproj		\
	Spanish.lproj		\
	Portuguese.lproj	\
	Polish.lproj		\
	ptBR.lproj		\
	Swedish.lproj		\

install :: ${RESOURCES_INSTALLATION_DIR}
	cp -RPp ${Skyrix_LANGUAGE_Projects} ${RESOURCES_INSTALLATION_DIR}


${RESOURCES_INSTALLATION_DIR}	 ::
	if (test ! -d ${RESOURCES_INSTALLATION_DIR});		\
		then mkdir ${RESOURCES_INSTALLATION_DIR}; fi;	\
