#$Id$
# Localized Resources

OGoSchedulerViews_LANGUAGES = \
	English German		\
	English_blue German_blue\
	English_orange

OGoSchedulerViews_LOCALIZED_RESOURCE_FILES = 	\
	OGoSchedulerViews.ccfg			\

OGoSchedulerViews_DERIVED_RESOURCES =		\
	German.lproj/OGoSchedulerViews.ccfg		\

German.lproj/OGoSchedulerViews.ccfg : English.lproj/OGoSchedulerViews.ccfg
	echo "// do not modify, automatically created!" > $@
	cat $< >> $@

German_blue.lproj/OGoSchedulerViews.ccfg : English_blue.lproj/OGoSchedulerViews.ccfg
	echo "// do not modify, automatically created!" > $@
	cat $< >> $@
