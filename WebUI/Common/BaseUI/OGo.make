BaseUI_LANGUAGES = \
	English German \
	English_orange German_blue   \
	English_blue   German_orange \
	English_OOo    German_OOo    \
	English_kde

BaseUI_RESOURCE_FILES += Defaults.plist Version

BaseUI_DERIVED_RESOURCES += \
	LSWSkyrixFrame.wo/German.lproj/LSWSkyrixFrame.html	\
	LSWSkyrixFrame.wo/German.lproj/LSWSkyrixFrame.wod	\
	LSWSkyrixFrame.wo/German_OOo.lproj/LSWSkyrixFrame.html	\
	LSWSkyrixFrame.wo/German_OOo.lproj/LSWSkyrixFrame.wod	\
	LSWSkyrixFrame.wo/German_blue.lproj/LSWSkyrixFrame.html \
	LSWSkyrixFrame.wo/German_blue.lproj/LSWSkyrixFrame.wod	\
	SkyDock.wo/German.lproj/SkyDock.html  			\
	SkyDock.wo/German.lproj/SkyDock.wod			\
	SkyDock.wo/German_OOo.lproj/SkyDock.html		\
	SkyDock.wo/German_OOo.lproj/SkyDock.wod 		\
	SkyDock.wo/German_blue.lproj/SkyDock.html 		\
	SkyDock.wo/German_blue.lproj/SkyDock.wod 		\
	SkyFavorites.wo/German.lproj/SkyFavorites.html  	\
	SkyFavorites.wo/German.lproj/SkyFavorites.wod		\
	SkyFavorites.wo/German_OOo.lproj/SkyFavorites.html	\
	SkyFavorites.wo/German_OOo.lproj/SkyFavorites.wod	\
	SkyFavorites.wo/German_blue.lproj/SkyFavorites.html	\
	SkyFavorites.wo/German_blue.lproj/SkyFavorites.wod	\
	SkyNavigation.wo/German.lproj/SkyNavigation.html	\
	SkyNavigation.wo/German.lproj/SkyNavigation.wod		\
	SkyNavigation.wo/German_OOo.lproj/SkyNavigation.html	\
	SkyNavigation.wo/German_OOo.lproj/SkyNavigation.wod	\
	SkyNavigation.wo/German_blue.lproj/SkyNavigation.html	\
	SkyNavigation.wo/German_blue.lproj/SkyNavigation.wod	\


# German

LSWSkyrixFrame.wo/German.lproj/LSWSkyrixFrame.html : LSWSkyrixFrame.wo/English.lproj/LSWSkyrixFrame.html
	echo "<!-- generated from $(<), do not modify ! -->" >$@
	cat $< >>$@

LSWSkyrixFrame.wo/German.lproj/LSWSkyrixFrame.wod : LSWSkyrixFrame.wo/English.lproj/LSWSkyrixFrame.wod
	echo "// generated from $(<), do not modify ! " >$@
	cat $< >>$@

SkyDock.wo/German.lproj/SkyDock.html : SkyDock.wo/English.lproj/SkyDock.html
	echo "<!-- generated from $(<), do not modify ! -->" >$@
	cat $< >>$@

SkyDock.wo/German.lproj/SkyDock.wod : SkyDock.wo/English.lproj/SkyDock.wod
	echo "// generated from $(<), do not modify ! " >$@
	cat $< >>$@

SkyFavorites.wo/German.lproj/SkyFavorites.html : SkyFavorites.wo/English.lproj/SkyFavorites.html
	echo "<!-- generated from $(<), do not modify ! -->" >$@
	cat $< >>$@

SkyFavorites.wo/German.lproj/SkyFavorites.wod : SkyFavorites.wo/English.lproj/SkyFavorites.wod
	echo "// generated from $(<), do not modify ! " >$@
	cat $< >>$@

SkyNavigation.wo/German.lproj/SkyNavigation.html : SkyNavigation.wo/English.lproj/SkyNavigation.html
	echo "<!-- generated from $(<), do not modify ! -->" >$@
	cat $< >>$@

