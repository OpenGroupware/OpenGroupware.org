# New ports collection makefile for:	sope45-devel
# Date created:  07 Sep 2005
# Whom:          Frank Reppin <frank@opengroupware.org>
#
# $FreeBSD$

PORTNAME=	sope
PORTVERSION=	4.7
PORTREVISION=	1
CATEGORIES=	devel
MASTER_SITES=	http://download.opengroupware.org/nightly/packages/freebsd/sope/
DISTNAME=	sope-trunk-r1467-200703191100

MAINTAINER=	frank@opengroupware.org
COMMENT=	SOPE is a framework for developing web applications and services

BUILD_DEPENDS=	${LOCALBASE}/OGo-GNUstep/System/Library/Makefiles/GNUstep.sh:${PORTSDIR}/devel/ogo-gnustep-make \
		${LOCALBASE}/lib/libFoundation.so.1.1:${PORTSDIR}/devel/ogo-libfoundation \
		bash:${PORTSDIR}/shells/bash \
		pkg-config:${PORTSDIR}/devel/pkg-config

UNIQUENAME=	${PORTNAME}47
CONFLICTS?=	sope-4.4* \
		sope-4.5* \
		sope-4.6*
DIST_SUBDIR=	ogo-suite

SHLIB_MAJOR=	4
SHLIB_MINOR=	7

LIBDOM_SUBMINOR=	23
LIBEOCONTROL_SUBMINOR=	72
LIBGDLACCESS_SUBMINOR=	58
LIBGDLCONTENTSTORE_SUBMINOR=	40
LIBNGEXTENSIONS_SUBMINOR=	191
LIBNGLDAP_SUBMINOR=	30
LIBNGMIME_SUBMINOR=	242
LIBNGOBJWEB_SUBMINOR=	6
LIBNGSTREAMS_SUBMINOR=	51
LIBNGXMLRPC_SUBMINOR=	16
LIBNGICAL_SUBMINOR=	81
LIBSAXOBJC_SUBMINOR=	65
LIBSOOFS_SUBMINOR=	25
LIBWEEXTENSIONS_SUBMINOR=	93
LIBWEPROTOTYPE_SUBMINOR=	9
LIBWOEXTENSIONS_SUBMINOR=	31
LIBWOXML_SUBMINOR=	9
LIBXMLRPC_SUBMINOR=	31

STRAY_SOPE_DIRS=	Library/WOxElemBuilders-${SHLIB_MAJOR}.${SHLIB_MINOR} \
			Library/SoProducts-${SHLIB_MAJOR}.${SHLIB_MINOR} \
			Library/SaxDrivers-${SHLIB_MAJOR}.${SHLIB_MINOR} \
			Library/Libraries \
			Library/Headers/XmlRpc \
			Library/Headers/WOXML \
			Library/Headers/WOExtensions \
			Library/Headers/WEExtensions \
			Library/Headers/SoOFS \
			Library/Headers/SaxObjC \
			Library/Headers/NGiCal \
			Library/Headers/NGXmlRpc \
			Library/Headers/NGStreams \
			Library/Headers/NGObjWeb \
			Library/Headers/NGMime \
			Library/Headers/NGMail \
			Library/Headers/NGLdap \
			Library/Headers/NGImap4 \
			Library/Headers/NGHttp \
			Library/Headers/NGExtensions \
			Library/Headers/GDLContentStore \
			Library/Headers/GDLAccess \
			Library/Headers/EOControl \
			Library/Headers/DOM \
			Library/Headers \
			Library/GDLAdaptors-${SHLIB_MAJOR}.${SHLIB_MINOR} \
			Library \
			Tools

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
USE_LDCONFIG=	yes
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

# AND HERE WE OVERRIDE WHAT CONFIGURE DETERMINES...
# (ONLY REQUIRED FOR EXCLUSIONS WRT TO WHAT 'do-configure' DETECTS)
.if defined(WITH_LIBXML2) || !defined(WITHOUT_LIBXML2)
LIB_DEPENDS+=	xml2.5:${PORTSDIR}/textproc/libxml2
.else
MAKE_ARGS+=	HAS_LIBRARY_xml2=no
.endif
.if defined(WITH_LDAP) || !defined(WITHOUT_LDAP)
USE_OPENLDAP=	YES
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
DEFAULT_PGSQL_VER?=	82
.else
MAKE_ARGS+=	HAS_LIBRARY_pq=no
.endif
.if defined(WITH_SQLITE3)
USE_SQLITE=	YES
LIB_DEPENDS+=	sqlite3.8:${PORTSDIR}/databases/sqlite3
.else
MAKE_ARGS+=	HAS_LIBRARY_sqlite3=no
.endif
.if defined(WITH_MYSQLCLIENT)
USE_MYSQL=	yes
DEFAULT_MYSQL_VER?=	50
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

do-configure:
	(cd ${WRKSRC}; . ${LOCALBASE}/OGo-GNUstep/System/Library/Makefiles/GNUstep.sh; ./configure)

do-build:
	(cd ${WRKSRC}; . ${LOCALBASE}/OGo-GNUstep/System/Library/Makefiles/GNUstep.sh; ${GMAKE} ${MAKE_ARGS})

do-install:
	@if [ ! -d "${LOCALBASE}/OGo-GNUstep/System/Library/Makefiles/Additional" ]; then \
	  ${ECHO_MSG} "creating directory '${LOCALBASE}/OGo-GNUstep/System/Library/Makefiles/Additional'"; \
	  ${MKDIR} ${LOCALBASE}/OGo-GNUstep/System/Library/Makefiles/Additional; \
	fi
	(cd ${WRKSRC}; . ${LOCALBASE}/OGo-GNUstep/System/Library/Makefiles/GNUstep.sh; ${GMAKE} ${MAKE_ARGS} install)
	@for STRAY_SOPE_DIR in ${STRAY_SOPE_DIRS}; do \
	  if [ -d ${LOCALBASE}/$${STRAY_LF_DIR} ]; then \
	  ${ECHO_MSG} "removing stray SOPE  directory '${LOCALBASE}/$${STRAY_SOPE_DIR}'..."; \
	  ${RMDIR} ${LOCALBASE}/$${STRAY_SOPE_DIR}; \
	  fi \
	done

.include <bsd.port.post.mk>
