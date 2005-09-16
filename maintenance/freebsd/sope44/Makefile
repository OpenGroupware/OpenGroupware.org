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
DISTNAME=	sope-4.4rc.2-rock-r944

MAINTAINER=	frank@opengroupware.org
COMMENT=	SOPE is a framework for developing web applications and services

BUILD_DEPENDS=	${LOCALBASE}/OGo-GNUstep/Makefiles/GNUstep.csh:${PORTSDIR}/devel/ogo-gnustep-make \
		${LOCALBASE}/lib/libobjc_d.so.lf2.95.3:${PORTSDIR}/devel/ogo-libobjc-lf2 \
		${LOCALBASE}/lib/libFoundation_d.so.1.0:${PORTSDIR}/devel/ogo-libfoundation \
		pkg-config:${PORTSDIR}/devel/pkgconfig

UNIQUENAME=	${PORTNAME}44
CONFLICTS=	sope-4.5*
DIST_SUBDIR=	ogo-suite

OPTIONS=	LIBXML2		"link with libxml2" on \
		LDAP		"link with ldap" on \
		PQ		"link with pq" on \
		SSL		"link with ssl" on \
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
.if defined(WITH_MYSQLCLIENT)
USE_MYSQL=	yes
MAKE_ARGS+=	HAS_LIBRARY_mysqlclient=yes
.else
MAKE_ARGS+=	HAS_LIBRARY_mysqlclient=no
.endif

do-build:
	(cd ${WRKSRC}; . ${LOCALBASE}/OGo-GNUstep/Makefiles/GNUstep.sh; ${GMAKE} ${MAKE_ARGS})

do-install:
	(cd ${WRKSRC}; . ${LOCALBASE}/OGo-GNUstep/Makefiles/GNUstep.sh; ${GMAKE} ${MAKE_ARGS} install)

.include <bsd.port.post.mk>
