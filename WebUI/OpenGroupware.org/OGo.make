# Localized Resources

OpenGroupware_LANGUAGES = \
	English German Danish Dutch Spanish French Italian Polish \
	English_blue   German_blue	\
	English_orange German_orange	\
	English_OOo  German_OOo 	\
	English_kde			\
	ptBR

OpenGroupware_LOCALIZED_RESOURCE_FILES = \
	componentAttributes.cfg	\
	components.cfg		\

OpenGroupware_DERIVED_RESOURCES = \
	German.lproj/components.cfg	\
	Danish.lproj/components.cfg	\
	Dutch.lproj/components.cfg	\
	Polish.lproj/components.cfg	\
	Spanish.lproj/components.cfg	\
	French.lproj/components.cfg	\
	Italian.lproj/components.cfg	\
	ptBR.lproj/components.cfg 	\
	\
	English_OOo.lproj/components.cfg\
	German_OOo.lproj/components.cfg	\
	English_kde.lproj/components.cfg\
	English_blue.lproj/components.cfg\
	German_blue.lproj/components.cfg

German.lproj/components.cfg : English.lproj/components.cfg
	echo "// do not modify, automatically created !" > $@
	cat $< >> $@

Danish.lproj/components.cfg : English.lproj/components.cfg
	echo "// do not modify, automatically created !" > $@
	cat $< >> $@

Dutch.lproj/components.cfg : English.lproj/components.cfg
	echo "// do not modify, automatically created !" > $@
	cat $< >> $@

Polish.lproj/components.cfg : English.lproj/components.cfg
	echo "// do not modify, automatically created !" > $@
	cat $< >> $@

Spanish.lproj/components.cfg : English.lproj/components.cfg
	echo "// do not modify, automatically created !" > $@
	cat $< >> $@

French.lproj/components.cfg : English.lproj/components.cfg
	echo "// do not modify, automatically created !" > $@
	cat $< >> $@

Italian.lproj/components.cfg : English.lproj/components.cfg
	echo "// do not modify, automatically created !" > $@
	cat $< >> $@

ptBR.lproj/components.cfg : English.lproj/components.cfg
	echo "// do not modify, automatically created !" > $@
	cat $< >> $@

# themes

English_OOo.lproj/components.cfg : English.lproj/components.cfg
	echo "// do not modify, automatically created !" > $@
	cat $< >> $@

German_OOo.lproj/components.cfg : English.lproj/components.cfg
	echo "// do not modify, automatically created !" > $@
	cat $< >> $@

English_blue.lproj/components.cfg : English.lproj/components.cfg
	echo "// do not modify, automatically created !" > $@
	cat $< >> $@

German_blue.lproj/components.cfg : English.lproj/components.cfg
	echo "// do not modify, automatically created !" > $@
	cat $< >> $@

English_kde.lproj/components.cfg : English.lproj/components.cfg
	echo "// do not modify, automatically created !" > $@
	cat $< >> $@

