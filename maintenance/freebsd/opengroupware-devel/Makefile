# New ports collection makefile for:	opengroupware-devel
# Date created:  09 Sep 2005
# Whom:          Frank Reppin <frank@opengroupware.org>
#
# $FreeBSD$

PORTNAME=	opengroupware
PORTVERSION=	1.1
PORTREVISION=	1
CATEGORIES=	devel
MASTER_SITES=	http://download.opengroupware.org/nightly/packages/freebsd/opengroupware/
DISTNAME=	opengroupware.org-trunk-r1910-200703251103

MAINTAINER=	frank@opengroupware.org
COMMENT=	OpenGroupware suite

BUILD_DEPENDS=	${LOCALBASE}/OGo-GNUstep/System/Library/Makefiles/GNUstep.sh:${PORTSDIR}/devel/ogo-gnustep-make \
		${LOCALBASE}/lib/libFoundation.so.1.1:${PORTSDIR}/devel/ogo-libfoundation \
		bash:${PORTSDIR}/shells/bash \
		pkg-config:${PORTSDIR}/devel/pkg-config

UNIQUENAME=	${PORTNAME}-devel
DIST_SUBDIR=	ogo-suite

OGO_VERSION=	1.1
ZIDE_VERSION=	1.5

SOPE_DEVEL_MAJOR=	4
SOPE_DEVEL_MINOR=	7
SOPE44_MAJOR=	4
SOPE44_MINOR=	4

OGO_SHLIB_MAJOR=	5
OGO_SHLIB_MINOR=	3
ZIDE_SHLIB_MAJOR=	1
ZIDE_SHLIB_MINOR=	5

LIBLSADDRESS_SUBMINOR=	92
LIBLSFOUNDATION_SUBMINOR=	127
LIBLSSEARCH_SUBMINOR=	35
LIBOGOACCOUNTS_SUBMINOR=	22
LIBOGOBASE_SUBMINOR=	10
LIBOGOCONTACTS_SUBMINOR=	60
LIBOGODATABASEPROJECT_SUBMINOR=	59
LIBOGODOCUMENTS_SUBMINOR=	29
LIBOGOFILESYSTEMPROJECT_SUBMINOR=	28
LIBOGOFOUNDATION_SUBMINOR=	106
LIBOGOJOBS_SUBMINOR=	26
LIBOGONHS_SUBMINOR=	12
LIBOGOPALMUI_SUBMINOR=	8
LIBOGOPALM_SUBMINOR=	32
LIBOGOPROJECT_SUBMINOR=	44
LIBOGORAWDATABASE_SUBMINOR=	14
LIBOGOSCHEDULERTOOLS_SUBMINOR=	99
LIBOGOSCHEDULER_SUBMINOR=	39
LIBOGOWEBMAIL_SUBMINOR=	106
LIBPPSYNC_SUBMINOR=	14
LIBZSAPPOINTMENTS_SUBMINOR=	0
LIBZSBACKEND_SUBMINOR=	89
LIBZSCONTACTS_SUBMINOR=	0
LIBZSFRONTEND_SUBMINOR=	117
LIBZSPROJECTS_SUBMINOR=	0
LIBZSTASKS_SUBMINOR=	0

