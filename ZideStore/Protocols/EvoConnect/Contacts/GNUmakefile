# $Id: GNUmakefile 1 2004-08-20 11:17:52Z znek $

include $(GNUSTEP_MAKEFILES)/common.make

SUBPROJECT_NAME = Contacts

Contacts_OBJC_FILES = \
	SxEvoContactQueryInfo.m		\
	SxEvoContactRenderer.m		\
	SxEvoFullContactParser.m	\
	SxEvoEnterpriseRenderer.m	\
	SxEvoFullEnterpriseParser.m	\
	SxEvoGroupRenderer.m		\
	SxEvoPersonRenderer.m		\
	SxEvoFullPersonParser.m		\
	\
	SxAddressFolder+Evo.m		\

ADDITIONAL_INCLUDE_DIRS += \
	-I. -I.. -I../..			\
	-I../../Products/Contacts		\
	-I../../Products/Contacts/Groups	\
	-I../../Products/Contacts/Companies	\
	-I../../Frontend		\
	-I../../Backend			\

include $(GNUSTEP_MAKEFILES)/subproject.make
