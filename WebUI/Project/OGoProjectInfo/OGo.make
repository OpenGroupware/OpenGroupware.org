# $Id$

OGoProjectInfo_LANGUAGES = \
	English German \
	English_blue   German_blue \
	English_orange German_orange \
	English_OOo    German_OOo  \
	English_kde

OGoProjectInfo_RESOURCE_FILES += Defaults.plist Version

OGoProjectInfo_DERIVED_RESOURCES += \
	SkyDockedProjects.wo/German.lproj/SkyDockedProjects.html	\
	SkyDockedProjects.wo/German.lproj/SkyDockedProjects.wod		\
	SkyDockedProjects.wo/German_OOo.lproj/SkyDockedProjects.html	\
	SkyDockedProjects.wo/German_OOo.lproj/SkyDockedProjects.wod	\
	SkyDockedProjects.wo/German_blue.lproj/SkyDockedProjects.html	\
	SkyDockedProjects.wo/German_blue.lproj/SkyDockedProjects.wod	\

# $Id$

# German

SkyDockedProjects.wo/German.lproj/SkyDockedProjects.html : SkyDockedProjects.wo/English.lproj/SkyDockedProjects.html
	echo "<!-- generated from $(<), do not modify ! -->" >$@
	cat $< >>$@

SkyDockedProjects.wo/German.lproj/SkyDockedProjects.wod : SkyDockedProjects.wo/English.lproj/SkyDockedProjects.wod
	echo "// generated from $(<), do not modify ! " >$@
	cat $< >>$@

# German OOo

SkyDockedProjects.wo/German_OOo.lproj/SkyDockedProjects.html : SkyDockedProjects.wo/English_OOo.lproj/SkyDockedProjects.html
	echo "<!-- generated from $(<), do not modify ! -->" >$@
	cat $< >>$@

SkyDockedProjects.wo/German_OOo.lproj/SkyDockedProjects.wod : SkyDockedProjects.wo/English_OOo.lproj/SkyDockedProjects.wod
	echo "// generated from $(<), do not modify ! " >$@
	cat $< >>$@

# German blue

SkyDockedProjects.wo/German_blue.lproj/SkyDockedProjects.html : SkyDockedProjects.wo/English_blue.lproj/SkyDockedProjects.html
	echo "<!-- generated from $(<), do not modify ! -->" >$@
	cat $< >>$@

SkyDockedProjects.wo/German_blue.lproj/SkyDockedProjects.wod : SkyDockedProjects.wo/English_blue.lproj/SkyDockedProjects.wod
	echo "// generated from $(<), do not modify ! " >$@
	cat $< >>$@