SkyNavigation.wo/German.lproj/SkyNavigation.wod : SkyNavigation.wo/English.lproj/SkyNavigation.wod
	echo "// generated from $(<), do not modify ! " >$@
	cat $< >>$@

# German OOo

LSWSkyrixFrame.wo/German_OOo.lproj/LSWSkyrixFrame.html : LSWSkyrixFrame.wo/English_OOo.lproj/LSWSkyrixFrame.html
	echo "<!-- generated from $(<), do not modify ! -->" >$@
	cat $< >>$@

LSWSkyrixFrame.wo/German_OOo.lproj/LSWSkyrixFrame.wod : LSWSkyrixFrame.wo/English_OOo.lproj/LSWSkyrixFrame.wod
	echo "// generated from $(<), do not modify ! " >$@
	cat $< >>$@

SkyDock.wo/German_OOo.lproj/SkyDock.html : SkyDock.wo/English_OOo.lproj/SkyDock.html
	echo "<!-- generated from $(<), do not modify ! -->" >$@
	cat $< >>$@

SkyDock.wo/German_OOo.lproj/SkyDock.wod : SkyDock.wo/English_OOo.lproj/SkyDock.wod
	echo "// generated from $(<), do not modify ! " >$@
	cat $< >>$@

SkyFavorites.wo/German_OOo.lproj/SkyFavorites.html : SkyFavorites.wo/English_OOo.lproj/SkyFavorites.html
	echo "<!-- generated from $(<), do not modify ! -->" >$@
	cat $< >>$@

SkyFavorites.wo/German_OOo.lproj/SkyFavorites.wod : SkyFavorites.wo/English_OOo.lproj/SkyFavorites.wod
	echo "// generated from $(<), do not modify ! " >$@
	cat $< >>$@

SkyNavigation.wo/German_OOo.lproj/SkyNavigation.html : SkyNavigation.wo/English_OOo.lproj/SkyNavigation.html
	echo "<!-- generated from $(<), do not modify ! -->" >$@
	cat $< >>$@

SkyNavigation.wo/German_OOo.lproj/SkyNavigation.wod : SkyNavigation.wo/English_OOo.lproj/SkyNavigation.wod
	echo "// generated from $(<), do not modify ! " >$@
	cat $< >>$@

# German blue

LSWSkyrixFrame.wo/German_blue.lproj/LSWSkyrixFrame.html : LSWSkyrixFrame.wo/English_blue.lproj/LSWSkyrixFrame.html
	echo "<!-- generated from $(<), do not modify ! -->" >$@
	cat $< >>$@

LSWSkyrixFrame.wo/German_blue.lproj/LSWSkyrixFrame.wod : LSWSkyrixFrame.wo/English_blue.lproj/LSWSkyrixFrame.wod
	echo "// generated from $(<), do not modify ! " >$@
	cat $< >>$@

SkyDock.wo/German_blue.lproj/SkyDock.html : SkyDock.wo/English_blue.lproj/SkyDock.html
	echo "<!-- generated from $(<), do not modify ! -->" >$@
	cat $< >>$@

SkyDock.wo/German_blue.lproj/SkyDock.wod : SkyDock.wo/English_blue.lproj/SkyDock.wod
	echo "// generated from $(<), do not modify ! " >$@
	cat $< >>$@

SkyFavorites.wo/German_blue.lproj/SkyFavorites.html : SkyFavorites.wo/English_blue.lproj/SkyFavorites.html
	echo "<!-- generated from $(<), do not modify ! -->" >$@
	cat $< >>$@

SkyFavorites.wo/German_blue.lproj/SkyFavorites.wod : SkyFavorites.wo/English_blue.lproj/SkyFavorites.wod
	echo "// generated from $(<), do not modify ! " >$@
	cat $< >>$@

SkyNavigation.wo/German_blue.lproj/SkyNavigation.html : SkyNavigation.wo/English_blue.lproj/SkyNavigation.html
	echo "<!-- generated from $(<), do not modify ! -->" >$@
	cat $< >>$@

SkyNavigation.wo/German_blue.lproj/SkyNavigation.wod : SkyNavigation.wo/English_blue.lproj/SkyNavigation.wod
	echo "// generated from $(<), do not modify ! " >$@
	cat $< >>$@
