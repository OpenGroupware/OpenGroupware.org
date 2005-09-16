# New ports collection makefile for:	sope45-devel
# Date created:  07 Sep 2005
# Whom:          Frank Reppin <frank@opengroupware.org>
#
# $FreeBSD$

PORTNAME=	sope
PORTVERSION=	4.5
PORTREVISION=	1
CATEGORIES=	devel
MASTER_SITES=	http://download.opengroupware.org/nightly/packages/freebsd/sope/
DISTNAME=	sope-trunk-r1110-200509161800

MAINTAINER=	frank@opengroupware.org
COMMENT=	SOPE is a framework for developing web applications and services

BUILD_DEPENDS=	${LOCALBASE}/OGo-GNUstep/Makefiles/GNUstep.csh:${PORTSDIR}/devel/ogo-gnustep-make \
		${LOCALBASE}/lib/libobjc_d.so.lf2.95.3:${PORTSDIR}/devel/ogo-libobjc-lf2 \
		${LOCALBASE}/lib/libFoundation_d.so.1.0:${PORTSDIR}/devel/ogo-libfoundation \
		pkg-config:${PORTSDIR}/devel/pkgconfig

UNIQUENAME=	${PORTNAME}45
CONFLICTS?=	sope-4.4*
DIST_SUBDIR=	ogo-suite

OPTIONS=	LIBXML2		"link with libxml2" on \
		LDAP		"link with ldap" on \
		PQ		"link with pq" on \
		SSL		"link with ssl" on \
		SQLITE3		"link with sqlite3" off \
		MYSQLCLIENT	"link with mysqlclient" off

.include <bsd.port.pre.mk>

WRKSRC=		${WRKDIR}/sope
INSTALLS_SHLIB=	yes
NO_FILTER_SHLIBS=	yes
USE_GMAKE=	yes
USE_ICONV=	yes
PREFIX=		${LOCALBASE}
MAKEFILE=	GNUmakefile
MAKE_ARGS=	debug=yes \
		GNUSTEP_INSTALLATION_DIR=${PREFIX} \
		FHS_INSTALL_ROOT=${PREFIX}

.if defined(WITH_LIBXML2) || !defined(WITHOUT_LIBXML2)
MAKE_ARGS+=	HAS_LIBRARY_xml2=yes
LIB_DEPENDS+=	xml2.5:${PORTSDIR}/textproc/libxml2
.endif
.if defined(WITH_LDAP) || !defined(WITHOUT_LDAP)
USE_OPENLDAP=	YES
MAKE_ARGS+=	HAS_LIBRARY_ldap=yes
.endif
# not yet optional at all
.if defined(WITH_SSL) || !defined(WITHOUT_SSL)
MAKE_ARGS+=	HAS_LIBRARY_ssl=yes
.endif
.if defined(WITH_PQ) || !defined(WITHOUT_PQ)
USE_PGSQL=	YES
MAKE_ARGS+=	HAS_LIBRARY_pq=yes
.endif
.if defined(WITH_SQLITE3)
MAKE_ARGS+=	HAS_LIBRARY_sqlite3=yes
LIB_DEPENDS+=	sqlite3.8:${PORTSDIR}/databases/sqlite3
.else
MAKE_ARGS+=	HAS_LIBRARY_sqlite3=no
.endif
.if defined(WITH_MYSQLCLIENT)
USE_MYSQL=	yes
MAKE_ARGS+=	HAS_LIBRARY_mysqlclient=yes
.else
MAKE_ARGS+=	HAS_LIBRARY_mysqlclient=no
.endif

