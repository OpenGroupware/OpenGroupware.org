# $Id$

OGoSchedulerDock_LANGUAGES = \
	English German	\
	English_orange	\
	English_blue	\
	English_kde	\
	English_OOo

# resources

OGoSchedulerDock_RESOURCE_FILES += Version

OGoSchedulerDock_DERIVED_RESOURCES += \
  SkySchedulerDockView.wo/German.lproj/SkySchedulerDockView.html     \
  SkySchedulerDockView.wo/German.lproj/SkySchedulerDockView.wod      \

# German

SkySchedulerDockView.wo/German.lproj/SkySchedulerDockView.html : SkySchedulerDockView.wo/English.lproj/SkySchedulerDockView.html
	echo "<!-- generated from $(<), do not modify ! -->" >$@
	cat $< >>$@

SkySchedulerDockView.wo/German.lproj/SkySchedulerDockView.wod : SkySchedulerDockView.wo/English.lproj/SkySchedulerDockView.wod
	echo "// generated from $(<), do not modify ! " >$@
	cat $< >>$@
