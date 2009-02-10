# GNUstep makefile

include ../config.make
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
	ogo-qsearch-persons

TOOL_NAME += \
	ogo-qsearch-tasks

TOOL_NAME += \
	ogo-qsearch-enterprises

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

skyaptnotify_OBJC_FILES            = skyaptnotify.m
skyaptnotify_INSTALL_DIR           = $(OGO_TOOLS)
sky_install_sieve_OBJC_FILES       = sky_install_sieve.m
sky_install_sieve_INSTALL_DIR      = $(OGO_TOOLS)
sky_send_bulk_messages_OBJC_FILES  = sky_send_bulk_messages.m
sky_send_bulk_messages_INSTALL_DIR = $(OGO_TOOLS)

ogo-jobs-export_OBJC_FILES         = ogo-jobs-export.m
ogo-jobs-export_INSTALL_DIR = $(OGO_TOOLS)

ogo-qsearch-persons_OBJC_FILES     = ogo-qsearch-persons.m
ogo-qsearch-persons_INSTALL_DIR = $(OGO_TOOLS)
ogo-qsearch-tasks_OBJC_FILES       = ogo-qsearch-tasks.m
ogo-qsearch-tasks_INSTALL_DIR = $(OGO_TOOLS)
ogo-qsearch-enterprises_OBJC_FILES = ogo-qsearch-enterprises.m
ogo-qsearch-enterprises_INSTALL_DIR = $(OGO_TOOLS)

ogo-account-list_OBJC_FILES        = SkyTool.m SkyGetLoginNames.m
ogo-account-list_INSTALL_DIR = $(OGO_TOOLS)
ogo-account-add_OBJC_FILES         = SkyTool.m SkyAddAccount.m
ogo-account-add_INSTALL_DIR = $(OGO_TOOLS)
ogo-account-del_OBJC_FILES         = SkyTool.m SkyDelAccount.m
ogo-account-del_INSTALL_DIR = $(OGO_TOOLS)

ogo-project-export_OBJC_FILES      = ogo-project-export.m NGUnixTool.m
ogo-project-export_INSTALL_DIR = $(OGO_TOOLS)
ogo-project-import_OBJC_FILES      = ogo-project-import.m NGUnixTool.m
ogo-project-import_INSTALL_DIR = $(OGO_TOOLS)
ogo-project-list_OBJC_FILES        = ogo-project-list.m
ogo-project-list_INSTALL_DIR = $(OGO_TOOLS)

ogo-runcmd_OBJC_FILES              = ogo-runcmd.m
ogo-runcmd_INSTALL_DIR = $(OGO_TOOLS)
ogo-defaults_OBJC_FILES            = ogo-defaults.m
ogo-defaults_INSTALL_DIR = $(OGO_TOOLS)

ogo-acl-list_OBJC_FILES	           = ogo-list-acls.m
ogo-acl-list_INSTALL_DIR = $(OGO_TOOLS)
ogo-check-permission_OBJC_FILES    = ogo-check-permission.m
ogo-check-permission_INSTALL_DIR = $(OGO_TOOLS)
ogo-check-aptconflicts_OBJC_FILES  = ogo-check-aptconflicts.m
ogo-check-aptconflicts_INSTALL_DIR = $(OGO_TOOLS)
ogo-prop-list_OBJC_FILES           = ogo-prop-list.m
ogo-prop-list_INSTALL_DIR = $(OGO_TOOLS)
ogo-prop-set_OBJC_FILES            = ogo-prop-set.m
ogo-prop-set_INSTALL_DIR = $(OGO_TOOLS)

ogo-instfilter-procmail_OBJC_FILES = ogo-instfilter-procmail.m
ogo-instfilter-procmail_INSTALL_DIR = $(OGO_TOOLS)

ogo-vcard-get_OBJC_FILES           = ogo-vcard-get.m
ogo-vcard-get_INSTALL_DIR = $(OGO_TOOLS)
ogo-vcard-put_OBJC_FILES           = ogo-vcard-put.m
ogo-vcard-put_INSTALL_DIR = $(OGO_TOOLS)

-include GNUmakefile.preamble
include $(GNUSTEP_MAKEFILES)/tool.make
-include GNUmakefile.postamble
