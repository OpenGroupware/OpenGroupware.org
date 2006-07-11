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
DISTNAME=	opengroupware.org-trunk-r1687-200607111102

MAINTAINER=	frank@opengroupware.org
COMMENT=	OpenGroupware suite

BUILD_DEPENDS=	${LOCALBASE}/OGo-GNUstep/Makefiles/GNUstep.csh:${PORTSDIR}/devel/ogo-gnustep-make \
		${LOCALBASE}/lib/libobjc_d.so.lf2.95.3:${PORTSDIR}/devel/ogo-libobjc-lf2 \
		${LOCALBASE}/lib/libFoundation_d.so.1.0:${PORTSDIR}/devel/ogo-libfoundation \
		pkg-config:${PORTSDIR}/devel/pkg-config

UNIQUENAME=	${PORTNAME}-devel
DIST_SUBDIR=	ogo-suite

OGO_VERSION=	1.1
ZIDE_VERSION=	1.5
SUB_FILES=	pkg-install pkg-message ogo-webui.sh ogo-xmlrpcd.sh ogo-nhsd.sh ogo-zidestore.sh \
		ogo-webui-apache.conf ogo-zidestore-apache.conf ogo-xmlrpcd-apache.conf \
		README_APACHE_SETUP README_POSTGRESQL_SETUP
SUB_LIST=	OGO_VERSION=${OGO_VERSION} ZIDE_VERSION=${ZIDE_VERSION} PREFIX=${PREFIX} \
		P_NAME=${PORTNAME} P_VERSION=${PORTVERSION}
DOCS=		README_APACHE_SETUP README_POSTGRESQL_SETUP
DOCSDIR=	${PREFIX}/share/doc/${PORTNAME}-${PORTVERSION}
EXAMPLES=	ogo-webui-apache.conf ogo-xmlrpcd-apache.conf ogo-zidestore-apache.conf
EXAMPLESDIR=	${PREFIX}/share/examples/${PORTNAME}-${PORTVERSION}

OPTIONS=	SOPE_45_DEVEL	"link with sope-4.5" on \
		SOPE_44		"link with sope-4.4" off \
		PDA_SUPPORT     "build with support for PDA" on \
		PGSQLSERVER_HERE  "use PostgreSQL Server ${DEFAULT_PGSQL_VER} on this host?" on

.include <bsd.port.pre.mk>

WRKSRC=		${WRKDIR}/opengroupware.org
INSTALLS_SHLIB=	yes
NO_FILTER_SHLIBS=	yes
USE_OPENLDAP=	yes
USE_RC_SUBR=	ogo-nhsd.sh ogo-webui.sh ogo-xmlrpcd.sh ogo-zidestore.sh
USE_PGSQL=	yes
DEFAULT_PGSQL_VER?=	80
USE_GMAKE=	yes
USE_ICONV=	yes
PREFIX=		${LOCALBASE}
MAKEFILE=	GNUmakefile
MAKE_ARGS=	debug=yes \
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
.if defined(WITH_SOPE_45_DEVEL) || !defined(WITHOUT_SOPE_45_DEVEL)
BUILD_DEPENDS+=	${LOCALBASE}/sbin/sope-4.5:${PORTSDIR}/devel/sope-devel
.endif
.if defined(WITH_PDA_SUPPORT) || !defined(WITHOUT_PDA_SUPPORT)
LIB_DEPENDS+=	pisock.8:${PORTSDIR}/palm/pilot-link
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
	@${ECHO_MSG} "# You must either choose sope-4.4 or sope-4.5, not both or even none!   #"
	@${ECHO_MSG} "# Please run 'make config' again...                                     #"
	@${ECHO_MSG} "#   ... or 'make rmconfig' prior your next 'make' attempt               #"
	@${ECHO_MSG} "#########################################################################"
	@exit 1
.endif

do-build:
.if (defined(WITH_SOPE_45_DEVEL) && ((!exists(${LOCALBASE}/lib/libGDLAccess_d.so.4.5)) || (!exists(${LOCALBASE}/lib/libNGLdap_d.so.4.5)) || (!exists(${LOCALBASE}/lib/libNGObjWeb_d.so.4.5)))) || \
	(defined(WITH_SOPE_44) && (!exists(${LOCALBASE}/lib/libGDLAccess_d.so.4.4) || !exists(${LOCALBASE}/lib/libNGLdap_d.so.4.4) || !exists(${LOCALBASE}/lib/libNGObjWeb_d.so.4.4)))
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
	(cd ${WRKSRC}; . ${LOCALBASE}/OGo-GNUstep/Makefiles/GNUstep.sh; ${GMAKE} ${MAKE_ARGS})

do-install:
	(cd ${WRKSRC}; . ${LOCALBASE}/OGo-GNUstep/Makefiles/GNUstep.sh; ${GMAKE} ${MAKE_ARGS} install)
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
