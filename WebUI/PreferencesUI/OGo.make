# $Id$

PreferencesUI_LANGUAGES = \
	English German			\
	English_blue   German_blue	\
	English_orange German_orange

PreferencesUI_RESOURCE_FILES += Defaults.plist Version
PreferencesUI_INCLUDE_DIRS   += -IHeaders

PreferencesUI_DERIVED_RESOURCES += \
	SkyDisplayPreferences.wo/German.lproj/SkyDisplayPreferences.html\
	SkyDisplayPreferences.wo/German.lproj/SkyDisplayPreferences.wod	\
	SkyDisplayPreferences.wo/German_blue.lproj/SkyDisplayPreferences.html\
	SkyDisplayPreferences.wo/German_blue.lproj/SkyDisplayPreferences.wod\
	SkyDisplayPreferences.wo/German_orange.lproj/SkyDisplayPreferences.html\
	SkyDisplayPreferences.wo/German_orange.lproj/SkyDisplayPreferences.wod\

# $Id$

# German

SkyDisplayPreferences.wo/German.lproj/SkyDisplayPreferences.html : SkyDisplayPreferences.wo/English.lproj/SkyDisplayPreferences.html
	echo "<!-- generated from $(<), do not modify ! -->" >$@
	cat $< >>$@

SkyDisplayPreferences.wo/German.lproj/SkyDisplayPreferences.wod : SkyDisplayPreferences.wo/English.lproj/SkyDisplayPreferences.wod
	echo "// generated from $(<), do not modify ! " >$@
	cat $< >>$@

# Blue

SkyDisplayPreferences.wo/English_blue.lproj/SkyDisplayPreferences.html : SkyDisplayPreferences.wo/English.lproj/SkyDisplayPreferences.html
	echo "<!-- generated from $(<), do not modify ! -->" >$@
	cat $< >>$@

SkyDisplayPreferences.wo/English_blue.lproj/SkyDisplayPreferences.wod : SkyDisplayPreferences.wo/English.lproj/SkyDisplayPreferences.wod
	echo "// generated from $(<), do not modify ! " >$@
	cat $< >>$@


SkyDisplayPreferences.wo/German_blue.lproj/SkyDisplayPreferences.html : SkyDisplayPreferences.wo/English.lproj/SkyDisplayPreferences.html
	echo "<!-- generated from $(<), do not modify ! -->" >$@
	cat $< >>$@

SkyDisplayPreferences.wo/German_blue.lproj/SkyDisplayPreferences.wod : SkyDisplayPreferences.wo/English.lproj/SkyDisplayPreferences.wod
	echo "// generated from $(<), do not modify ! " >$@
	cat $< >>$@

# German Orange

SkyDisplayPreferences.wo/German_orange.lproj/SkyDisplayPreferences.html : SkyDisplayPreferences.wo/English_orange.lproj/SkyDisplayPreferences.html
	echo "<!-- generated from $(<), do not modify ! -->" >$@
	cat $< >>$@

SkyDisplayPreferences.wo/German_orange.lproj/SkyDisplayPreferences.wod : SkyDisplayPreferences.wo/English_orange.lproj/SkyDisplayPreferences.wod
	echo "// generated from $(<), do not modify ! " >$@
	cat $< >>$@
