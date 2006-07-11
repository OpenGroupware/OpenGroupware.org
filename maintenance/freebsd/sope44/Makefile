# New ports collection makefile for:	sope44
# Date created:  08 Sep 2005
# Whom:          Frank Reppin <frank@opengroupware.org>
#
# $FreeBSD$

PORTNAME=	sope
PORTVERSION=	4.4
PORTREVISION=	1
CATEGORIES=	devel
MASTER_SITES=	http://download.opengroupware.org/nightly/packages/freebsd/sope/
DISTNAME=	sope-4.4.0-cell-r1160

MAINTAINER=	frank@opengroupware.org
COMMENT=	SOPE is a framework for developing web applications and services

BUILD_DEPENDS=	${LOCALBASE}/OGo-GNUstep/Library/Makefiles/GNUstep.csh:${PORTSDIR}/devel/ogo-gnustep-make \
		${LOCALBASE}/lib/libobjc_d.so.lf2.95.3:${PORTSDIR}/devel/ogo-libobjc-lf2 \
		${LOCALBASE}/lib/libFoundation_d.so.1.0:${PORTSDIR}/devel/ogo-libfoundation \
		pkg-config:${PORTSDIR}/devel/pkg-config

UNIQUENAME=	${PORTNAME}44
CONFLICTS=	sope-4.5*
DIST_SUBDIR=	ogo-suite

OPTIONS=	LIBXML2		"link with libxml2 (required)" on \
		LDAP		"link with ldap (required)" on \
		PQ		"link with pq (required if you build for OGo)" on \
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
.if defined(WITH_MYSQLCLIENT)
USE_MYSQL=	yes
DEFAULT_MYSQL_VER?=	41
MAKE_ARGS+=	HAS_LIBRARY_mysqlclient=yes
.else
MAKE_ARGS+=	HAS_LIBRARY_mysqlclient=no
.endif

do-build:
	(cd ${WRKSRC}; . ${LOCALBASE}/OGo-GNUstep/Makefiles/GNUstep.sh; ${GMAKE} ${MAKE_ARGS})
.if defined(WITH_MYSQLCLIENT)
	(cd ${WRKSRC}/sope-gdl1/MySQL; . ${LOCALBASE}/OGo-GNUstep/Makefiles/GNUstep.sh; ${GMAKE} ${MAKE_ARGS})
.endif

do-install:
	(cd ${WRKSRC}; . ${LOCALBASE}/OGo-GNUstep/Makefiles/GNUstep.sh; ${GMAKE} ${MAKE_ARGS} install)
.if defined(WITH_MYSQLCLIENT)
	(cd ${WRKSRC}/sope-gdl1/MySQL; . ${LOCALBASE}/OGo-GNUstep/Makefiles/GNUstep.sh; ${GMAKE} ${MAKE_ARGS} install)
.endif

.include <bsd.port.post.mk>