PLIST_SUB=	OGO_VERSION="${OGO_VERSION}" \
		OGO_SHLIB_MAJOR="${OGO_SHLIB_MAJOR}" \
		OGO_SHLIB_MINOR="${OGO_SHLIB_MINOR}" \
		ZIDE_VERSION="${ZIDE_VERSION}" \
		ZIDE_SHLIB_MAJOR="${ZIDE_SHLIB_MAJOR}" \
		ZIDE_SHLIB_MINOR="${ZIDE_SHLIB_MINOR}" \
		LIBLSADDRESS_SUBMINOR="${LIBLSADDRESS_SUBMINOR}" \
		LIBLSFOUNDATION_SUBMINOR="${LIBLSFOUNDATION_SUBMINOR}" \
		LIBLSSEARCH_SUBMINOR="${LIBLSSEARCH_SUBMINOR}" \
		LIBOGOACCOUNTS_SUBMINOR="${LIBOGOACCOUNTS_SUBMINOR}" \
		LIBOGOBASE_SUBMINOR="${LIBOGOBASE_SUBMINOR}" \
		LIBOGOCONTACTS_SUBMINOR="${LIBOGOCONTACTS_SUBMINOR}" \
		LIBOGODATABASEPROJECT_SUBMINOR="${LIBOGODATABASEPROJECT_SUBMINOR}" \
		LIBOGODOCUMENTS_SUBMINOR="${LIBOGODOCUMENTS_SUBMINOR}" \
		LIBOGOFILESYSTEMPROJECT_SUBMINOR="${LIBOGOFILESYSTEMPROJECT_SUBMINOR}" \
		LIBOGOFOUNDATION_SUBMINOR="${LIBOGOFOUNDATION_SUBMINOR}" \
		LIBOGOJOBS_SUBMINOR="${LIBOGOJOBS_SUBMINOR}" \
		LIBOGONHS_SUBMINOR="${LIBOGONHS_SUBMINOR}" \
		LIBOGOPALMUI_SUBMINOR="${LIBOGOPALMUI_SUBMINOR}" \
		LIBOGOPALM_SUBMINOR="${LIBOGOPALM_SUBMINOR}" \
		LIBOGOPROJECT_SUBMINOR="${LIBOGOPROJECT_SUBMINOR}" \
		LIBOGORAWDATABASE_SUBMINOR="${LIBOGORAWDATABASE_SUBMINOR}" \
		LIBOGOSCHEDULERTOOLS_SUBMINOR="${LIBOGOSCHEDULERTOOLS_SUBMINOR}" \
		LIBOGOSCHEDULER_SUBMINOR="${LIBOGOSCHEDULER_SUBMINOR}" \
		LIBOGOWEBMAIL_SUBMINOR="${LIBOGOWEBMAIL_SUBMINOR}" \
		LIBPPSYNC_SUBMINOR="${LIBPPSYNC_SUBMINOR}" \
		LIBZSAPPOINTMENTS_SUBMINOR="${LIBZSAPPOINTMENTS_SUBMINOR}" \
		LIBZSBACKEND_SUBMINOR="${LIBZSBACKEND_SUBMINOR}" \
		LIBZSCONTACTS_SUBMINOR="${LIBZSCONTACTS_SUBMINOR}" \
		LIBZSFRONTEND_SUBMINOR="${LIBZSFRONTEND_SUBMINOR}" \
		LIBZSPROJECTS_SUBMINOR="${LIBZSPROJECTS_SUBMINOR}" \
		LIBZSTASKS_SUBMINOR="${LIBZSTASKS_SUBMINOR}"

SUB_FILES=	pkg-install pkg-message ogo-webui.sh ogo-xmlrpcd.sh ogo-nhsd.sh ogo-zidestore.sh \
		ogo-webui-apache.conf ogo-zidestore-apache.conf ogo-xmlrpcd-apache.conf \
		README_APACHE_SETUP README_POSTGRESQL_SETUP
SUB_LIST=	OGO_VERSION=${OGO_VERSION} ZIDE_VERSION=${ZIDE_VERSION} PREFIX=${PREFIX} \
		P_NAME=${PORTNAME} P_VERSION=${PORTVERSION}
DOCS=		README_APACHE_SETUP README_POSTGRESQL_SETUP
DOCSDIR=	${PREFIX}/share/doc/${PORTNAME}-${PORTVERSION}
EXAMPLES=	ogo-webui-apache.conf ogo-xmlrpcd-apache.conf ogo-zidestore-apache.conf
EXAMPLESDIR=	${PREFIX}/share/examples/${PORTNAME}-${PORTVERSION}

OPTIONS=	SOPE_DEVEL	"link with sope-devel (sope-${SOPE_DEVEL_MAJOR}.${SOPE_DEVEL_MINOR})" on \
		SOPE_44		"link with sope44 (sope-${SOPE44_MAJOR}.${SOPE44_MINOR})" off \
		PDA_SUPPORT     "build with support for PDA" off \
		PGSQLSERVER_HERE  "use PostgreSQL Server ${DEFAULT_PGSQL_VER} on this host?" on