MAN3=		JSAlertPanel.3 JSClipboard.3 JSConfirmPanel.3 JSImageFlyover.3 JSMenu.3 \
		JSMenuItem.3 JSModalWindow.3 JSShiftClick.3 JSTextFlyover.3 JSValidatedField.3 \
		WEBrowser.3 WECalendarField.3 WECase.3 WECollapsibleComponentContent.3 WEComponentValue.3 \
		WEContextConditional.3 WEContextKey.3 WEDateField.3 WEDragContainer.3 WEDropContainer.3 \
		WEEpozEditor.3 WEHSpanTableMatrix.3 WEMonthLabel.3 WEMonthOverview.3 WEPageItem.3 \
		WEPageLink.3 WEPageView.3 WEQualifierConditional.3 WERedirect.3 WERichString.3 \
		WESwitch.3 WETabItem.3 WETabView.3 WETableData.3 WETableHeader.3 \
		WETableMatrix.3 WETableMatrixContent.3 WETableMatrixLabel.3 WETableView.3 WETimeField.3 \
		WETreeData.3 WETreeHeader.3 WETreeView.3 WEVSpanTableMatrix.3 WEWeekColumnView.3 \
		WEWeekOverview.3 WOActionURL.3 WOBody.3 WOBrowser.3 WOCheckBox.3 \
		WOCheckBoxList.3 WOCheckBoxMatrix.3 WOCollapsibleComponentContent.3 WOComponentReference.3 WOConditional.3 \
		WODictionaryRepetition.3 WOEmbeddedObject.3 WOEntity.3 WOFileUpload.3 WOForm.3 \
		WOFrame.3 WOGenericContainer.3 WOGenericElement.3 WOHiddenField.3 WOHyperlink.3 \
		WOIFrame.3 WOImage.3 WOImageButton.3 WOJavaScript.3 WOKeyValueConditional.3 \
		WOMetaRefresh.3 WONestedList.3 WOPasswordField.3 WOPopUpButton.3 WOQuickTime.3 \
		WORadioButton.3 WORadioButtonList.3 WORadioButtonMatrix.3 WORedirect.3 WORepetition.3 \
		WOResetButton.3 WOResourceURL.3 WOSetCursor.3 WOString.3 WOSubmitButton.3 \
		WOSwitchComponent.3 WOTabPanel.3 WOTable.3 WOText.3 WOTextField.3 \
		WOThresholdColoredNumber.3 WOVBScript.3

MAN5=		sope-ngobjweb-defaults.5

pre-everything::
	@${ECHO_CMD} "################################################################"
	@${ECHO_CMD} "# README !!! README!!! README!!! README!!! README!!! README!!! #"
	@${ECHO_CMD} "#                                                              #"
	@${ECHO_CMD} "# The preselected values in the following survey are OK if     #"
	@${ECHO_CMD} "# you're going to build SOPE for OpenGroupware.org - so        #"
	@${ECHO_CMD} "# simply TAB to [OK] and wait for it to finish.                #"
	@${ECHO_CMD} "#                                                              #"
	@${ECHO_CMD} "# If you've built this port before or changed your mind        #"
	@${ECHO_CMD} "# regarding the settings - please do a CTRL+C now and:         #"
	@${ECHO_CMD} "#                                                              #"
	@${ECHO_CMD} "#  make rmconfig - will remove the current config              #"
	@${ECHO_CMD} "#                  for this port                               #"
	@${ECHO_CMD} "#                                                              #"
	@${ECHO_CMD} "#  make config   - will summon the config panel                #"
	@${ECHO_CMD} "#                  again                                       #"
	@${ECHO_CMD} "#                                                              #"
	@${ECHO_CMD} "#  (make sure that you're in the correct portsdir prior        #"
	@${ECHO_CMD} "#  executing the above mentioned commands)                     #"
	@${ECHO_CMD} "#                                                              #"
	@${ECHO_CMD} "################################################################"
	@sleep 5

do-build:
	(cd ${WRKSRC}; . ${LOCALBASE}/OGo-GNUstep/Makefiles/GNUstep.sh; ${GMAKE} ${MAKE_ARGS})

do-install:
	(cd ${WRKSRC}; . ${LOCALBASE}/OGo-GNUstep/Makefiles/GNUstep.sh; ${GMAKE} ${MAKE_ARGS} install)

.include <bsd.port.post.mk>
