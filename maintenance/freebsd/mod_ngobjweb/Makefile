# New ports collection makefile for:	mod_ngobjweb
# Date created:  10 Sep 2005
# Whom:          Frank Reppin <frank@opengroupware.org>
#
# $FreeBSD$

PORTNAME=	mod_ngobjweb
PORTVERSION=	1.0
PORTREVISION=	1
CATEGORIES=	devel
MASTER_SITES=	http://download.opengroupware.org/nightly/packages/freebsd/sope/
DISTNAME=	sope-mod_ngobjweb-trunk-r1102-200509071705

MAINTAINER=	frank@opengroupware.org
COMMENT=	Apache mod for forwarding HTTP requests to SOPE appl. server instances

DIST_SUBDIR=	ogo-suite

WRKSRC=		${WRKDIR}/sope-mod_ngobjweb
USE_APACHE=	yes
USE_GMAKE=	yes
MAKEFILE=	GNUmakefile
SUB_FILES=	pkg-message pkg-deinstall
SUB_LIST=	AP_RC=${AP_RC} P_NAME=${PORTNAME} P_VERSION=${PORTVERSION}

DOCS=		COPYRIGHT CHANGES README ChangeLog skyrix.conf

.include <bsd.port.pre.mk>

.if exists(${LOCALBASE}/include/apache2/httpd.h) || !exists(${LOCALBASE}/include/apache/httpd.h)
APACHE_PORT=	www/apache2
WITH_APACHE2=	yes
.else
APACHE_PORT=	www/apache13
.endif

.if defined(WITH_APACHE2)
MAKE_ARGS=	APXS=${APXS} APXS_INCLUDE_DIRS=-I${LOCALBASE}/include/apache2
PLIST_SUB=	APACHE=apache2
AP_RC?=		${LOCALBASE}/etc/rc.d/apache2.sh
.else
MAKE_ARGS=	APXS=${APXS} APXS_INCLUDE_DIRS=-I${LOCALBASE}/include/apache
PLIST_SUB=	APACHE=apache
AP_RC?=		${LOCALBASE}/etc/rc.d/apache.sh
.endif

do-build:
	(cd ${WRKSRC}; ${GMAKE} ${MAKE_ARGS})

do-install:
	@${APXS} -i -a -n ngobjweb ${WRKSRC}/mod_ngobjweb.so

post-install:
	@${CAT} ${PKGMESSAGE}

.if !defined(NOPORTDOCS)
	@${MKDIR} ${DOCSDIR}
.for d in ${DOCS}
	@${INSTALL_DATA} ${WRKSRC}/${d} ${DOCSDIR}
.endfor
.endif

.include <bsd.port.post.mk>