STRAY_OGO_DIRS=	Library/ZideStore-${ZIDE_SHLIB_MAJOR}.${ZIDE_SHLIB_MINOR} \
		Library/OpenGroupware.org-${OGO_VERSION}/WebUI \
		Library/OpenGroupware.org-${OGO_VERSION}/DataSources \
		Library/OpenGroupware.org-${OGO_VERSION}/Commands \
		Library/OpenGroupware.org-${OGO_VERSION} \
		Library/Libraries \
		Library/Headers/ZSFrontend \
		Library/Headers/ZSBackend \
		Library/Headers/WebUI \
		Library/Headers/OGoWebMail \
		Library/Headers/OGoSchedulerTools \
		Library/Headers/OGoScheduler \
		Library/Headers/OGoRawDatabase \
		Library/Headers/OGoProject \
		Library/Headers/OGoJobs \
		Library/Headers/OGoFoundation \
		Library/Headers/OGoFileSystemProject \
		Library/Headers/OGoDocuments \
		Library/Headers/OGoDatabaseProject \
		Library/Headers/OGoContacts \
		Library/Headers/OGoBase \
		Library/Headers/OGoAccounts \
		Library/Headers/LSFoundation \
		Library/Headers \
		Library \
		Tools

.include <bsd.port.pre.mk>

WRKSRC=		${WRKDIR}/opengroupware.org
INSTALLS_SHLIB=	yes
NO_FILTER_SHLIBS=	yes
USE_OPENLDAP=	yes
USE_RC_SUBR=	ogo-nhsd.sh ogo-webui.sh ogo-xmlrpcd.sh ogo-zidestore.sh
USE_PGSQL=	yes
DEFAULT_PGSQL_VER?=	82
USE_GMAKE=	yes
USE_ICONV=	yes
PREFIX=		${LOCALBASE}
MAKEFILE=	GNUmakefile
MAKE_ARGS=	debug=yes \
		strip=no \
		GNUSTEP_INSTALLATION_DIR=${PREFIX} \
		FHS_INSTALL_ROOT=${PREFIX}

.if ${OSVERSION} >= 600022
EXTRACT_DEPENDS+=	${LOCALBASE}/bin/gtar:${PORTSDIR}/archivers/gtar
TAR=	${LOCALBASE}/bin/gtar
MAKE_ARGS+=	TAR=${TAR}
.endif

.if defined(SHOW_MESSAGES)
MAKE_ARGS+=	messages=yes
.endif

.if defined(WITH_SOPE_44)
BUILD_DEPENDS+=	${LOCALBASE}/sbin/sope-4.4:${PORTSDIR}/devel/sope44
.endif
.if defined(WITH_SOPE_DEVEL) || !defined(WITHOUT_SOPE_DEVEL)
BUILD_DEPENDS+=	${LOCALBASE}/sbin/sope-${SOPE_DEVEL_MAJOR}.${SOPE_DEVEL_MINOR}:${PORTSDIR}/devel/sope-devel
.endif
#WARNING doesn't work with 0.12.x out of the box... :/
.if defined(WITH_PDA_SUPPORT) || !defined(WITHOUT_PDA_SUPPORT)
LIB_DEPENDS+=	pisock.9:${PORTSDIR}/palm/pilot-link
MAKE_ARGS+=	libpisock=yes
.else
MAKE_ARGS+=	libpisock=no
.endif
.if defined(WITH_PGSQLSERVER_HERE) || !defined(WITHOUT_PGSQLSERVER_HERE)
BUILD_DEPENDS+=	${LOCALBASE}/bin/postmaster:${PORTSDIR}/databases/postgresql${DEFAULT_PGSQL_VER}-server
.endif

pre-everything::
.if (defined(WITH_SOPE_44) && defined(WITH_SOPE_45_DEVEL)) || (defined(WITHOUT_SOPE_44) && defined(WITHOUT_SOPE_45_DEVEL))
	@${ECHO_MSG} "#########################################################################"
	@${ECHO_MSG} "# WARNING!!!   WARNING!!!   WARNING!!!   WARNING!!!   WARNING!!!        #"
	@${ECHO_MSG} "# You must either choose sope44 or sope-devel, not both or even none!   #"
	@${ECHO_MSG} "# Please run 'make config' again...                                     #"
	@${ECHO_MSG} "#   ... or 'make rmconfig' prior your next 'make' attempt               #"
	@${ECHO_MSG} "#########################################################################"
	@exit 1
.endif

do-configure:
	(cd ${WRKSRC}; . ${LOCALBASE}/OGo-GNUstep/System/Library/Makefiles/GNUstep.sh; ./configure)

