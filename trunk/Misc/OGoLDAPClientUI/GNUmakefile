# $Id$

include $(GNUSTEP_MAKEFILES)/common.make

WOBUNDLE_NAME        = OGoLDAPClientUI
WOBUNDLE_EXTENSION   = .lso
WOBUNDLE_INSTALL_DIR = $(GNUSTEP_INSTALLATION_DIR)/Library/OpenGroupware.org

OGoLDAPClientUI_PRINCIPAL_CLASS = LdapViewerModule

OGoLDAPClientUI_OBJC_FILES = 		\
	AddressList.m			\
	LdapViewerPanel.m		\
	LdapViewerModule.m		\
	LdapPersonEditor.m		\
	LdapPersonViewer.m		\
					\
	LdapPersonDocument.m		\
	LdapPersonDataSource.m		\
	SkyLDAPDataSource.m		\
	SkyLDAPDocument.m		\
	SkyLDAPFileManager.m		\

OGoLDAPClientUI_COMPONENTS = 		\
	AddressList.wo			\
	LdapViewerPanel.wo		\
	LdapPersonEditor.wo		\
	LdapPersonViewer.wo		\

OGoLDAPClientUI_RESOURCE_FILES +=		\
	Defaults.plist			\

#OGoLDAPClientUI_LOCALIZED_RESOURCE_FILES +=	\
#	OGoLDAPClientUI.strings		\

OGoLDAPClientUI_LANGUAGES = English German

OGoLDAPClientUI_BUNDLE_LIBS +=		\
	-lWEExtensions			\
	-lNGExtensions			\
	-lOGoDocuments			\
	-lNGLdap -lldap -llber

#		?
#OGoLDAPClientUI_LIBRARIES_DEPEND_UPON += \
#	-lSkyDocuments			\

-include GNUmakefile.preamble
include $(GNUSTEP_MAKEFILES)/wobundle.make
-include GNUmakefile.postamble
