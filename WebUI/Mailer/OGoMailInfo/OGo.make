# $Id$

OGoMailInfo_LANGUAGES += \
	English German	\
	English_OOo	\
	English_blue	\
	English_kde	\
	English_orange

# resources

OGoMailInfo_RESOURCE_FILES += Defaults.plist Version

OGoMailInfo_DERIVED_RESOURCES += \
	LSWImapDockView.wo/German.lproj/LSWImapDockView.html  \
	LSWImapDockView.wo/German.lproj/LSWImapDockView.wod \


# $Id$

# German

LSWImapDockView.wo/German.lproj/LSWImapDockView.html : LSWImapDockView.wo/English.lproj/LSWImapDockView.html
	echo "<!-- generated from $(<), do not modify ! -->" >$@
	cat $< >>$@

LSWImapDockView.wo/German.lproj/LSWImapDockView.wod : LSWImapDockView.wo/English.lproj/LSWImapDockView.wod
	echo "// generated from $(<), do not modify ! " >$@
	cat $< >>$@