do-build:
.if (defined(WITH_SOPE_DEVEL) && ((!exists(${LOCALBASE}/lib/libGDLAccess.so.${SOPE_DEVEL_MAJOR}.${SOPE_DEVEL_MINOR})) || (!exists(${LOCALBASE}/lib/libNGLdap.so.${SOPE_DEVEL_MAJOR}.${SOPE_DEVEL_MINOR})) || (!exists(${LOCALBASE}/lib/libNGObjWeb.so.${SOPE_DEVEL_MAJOR}.${SOPE_DEVEL_MINOR})))) || \
	(defined(WITH_SOPE_44) && (!exists(${LOCALBASE}/lib/libGDLAccess.so.${SOPE44_MAJOR}.${SOPE44_MINOR}) || !exists(${LOCALBASE}/lib/libNGLdap.so.${SOPE44_MAJOR}.${SOPE44_MINOR}) || !exists(${LOCALBASE}/lib/libNGObjWeb.so.${SOPE44_MAJOR}.${SOPE44_MINOR})))
	@${ECHO_MSG} "#########################################################################"
	@${ECHO_MSG} "# WARNING!!!   WARNING!!!   WARNING!!!   WARNING!!!   WARNING!!!        #"
	@${ECHO_MSG} "#                                                                       #"
	@${ECHO_MSG} "# OpenGroupware cannot be compiled due to missing SOPE libraries.       #"
	@${ECHO_MSG} "#                                                                       #"
	@${ECHO_MSG} "# This isn't necessarily a 'bug' - chances are that you've compiled     #"
	@${ECHO_MSG} "# SOPE earlier and didn't intend to use it for OpenGroupware at this    #"
	@${ECHO_MSG} "# time.                                                                 #"
	@${ECHO_MSG} "# Please reinstall the SOPE port and use at least the following knobs:  #"
	@${ECHO_MSG} "#                                                                       #"
	@${ECHO_MSG} "#   WITH_LIBXML2  WITH_LDAP  WITH_PQ                                    #"
	@${ECHO_MSG} "#                                                                       #"
	@${ECHO_MSG} "# Thankyou!                                                             #"
	@${ECHO_MSG} "#                                                                       #"
	@${ECHO_MSG} "#########################################################################"
	@exit 1
.endif
	(cd ${WRKSRC}; . ${LOCALBASE}/OGo-GNUstep/System/Library/Makefiles/GNUstep.sh; ${GMAKE} ${MAKE_ARGS})

do-install:
	(cd ${WRKSRC}; . ${LOCALBASE}/OGo-GNUstep/System/Library/Makefiles/GNUstep.sh; ${GMAKE} ${MAKE_ARGS} install)
	@for STRAY_OGO_DIR in ${STRAY_OGO_DIRS}; do \
	  if [ -d ${LOCALBASE}/$${STRAY_OGO_DIR} ]; then \
	    ${ECHO_MSG} "removing stray OGo directory '${LOCALBASE}/$${STRAY_OGO_DIR}'..."; \
	    ${RMDIR} ${LOCALBASE}/$${STRAY_OGO_DIR}; \
	  fi \
	done
	# the following procedure is required because we use 'patch-aa'
	# (and patch-aa is required or we'll end up with a link into WRKSRC in our final installation :/)
	${MKDIR} ${PREFIX}/share/opengroupware.org-${OGO_VERSION}/templates
	${MKDIR} ${PREFIX}/share/opengroupware.org-${OGO_VERSION}/translations
	${MKDIR} ${PREFIX}/share/opengroupware.org-${OGO_VERSION}/www
	${CP} -fRp ${WRKSRC}/WebUI/Templates/* ${PREFIX}/share/opengroupware.org-${OGO_VERSION}/templates
	${CP} -fRp ${WRKSRC}/WebUI/Resources/* ${PREFIX}/share/opengroupware.org-${OGO_VERSION}/translations
	${CP} -fRp ${WRKSRC}/Themes/WebServerResources/* ${PREFIX}/share/opengroupware.org-${OGO_VERSION}/www

post-install:
	 PKG_PREFIX=${PREFIX} ${SH} ${PKGINSTALL} ${PKGNAME} POST-INSTALL

.if !defined(NOPORTDOCS)
	@${MKDIR} ${DOCSDIR}
	@${MKDIR} ${EXAMPLESDIR}
.for example in ${EXAMPLES}
	@${INSTALL_DATA} ${WRKDIR}/${example} ${EXAMPLESDIR}
.endfor
.for doc in ${DOCS}
	@${INSTALL_DATA} ${WRKDIR}/${doc} ${DOCSDIR}
.endfor
.endif

	@${CAT} ${PKGMESSAGE}

.include <bsd.port.post.mk>
