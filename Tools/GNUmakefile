# GNUstep makefile

-include ../config.make
include $(GNUSTEP_MAKEFILES)/common.make

TOOL_NAME += \
	skyaptnotify		\
	sky_install_sieve	\
	sky_send_bulk_messages

TOOL_NAME += \
	ogo-project-export	\
	ogo-project-import	\
	ogo-project-list

TOOL_NAME += \
	ogo-instfilter-procmail	\
	ogo-jobs-export		\
	ogo-runcmd		\
	ogo-defaults		\
	ogo-acl-list		\
	ogo-check-permission	\
	ogo-check-aptconflicts

TOOL_NAME += \
	ogo-account-list	\
	ogo-account-add		\
	ogo-account-del		\

TOOL_NAME += \
	ogo-vcard-get		\
	ogo-vcard-put		\

TOOL_NAME += \
	ogo-prop-list		\
	ogo-prop-set

skyaptnotify_OBJC_FILES           = skyaptnotify.m
sky_install_sieve_OBJC_FILES      = sky_install_sieve.m
sky_send_bulk_messages_OBJC_FILES = sky_send_bulk_messages.m

ogo-jobs-export_OBJC_FILES = ogo-jobs-export.m

ogo-account-list_OBJC_FILES   = SkyTool.m SkyGetLoginNames.m
ogo-account-add_OBJC_FILES    = SkyTool.m SkyAddAccount.m
ogo-account-del_OBJC_FILES    = SkyTool.m SkyDelAccount.m

ogo-project-export_OBJC_FILES = ogo-project-export.m NGUnixTool.m
ogo-project-import_OBJC_FILES = ogo-project-import.m NGUnixTool.m
ogo-project-list_OBJC_FILES   = ogo-project-list.m

ogo-runcmd_OBJC_FILES         = ogo-runcmd.m
ogo-defaults_OBJC_FILES       = ogo-defaults.m

ogo-acl-list_OBJC_FILES	          = ogo-list-acls.m
ogo-check-permission_OBJC_FILES   = ogo-check-permission.m
ogo-check-aptconflicts_OBJC_FILES = ogo-check-aptconflicts.m
ogo-prop-list_OBJC_FILES          = ogo-prop-list.m
ogo-prop-set_OBJC_FILES           = ogo-prop-set.m

ogo-instfilter-procmail_OBJC_FILES = ogo-instfilter-procmail.m

ogo-vcard-get_OBJC_FILES = ogo-vcard-get.m
ogo-vcard-put_OBJC_FILES = ogo-vcard-put.m

-include GNUmakefile.preamble
include $(GNUSTEP_MAKEFILES)/tool.make
-include GNUmakefile.postamble
-include fhs.make
