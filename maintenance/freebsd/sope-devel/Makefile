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
DISTNAME=	sope-trunk-r1313-200607111100

MAINTAINER=	frank@opengroupware.org
COMMENT=	SOPE is a framework for developing web applications and services

BUILD_DEPENDS=	${LOCALBASE}/OGo-GNUstep/Makefiles/GNUstep.csh:${PORTSDIR}/devel/ogo-gnustep-make \
		${LOCALBASE}/lib/libobjc_d.so.lf2.95.3:${PORTSDIR}/devel/ogo-libobjc-lf2 \
		${LOCALBASE}/lib/libFoundation_d.so.1.0:${PORTSDIR}/devel/ogo-libfoundation \
		pkg-config:${PORTSDIR}/devel/pkgconfig

UNIQUENAME=	${PORTNAME}45
CONFLICTS?=	sope-4.4*
DIST_SUBDIR=	ogo-suite

SHLIB_MAJOR=	4
SHLIB_MINOR=	5

LIBDOM_SUBMINOR=	20
LIBEOCONTROL_SUBMINOR=	64
LIBGDLACCESS_SUBMINOR=	55
LIBGDLCONTENTSTORE_SUBMINOR=	35
LIBNGEXTENSIONS_SUBMINOR=	183
LIBNGLDAP_SUBMINOR=	29
LIBNGMIME_SUBMINOR=	240
LIBNGOBJWEB_SUBMINOR=	233
LIBNGSTREAMS_SUBMINOR=	49
LIBNGXMLRPC_SUBMINOR=	14
LIBNGICAL_SUBMINOR=	74
LIBSAXOBJC_SUBMINOR=	55
LIBSOOFS_SUBMINOR=	21
LIBWEEXTENSIONS_SUBMINOR=	85
LIBWEPROTOTYPE_SUBMINOR=	7
LIBWOEXTENSIONS_SUBMINOR=	29
LIBWOXML_SUBMINOR=	8
LIBXMLRPC_SUBMINOR=	27

PLIST_SUB=	SHLIB_MAJOR="${SHLIB_MAJOR}" \
		SHLIB_MINOR="${SHLIB_MINOR}" \
		LIBDOM_SUBMINOR="${LIBDOM_SUBMINOR}" \
		LIBEOCONTROL_SUBMINOR="${LIBEOCONTROL_SUBMINOR}" \
		LIBGDLACCESS_SUBMINOR="${LIBGDLACCESS_SUBMINOR}" \
		LIBGDLCONTENTSTORE_SUBMINOR="${LIBGDLCONTENTSTORE_SUBMINOR}" \
		LIBNGEXTENSIONS_SUBMINOR="${LIBNGEXTENSIONS_SUBMINOR}" \
		LIBNGLDAP_SUBMINOR="${LIBNGLDAP_SUBMINOR}" \
		LIBNGMIME_SUBMINOR="${LIBNGMIME_SUBMINOR}" \
		LIBNGOBJWEB_SUBMINOR="${LIBNGOBJWEB_SUBMINOR}" \
		LIBNGSTREAMS_SUBMINOR="${LIBNGSTREAMS_SUBMINOR}" \
		LIBNGXMLRPC_SUBMINOR="${LIBNGXMLRPC_SUBMINOR}" \
		LIBNGICAL_SUBMINOR="${LIBNGICAL_SUBMINOR}" \
		LIBSAXOBJC_SUBMINOR="${LIBSAXOBJC_SUBMINOR}" \
		LIBSOOFS_SUBMINOR="${LIBSOOFS_SUBMINOR}" \
		LIBWEEXTENSIONS_SUBMINOR="${LIBWEEXTENSIONS_SUBMINOR}" \
		LIBWEPROTOTYPE_SUBMINOR="${LIBWEPROTOTYPE_SUBMINOR}" \
		LIBWOEXTENSIONS_SUBMINOR="${LIBWOEXTENSIONS_SUBMINOR}" \
		LIBWOXML_SUBMINOR="${LIBWOXML_SUBMINOR}" \
		LIBXMLRPC_SUBMINOR="${LIBXMLRPC_SUBMINOR}"

OPTIONS=	LIBXML2		"link with libxml2 (required)" on \
		LDAP		"link with ldap (required)" on \
		PQ		"link with pq (required if you build for OGo)" on \
		SQLITE3		"link with sqlite3 (optional)" off \
		MYSQLCLIENT	"link with mysqlclient (optional)" off

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

.if defined(SHOW_MESSAGES)
MAKE_ARGS+=	messages=yes
.endif
.if defined(WITH_LIBXML2) || !defined(WITHOUT_LIBXML2)
MAKE_ARGS+=	HAS_LIBRARY_xml2=yes
LIB_DEPENDS+=	xml2.5:${PORTSDIR}/textproc/libxml2
.else
MAKE_ARGS+=	HAS_LIBRARY_xml2=no
.endif
.if defined(WITH_LDAP) || !defined(WITHOUT_LDAP)
USE_OPENLDAP=	YES
MAKE_ARGS+=	HAS_LIBRARY_ldap=yes
.else
MAKE_ARGS+=	HAS_LIBRARY_ldap=no
.endif
# not yet optional at all
#.if defined(WITH_SSL)
#MAKE_ARGS+=	HAS_LIBRARY_ssl=yes
#.else
#MAKE_ARGS+=	HAS_LIBRARY_ssl=no
#.endif
.if defined(WITH_PQ) || !defined(WITHOUT_PQ)
USE_PGSQL=	YES
DEFAULT_PGSQL_VER?=	80
MAKE_ARGS+=	HAS_LIBRARY_pq=yes
.else
MAKE_ARGS+=	HAS_LIBRARY_pq=no
.endif
.if defined(WITH_SQLITE3)
USE_SQLITE=	YES
MAKE_ARGS+=	HAS_LIBRARY_sqlite3=yes
LIB_DEPENDS+=	sqlite3.8:${PORTSDIR}/databases/sqlite3
.else
MAKE_ARGS+=	HAS_LIBRARY_sqlite3=no
.endif
.if defined(WITH_MYSQLCLIENT)
USE_MYSQL=	yes
DEFAULT_MYSQL_VER?=	41
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

do-build:
	(cd ${WRKSRC}; . ${LOCALBASE}/OGo-GNUstep/Makefiles/GNUstep.sh; ${GMAKE} ${MAKE_ARGS})

do-install:
	(cd ${WRKSRC}; . ${LOCALBASE}/OGo-GNUstep/Makefiles/GNUstep.sh; ${GMAKE} ${MAKE_ARGS} install)

.include <bsd.port.post.mk>
