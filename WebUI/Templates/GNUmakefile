# GNUstep makefile

include ../../config.make
include $(GNUSTEP_MAKEFILES)/common.make
include ../Version

WOX_FILES = $(shell find . -name "*.wox")
TEMPLATE_DIRS = \
	AddressUI		\
	AdminUI			\
	BaseUI			\
	EnterprisesUI		\
	GroupsUI		\
	HelpUI			\
	JobUI			\
	LDAPAccounts		\
	LSWMail			\
	LSWProject		\
	LSWScheduler		\
	NewsUI			\
	OGoDocInlineViewers	\
	OGoMailEditor		\
	OGoMailFilter		\
	OGoMailInfo		\
	OGoMailViewers		\
	OGoNote			\
	OGoProject		\
	OGoProjectInfo		\
	OGoProjectZip		\
	OGoRecipientLists	\
	OGoResourceScheduler	\
	OGoScheduler		\
	OGoSchedulerDock	\
	OGoSchedulerViews	\
	OGoUIElements		\
	OGoWebMail		\
	PersonsUI		\
	PreferencesUI		\
	PropertiesUI		\
	RegUI			\
	RelatedLinksUI		\
	Themes			\
	ogo-webui-$(MAJOR_VERSION).$(MINOR_VERSION)		\


validate-wox ::
	@echo validating .wox templates ...
	for WOX_FILE in $(WOX_FILES); do \
	  xmllint --noout $${WOX_FILE};\
	done

all :: validate-wox

install ::
	mkdir -p $(OGO_SHARED_TEMPLATES) 
	for TEMPLATEDIR in $(TEMPLATE_DIRS); do \
		cp -rf $$TEMPLATEDIR $(OGO_SHARED_TEMPLATES)/; \
	done;

uninstall ::
	rm -rf $(OGO_SHARED_TEMPLATES)

clean ::

distclean ::

