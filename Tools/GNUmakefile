# $Id$

include $(GNUSTEP_MAKEFILES)/common.make

TOOL_NAME = \
	skyaptnotify		\
	skyprojectexporter	\
	skyprojectimporter	\
	skylistprojects		\
	sky_install_sieve	\
	sky_install_procmail	\
	sky_send_bulk_messages	\
	skyjobs2ical		\
	skyruncmd		\
	skydefaults		\
	skylistacls		\
	skycheckperm		\
				\
	sky_get_login_names	\
	sky_add_account 	\
	sky_del_account 	\

skyaptnotify_OBJC_FILES = skyaptnotify.m
skyjobs2ical_OBJC_FILES = skyjobs2ical.m

sky_get_login_names_OBJC_FILES = \
	SkyTool.m		\
	SkyGetLoginNames.m	\

sky_add_account_OBJC_FILES = \
	SkyTool.m		\
	SkyAddAccount.m		\

sky_del_account_OBJC_FILES = \
	SkyTool.m		\
	SkyDelAccount.m		\

skyprojectexporter_OBJC_FILES = skyprojectexporter.m NGUnixTool.m
skyprojectimporter_OBJC_FILES = skyprojectimporter.m NGUnixTool.m
skylistprojects_OBJC_FILES    = skylistprojects.m
skyruncmd_OBJC_FILES          = skyruncmd.m
skydefaults_OBJC_FILES        = skydefaults.m

skylistacls_OBJC_FILES	      = skylistacls.m
skycheckperm_OBJC_FILES	      = skycheckperm.m

sky_install_sieve_OBJC_FILES      = sky_install_sieve.m
sky_install_procmail_OBJC_FILES   = sky_install_procmail.m
sky_send_bulk_messages_OBJC_FILES = sky_send_bulk_messages.m

-include GNUmakefile.preamble
include $(GNUSTEP_MAKEFILES)/tool.make
-include GNUmakefile.postamble
-include fhs.make
