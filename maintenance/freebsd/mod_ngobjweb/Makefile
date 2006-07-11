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
DISTNAME=	sope-mod_ngobjweb-trunk-r1313-200607111102

MAINTAINER=	frank@opengroupware.org
COMMENT=	Apache mod for forwarding HTTP requests to SOPE appl. server instances

DIST_SUBDIR=	ogo-suite

WRKSRC=		${WRKDIR}/sope-mod_ngobjweb
USE_APACHE=	yes
USE_GMAKE=	yes
MAKEFILE=	GNUmakefile
SUB_FILES=	pkg-message pkg-deinstall
SUB_LIST=	AP_RC=${AP_RC} AP_RCCONF=${AP_RCCONF} P_NAME=${PORTNAME} P_VERSION=${PORTVERSION}

DOCS=		COPYRIGHT CHANGES README ChangeLog

.include <bsd.port.pre.mk>

.if exists(${LOCALBASE}/include/apache2/httpd.h) || (!exists(${LOCALBASE}/include/apache/httpd.h) && \
	!exists(${LOCALBASE}/include/apache21/httpd.h) && !exists(${LOCALBASE}/include/apache22/httpd.h))
APACHE_PORT=	www/apache20
WITH_APACHE2=	yes
.elif exists(${LOCALBASE}/include/apache21/httpd.h)
APACHE_PORT=	www/apache21
.elif exists(${LOCALBASE}/include/apache22/httpd.h)
APACHE_PORT=	www/apache22
.else
APACHE_PORT=	www/apache13
.endif

# apache20
.if (${APACHE_PORT} == "www/apache20")
MAKE_ARGS=	APXS=${APXS} APXS_INCLUDE_DIRS=-I${LOCALBASE}/include/apache2
.if exists(${APXS})
AP_LIBEXEC!=	${APXS} -q LIBEXECDIR
.else
AP_LIBEXEC?=	${LOCALBASE}/libexec/apache2
.endif
AP_MOD_DIR?=	${AP_LIBEXEC:S/${PREFIX}//}
AP_RC?=		${LOCALBASE}/etc/rc.d/apache2.sh
AP_RCCONF=	"apache2_enable=\"YES\""
PLIST_SUB=	APACHE=apache2
# apache21
.elif (${APACHE_PORT} == "www/apache21")
MAKE_ARGS=	APXS=${APXS} APXS_INCLUDE_DIRS="-I${LOCALBASE}/include/apache21 -I${LOCALBASE}/include/apr-1"
.if exists(${APXS})
AP_LIBEXEC!=	${APXS} -q LIBEXECDIR
.else
AP_LIBEXEC?=	${LOCALBASE}/libexec/apache21
.endif
AP_MOD_DIR?=	${AP_LIBEXEC:S/${PREFIX}//}
AP_RC?=		${LOCALBASE}/etc/rc.d/apache21.sh
AP_RCCONF=	"apache21_enable=\"YES\""
PLIST_SUB=	APACHE=apache21
# apache22
.elif (${APACHE_PORT} == "www/apache22")
MAKE_ARGS=	APXS=${APXS} APXS_INCLUDE_DIRS="-I${LOCALBASE}/include/apache22 -I${LOCALBASE}/include/apr-1"
.if exists(${APXS})
AP_LIBEXEC!=	${APXS} -q LIBEXECDIR
.else
AP_LIBEXEC?=	${LOCALBASE}/libexec/apache22
.endif
AP_MOD_DIR?=	${AP_LIBEXEC:S/${PREFIX}//}
AP_RC?=		${LOCALBASE}/etc/rc.d/apache22.sh
AP_RCCONF=	"apache22_enable=\"YES\""
PLIST_SUB=	APACHE=apache22
# apache13
.else
MAKE_ARGS=	APXS=${APXS} APXS_INCLUDE_DIRS=-I${LOCALBASE}/include/apache
.if exists(${APXS})
AP_LIBEXEC!=	${APXS} -q LIBEXECDIR
.else
AP_LIBEXEC?=	${LOCALBASE}/libexec/apache
.endif
AP_MOD_DIR?=	${AP_LIBEXEC:S/${PREFIX}//}
AP_RC?=		${LOCALBASE}/etc/rc.d/apache.sh
AP_RCCONF=	"apache_enable=\"YES\""
PLIST_SUB=	APACHE=apache
.endif

do-build:
	(cd ${WRKSRC}; ${GMAKE} ${MAKE_ARGS})

do-install:
	@${APXS} -i -a ${WRKSRC}/ngobjweb_module.so
	@${INSTALL_DATA} ${WRKSRC}/ngobjweb_module.c ${PREFIX}/${AP_MOD_DIR}

post-install:
	@${CAT} ${PKGMESSAGE}

.if !defined(NOPORTDOCS)
	@${MKDIR} ${DOCSDIR}
.for d in ${DOCS}
	@${INSTALL_DATA} ${WRKSRC}/${d} ${DOCSDIR}
.endfor
.endif

.include <bsd.port.post.mk>
