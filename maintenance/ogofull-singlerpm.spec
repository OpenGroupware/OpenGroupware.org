%define ogoall_version                  1.0alpha12
%define ogoall_release                  1
%define ogoall_buildcount               0
%define ogoall_prefix                   /usr/local
%define ogoall_gstepmake_source         gnustep-make-1.10.0.tar.gz
%define ogoall_gstepmake_makeflags      debug=yes
%define ogoall_libfobjc_source          gnustep-objc-lf2.95.3-r85.tar.gz
%define ogoall_libfobjc_makeflags       debug=yes
%define ogoall_libfoundation_source     libFoundation-1.0.67-r91.tar.gz
%define ogoall_libfoundation_version    1.0.67
%define ogoall_libfoundation_major      1
%define ogoall_libfoundation_minor      0
%define ogoall_libfoundation_makeflags  debug=yes
%define ogoall_sope_source              sope-4.4beta.4-voyager-r638.tar.gz
%define ogoall_sope_major               4
%define ogoall_sope_minor               4
%define ogoall_sope_makeflags           debug=yes
%define ogoall_ogo_source               opengroupware.org-1.0alpha12-ultra-r829.tar.gz
%define ogoall_ogo_makeflags            debug=yes

Summary:       A free and open groupware suite.
Name:          ogoall
Version:       %{ogoall_version}
Release:       %{ogoall_release}.%{ogoall_buildcount}%{dist_suffix}
Vendor:        http://www.opengroupware.org
Packager:      Frank Reppin <frank@opengroupware.org>  
License:       GPL
URL:           http://www.opengroupware.org
Group:         Development/Libraries
AutoReqProv:   off
Source0:       %{ogoall_gstepmake_source}
Source1:       %{ogoall_libfobjc_source}
Source2:       %{ogoall_libfoundation_source}
Source3:       %{ogoall_sope_source}
Source4:       %{ogoall_ogo_source}
Prefix:        %{ogoall_prefix}
BuildRoot:     %{_tmppath}/%{name}-%{version}-%{release}-root
Conflicts:     sope%{ogoall_sope_major}%{ogoall_sope_minor}-xml sope%{ogoall_sope_major}%{ogoall_sope_minor} sope%{ogoall_sope_major}%{ogoall_sope_minor}-xml-devel sope%{ogoall_sope_major}%{ogoall_sope_minor}-xml-tools sope%{ogoall_sope_major}%{ogoall_sope_minor}-core sope%{ogoall_sope_major}%{ogoall_sope_minor}-core-devel sope%{ogoall_sope_major}%{ogoall_sope_minor}-mime sope%{ogoall_sope_major}%{ogoall_sope_minor}-mime-devel sope%{ogoall_sope_major}%{ogoall_sope_minor}-appserver sope%{ogoall_sope_major}%{ogoall_sope_minor}-appserver-devel sope%{ogoall_sope_major}%{ogoall_sope_minor}-appserver-tools sope%{ogoall_sope_major}%{ogoall_sope_minor}-ldap sope%{ogoall_sope_major}%{ogoall_sope_minor}-ldap-devel sope%{ogoall_sope_major}%{ogoall_sope_minor}-ldap-tools sope%{ogoall_sope_major}%{ogoall_sope_minor}-ical sope%{ogoall_sope_major}%{ogoall_sope_minor}-ical-devel sope%{ogoall_sope_major}%{ogoall_sope_minor}-gdl1 sope%{ogoall_sope_major}%{ogoall_sope_minor}-gdl1-postgresql sope%{ogoall_sope_major}%{ogoall_sope_minor}-gdl1-devel ogo-docapi ogo-docapi-fs-project ogo-docapi-fs-project-devel ogo-docapi-db-project ogo-docapi-db-project-devel ogo-docapi-devel ogo-logic ogo-logic-tools ogo-logic-devel ogo-pda ogo-pda-devel ogo-theme-default ogo-theme-ooo ogo-theme-blue ogo-theme-kde ogo-theme-orange ogo-tools ogo-webui-app ogo-webui-core ogo-webui-core-devel ogo-webui-calendar ogo-webui-contact ogo-webui-mailer ogo-webui-mailer-devel ogo-webui-news ogo-webui-task ogo-webui-project ogo-webui-resource-basque ogo-webui-resource-dk ogo-webui-resource-nl ogo-webui-resource-en ogo-webui-resource-fr ogo-webui-resource-de ogo-webui-resource-hu ogo-webui-resource-it ogo-webui-resource-jp ogo-webui-resource-no ogo-webui-resource-pl ogo-webui-resource-pt ogo-webui-resource-es ogo-webui-resource-sk ogo-webui-resource-ptbr ogo-xmlrpcd ogo-zidestore ogo-zidestore-devel libfoundation%{ogoall_libfoundation_major}%{ogoall_libfoundation_minor} libfoundation%{ogoall_libfoundation_major}%{ogoall_libfoundation_minor}-devel libobjc-lf2 libobjc-lf2-devel ogo-database-setup libfoundation libfoundation-devel
Requires:      mod_ngobjweb

%description
OpenGroupware.org aims at being an open source groupware server which
integrates with the leading open source office suite products and all
the leading groupware clients running across all major platforms, and
to provide access to all functionality and data through open XML-based
interfaces and APIs. Additionally it has a web User Interface for
platform independent usage. OpenGroupware.org is built on top of the
SOPE application server.

This is an 'All-in-One' package providing everything needed to evaluate
OpenGroupware.org (you only need to install the mod_ngobjweb for your
distribution separately).

#########################################
%prep
rm -fr ${RPM_BUILD_ROOT}
%setup -T -D -c -q -b0 -b1 -b2 -b3 -b4

# ****************************** build ********************************
%build
OGO_INSTALL_ROOT=${RPM_BUILD_ROOT}%{prefix}/OGo-GNUstep

cd gnustep-make-1.10.0
export CPPFLAGS=-Wno-import
export CFLAGS=-O0
./configure --prefix=${OGO_INSTALL_ROOT} \
  --with-library-combo=gnu-fd-nil \
  --with-user-root=${OGO_INSTALL_ROOT} \
  --with-network-root=${OGO_INSTALL_ROOT} \
  --with-local-root=${OGO_INSTALL_ROOT} \
  --without-system-root

make %{ogoall_gstepmake_makeflags} install
cd ..

source ${RPM_BUILD_ROOT}%{prefix}/OGo-GNUstep/Library/Makefiles/GNUstep.sh

cd libobjc-lf2
make %{ogoall_libfobjc_makeflags} all
make %{ogoall_libfobjc_makeflags} install
cd ..

cd libfoundation
export CFLAGS="-Wno-import -O0"
./configure
make %{ogoall_libfoundation_makeflags} all
mkdir -p ${RPM_BUILD_ROOT}%{prefix}/lib
mkdir -p ${RPM_BUILD_ROOT}%{prefix}/OGo-GNUstep/Library/Makefiles/Additional
make %{ogoall_libfoundation_makeflags} install
cd ..

unset CFLAGS
cd sope
make %{ogoall_sope_makeflags}
make %{ogoall_sope_makeflags} install
cd ..

cd opengroupware.org
make %{ogoall_ogo_makeflags}
cd ..

# ****************************** install ******************************
%install
source ${RPM_BUILD_ROOT}%{prefix}/OGo-GNUstep/Library/Makefiles/GNUstep.sh

# libobjc-lf
cd libobjc-lf2
make %{ogoall_libfobjc_makeflags} GNUSTEP_INSTALLATION_DIR=${RPM_BUILD_ROOT}%{prefix}/OGo-GNUstep install

mkdir -p ${RPM_BUILD_ROOT}%{prefix}/lib
mv ${RPM_BUILD_ROOT}%{prefix}/OGo-GNUstep/Library/Libraries/libobjc*.so.lf2* \
   ${RPM_BUILD_ROOT}%{prefix}/lib/
cd ..

# libFoundation
cd libfoundation
mkdir -p ${RPM_BUILD_ROOT}%{prefix}/lib
mkdir -p ${RPM_BUILD_ROOT}%{prefix}/OGo-GNUstep/Library/Makefiles/Additional

make %{ogoall_libfoundation_makeflags} GNUSTEP_INSTALLATION_DIR=${RPM_BUILD_ROOT}%{prefix} \
                                       FHS_INSTALL_ROOT=${RPM_BUILD_ROOT}%{prefix} \
                                       install

rm -f ${RPM_BUILD_ROOT}%{prefix}/Library/Headers/libFoundation/extensions/exceptions/FoundationException.h
rm -f ${RPM_BUILD_ROOT}%{prefix}/Library/Headers/libFoundation/extensions/exceptions/GeneralExceptions.h
rm -f ${RPM_BUILD_ROOT}%{prefix}/Library/Headers/libFoundation/extensions/exceptions/NSCoderExceptions.h
cd ..

# SOPE
cd sope
mkdir -p ${RPM_BUILD_ROOT}%{prefix}/lib/lib
make %{ogoall_sope_makeflags} INSTALL_ROOT_DIR=${RPM_BUILD_ROOT} \
                              GNUSTEP_INSTALLATION_DIR=${RPM_BUILD_ROOT}%{prefix} \
                              FHS_INSTALL_ROOT=${RPM_BUILD_ROOT}%{prefix} \
                              install

rm -f ${RPM_BUILD_ROOT}%{prefix}/bin/rss2plist1
rm -f ${RPM_BUILD_ROOT}%{prefix}/bin/rss2plist2
rm -f ${RPM_BUILD_ROOT}%{prefix}/bin/rssparse
rm -f ${RPM_BUILD_ROOT}%{prefix}/bin/testqp
cd ..

# OGo
cd opengroupware.org
make %{ogoall_ogo_makeflags} GNUSTEP_INSTALLATION_DIR=${RPM_BUILD_ROOT}%{prefix}/lib/OGo-GNUstep \
                             FHS_INSTALL_ROOT=${RPM_BUILD_ROOT}%{prefix} \
                             BUNDLE_INSTALL_DIR=${RPM_BUILD_ROOT}%{prefix} \
                             WOBUNDLE_INSTALL_DIR=${RPM_BUILD_ROOT}%{prefix} \
                             install

SHAREDIR_OGO="${RPM_BUILD_ROOT}%{prefix}/share/opengroupware.org-1.0a"
SHAREDIR_ZIDE="${RPM_BUILD_ROOT}%{prefix}/share/zidestore-1.3"
rm -f "${SHAREDIR_OGO}/templates"
rm -f "${SHAREDIR_OGO}/translations"
rm -f "${SHAREDIR_OGO}/www"
cp -Rp WebUI/Templates "${SHAREDIR_OGO}/templates"
cp -Rp WebUI/Resources "${SHAREDIR_OGO}/translations"
cp -Rp Themes/WebServerResources "${SHAREDIR_OGO}/www"
rm -fr "${SHAREDIR_OGO}/templates/ChangeLog"
rm -fr "${SHAREDIR_OGO}/templates/GNUmakefile"
rm -fr "${SHAREDIR_OGO}/templates/HelpUI"
rm -fr "${SHAREDIR_OGO}/translations/COPYRIGHT"
rm -fr "${SHAREDIR_OGO}/translations/ChangeLog"
rm -fr "${SHAREDIR_OGO}/translations/GNUmakefile"
rm -fr "${SHAREDIR_OGO}/www/GNUmakefile"
rm -fr "${SHAREDIR_OGO}/www/tools"

#one lonely file for full package...
echo "You've installed OGo %{ogoall_version} using the monolithic mega package!" \
     >"${SHAREDIR_OGO}/INSTALLED.USING.OGOFULLPACKAGE"

#prepare initscript templates
INITSCRIPTS_TMP_DIR_OGO="${SHAREDIR_OGO}/initscript_templates"
INITSCRIPTS_TMP_DIR_ZIDE="${SHAREDIR_ZIDE}/initscript_templates"
mkdir -p ${INITSCRIPTS_TMP_DIR_OGO}
mkdir -p ${INITSCRIPTS_TMP_DIR_ZIDE}
cp %{_specdir}/initscript_templates/redhat_nhsd ${INITSCRIPTS_TMP_DIR_OGO}/
cp %{_specdir}/initscript_templates/redhat_xmlrpcd ${INITSCRIPTS_TMP_DIR_OGO}/
cp %{_specdir}/initscript_templates/redhat_opengroupware ${INITSCRIPTS_TMP_DIR_OGO}/
cp %{_specdir}/initscript_templates/redhat_zidestore ${INITSCRIPTS_TMP_DIR_ZIDE}/
cp %{_specdir}/initscript_templates/suse_nhsd ${INITSCRIPTS_TMP_DIR_OGO}/
cp %{_specdir}/initscript_templates/suse_xmlrpcd ${INITSCRIPTS_TMP_DIR_OGO}/
cp %{_specdir}/initscript_templates/suse_opengroupware ${INITSCRIPTS_TMP_DIR_OGO}/
cp %{_specdir}/initscript_templates/suse_zidestore ${INITSCRIPTS_TMP_DIR_ZIDE}/

#ghost initscripts
INITSCRIPT_DST="${RPM_BUILD_ROOT}%{_sysconfdir}/init.d"
mkdir -p ${INITSCRIPT_DST}
touch ${INITSCRIPT_DST}/ogo-nhsd-1.0a
touch ${INITSCRIPT_DST}/ogo-webui-1.0a
touch ${INITSCRIPT_DST}/ogo-xmlrpcd-1.0a
touch ${INITSCRIPT_DST}/ogo-zidestore-1.3

#template for ogo-aptnotify
APTNOTIFY_TMP_DIR="${SHAREDIR_OGO}/aptnotify_template"
mkdir -p ${APTNOTIFY_TMP_DIR}
cp %{_specdir}/aptnotify_template/ogo-aptnotify.sh ${APTNOTIFY_TMP_DIR}/

#create sysconfig
mkdir -p ${RPM_BUILD_ROOT}%{_sysconfdir}/sysconfig
echo "RUN_DBSCRIPT=\"YES\"                  # will run the whole script - or not, as thou wish
PATCH_POSTGRESQL_CONF=\"YES\"         # will backup and patch postgresql.conf - if needed
PATCH_PGHBA_CONF=\"YES\"              # will backup and patch pg_hba.conf - if needed
CREATE_DB_USER=\"YES\"                # will create a DB user for OpenGroupware.org
CREATE_DB_ITSELF=\"YES\"              # will create the DB itself for OpenGroupware.org
ROLLIN_SCHEME=\"YES\"                 # will roll'in the current base DB scheme of OGo
FORCE_OVERRIDE_PRESENT_SCHEME=\"YES\" # might harm thy current scheme (or not?)
UPDATE_SCHEMA=\"YES\"                 # will attempt to update the database scheme - if needed
OGO_USER=\"ogo\"                      # default username (unix) of your OGo install - might vary
PGCLIENTENCODING=\"LATIN1\"           # client encoding to use
USE_SKYAPTNOTIFY=\"YES\"              # periodically runs aptnotify - or not
" >${RPM_BUILD_ROOT}%{_sysconfdir}/sysconfig/ogo-webui-1.0a

echo "PGCLIENTENCODING=\"LATIN1\"           # client encoding to use
" >${RPM_BUILD_ROOT}%{_sysconfdir}/sysconfig/ogo-nhsd-1.0a

echo "PGCLIENTENCODING=\"LATIN1\"           # client encoding to use
" >${RPM_BUILD_ROOT}%{_sysconfdir}/sysconfig/ogo-xmlrpcd-1.0a

echo "PGCLIENTENCODING=\"LATIN1\"           # client encoding to use
" >${RPM_BUILD_ROOT}%{_sysconfdir}/sysconfig/ogo-zidestore-1.3

mkdir -p ${RPM_BUILD_ROOT}/var/lib/opengroupware.org/.libFoundation/Defaults
mkdir -p ${RPM_BUILD_ROOT}/var/lib/opengroupware.org/documents
mkdir -p ${RPM_BUILD_ROOT}/var/lib/opengroupware.org/news
mkdir -p ${RPM_BUILD_ROOT}/var/log/opengroupware

#from ogo-database-setup
DBSETUP_DEST="${SHAREDIR_OGO}/dbsetup"
mkdir -p ${DBSETUP_DEST}

cp -Rp Database/SQLite ${DBSETUP_DEST}/
cp -Rp Database/PostgreSQL ${DBSETUP_DEST}/
cp -Rp Database/FrontBase ${DBSETUP_DEST}/
cp %{_specdir}/db_setup_template/database_setup_psql.sh ${DBSETUP_DEST}/


#cleanout files we don't want to appear in the ogoall package:
rm -fr ${RPM_BUILD_ROOT}%{prefix}/.GNUsteprc
rm -fr ${RPM_BUILD_ROOT}%{prefix}/OGo-GNUstep
rm -fr ${RPM_BUILD_ROOT}%{prefix}/bin/domxml
rm -fr ${RPM_BUILD_ROOT}%{prefix}/bin/ldap2dsml
rm -fr ${RPM_BUILD_ROOT}%{prefix}/bin/ldapchkpwd
rm -fr ${RPM_BUILD_ROOT}%{prefix}/bin/ldapls
rm -fr ${RPM_BUILD_ROOT}%{prefix}/bin/saxxml
rm -fr ${RPM_BUILD_ROOT}%{prefix}/bin/wod
rm -fr ${RPM_BUILD_ROOT}%{prefix}/bin/xmln
rm -fr ${RPM_BUILD_ROOT}%{prefix}/include

#hm... how dost thou get there?
rm -f ${RPM_BUILD_ROOT}${RPM_BUILD_ROOT}/usr/local/OGo-GNUstep/Library/Makefiles/Additional/ngobjweb.make
rm -f ${RPM_BUILD_ROOT}${RPM_BUILD_ROOT}/usr/local/OGo-GNUstep/Library/Makefiles/woapp.make
rm -f ${RPM_BUILD_ROOT}${RPM_BUILD_ROOT}/usr/local/OGo-GNUstep/Library/Makefiles/wobundle.make

# ****************************** pre **********************************
%pre
if [ $1 = 1 ]; then
  OGO_USER="ogo"
  OGO_GROUP="skyrix"
  OGO_SHELL="/bin/bash"
  OGO_HOME="/var/lib/opengroupware.org"
  echo -en "adding group ${OGO_GROUP}.\n"
  /usr/sbin/groupadd "${OGO_GROUP}" 2>/dev/null || :
  echo -en "adding user ${OGO_USER}.\n"
  /usr/sbin/useradd -c "OpenGroupware.org User" \
                    -s "${OGO_SHELL}" -d "${OGO_HOME}" -g "${OGO_GROUP}" "${OGO_USER}" 2>/dev/null || :
fi

# ****************************** post *********************************
%post
if [ $1 = 1 ]; then
  if [ -d %{_sysconfdir}/ld.so.conf.d ]; then
    echo "%{prefix}/lib" > %{_sysconfdir}/ld.so.conf.d/ogoall.conf
  elif [ ! "`grep '%{prefix}/lib' %{_sysconfdir}/ld.so.conf`" ]; then
    echo "%{prefix}/lib" >> %{_sysconfdir}/ld.so.conf
  fi
  /sbin/ldconfig
  ##
  NHSD_INIT_VERSION="ogo-nhsd-1.0a"
  NHSD_INIT_PREFIX="%{prefix}"
  if [ -f "/etc/SuSE-release" ]; then
    sed "s^NHSD_INIT_VERSION^${NHSD_INIT_VERSION}^g; \
         s^NHSD_INIT_PREFIX^${NHSD_INIT_PREFIX}^g" \
         "%{prefix}/share/opengroupware.org-1.0a/initscript_templates/suse_nhsd" \
         >%{_sysconfdir}/init.d/"${NHSD_INIT_VERSION}"
    chown root:root %{_sysconfdir}/init.d/"${NHSD_INIT_VERSION}"
    chmod 755 %{_sysconfdir}/init.d/"${NHSD_INIT_VERSION}"
    insserv -f %{_sysconfdir}/init.d/"${NHSD_INIT_VERSION}"
    ln -s %{_sysconfdir}/init.d/"${NHSD_INIT_VERSION}" /usr/sbin/rc"${NHSD_INIT_VERSION}"
  else
    sed "s^NHSD_INIT_VERSION^${NHSD_INIT_VERSION}^g; \
         s^NHSD_INIT_PREFIX^${NHSD_INIT_PREFIX}^g" \
         "%{prefix}/share/opengroupware.org-1.0a/initscript_templates/redhat_nhsd" \
         >%{_sysconfdir}/init.d/"${NHSD_INIT_VERSION}"
    chown root:root %{_sysconfdir}/init.d/"${NHSD_INIT_VERSION}"
    chmod 755 %{_sysconfdir}/init.d/"${NHSD_INIT_VERSION}"
    chkconfig --add "${NHSD_INIT_VERSION}"
  fi
  ##
  OGO_INIT_VERSION="ogo-webui-1.0a"
  OGO_INIT_PREFIX="%{prefix}"
  if [ -f "/etc/SuSE-release" ]; then
    sed "s^OGO_INIT_VERSION^${OGO_INIT_VERSION}^g; \
         s^OGO_INIT_PREFIX^${OGO_INIT_PREFIX}^g" \
         "%{prefix}/share/opengroupware.org-1.0a/initscript_templates/suse_opengroupware" \
         >%{_sysconfdir}/init.d/"${OGO_INIT_VERSION}"
    chown root:root %{_sysconfdir}/init.d/"${OGO_INIT_VERSION}"
    chmod 755 %{_sysconfdir}/init.d/"${OGO_INIT_VERSION}"
    insserv -f %{_sysconfdir}/init.d/"${OGO_INIT_VERSION}"
    ln -s %{_sysconfdir}/init.d/"${OGO_INIT_VERSION}" /usr/sbin/rc"${OGO_INIT_VERSION}"
  else
    sed "s^OGO_INIT_VERSION^${OGO_INIT_VERSION}^g; \
         s^OGO_INIT_PREFIX^${OGO_INIT_PREFIX}^g" \
         "%{prefix}/share/opengroupware.org-1.0a/initscript_templates/redhat_opengroupware" \
         >%{_sysconfdir}/init.d/"${OGO_INIT_VERSION}"
    chown root:root %{_sysconfdir}/init.d/"${OGO_INIT_VERSION}"
    chmod 755 %{_sysconfdir}/init.d/"${OGO_INIT_VERSION}"
    chkconfig --add "${OGO_INIT_VERSION}"
    chkconfig "${OGO_INIT_VERSION}" on
  fi
  ##
  XMLRPCD_INIT_VERSION="ogo-xmlrpcd-1.0a"
  XMLRPCD_INIT_PREFIX="%{prefix}"
  if [ -f "/etc/SuSE-release" ]; then
    sed "s^XMLRPCD_INIT_VERSION^${XMLRPCD_INIT_VERSION}^g; \
         s^XMLRPCD_INIT_PREFIX^${XMLRPCD_INIT_PREFIX}^g" \
         "%{prefix}/share/opengroupware.org-1.0a/initscript_templates/suse_xmlrpcd" \
         >%{_sysconfdir}/init.d/"${XMLRPCD_INIT_VERSION}"
    chown root:root %{_sysconfdir}/init.d/"${XMLRPCD_INIT_VERSION}"
    chmod 755 %{_sysconfdir}/init.d/"${XMLRPCD_INIT_VERSION}"
    insserv -f %{_sysconfdir}/init.d/"${XMLRPCD_INIT_VERSION}"
    ln -s %{_sysconfdir}/init.d/"${XMLRPCD_INIT_VERSION}" /usr/sbin/rc"${XMLRPCD_INIT_VERSION}"
  else
    sed "s^XMLRPCD_INIT_VERSION^${XMLRPCD_INIT_VERSION}^g; \
         s^XMLRPCD_INIT_PREFIX^${XMLRPCD_INIT_PREFIX}^g" \
         "%{prefix}/share/opengroupware.org-1.0a/initscript_templates/redhat_xmlrpcd" \
         >%{_sysconfdir}/init.d/"${XMLRPCD_INIT_VERSION}"
    chown root:root %{_sysconfdir}/init.d/"${XMLRPCD_INIT_VERSION}"
    chmod 755 %{_sysconfdir}/init.d/"${XMLRPCD_INIT_VERSION}"
    chkconfig --add "${XMLRPCD_INIT_VERSION}"
  fi
  ##
  ZIDESTORE_INIT_VERSION="ogo-zidestore-1.3"
  ZIDESTORE_INIT_PREFIX="%{prefix}"
  if [ -f "/etc/SuSE-release" ]; then
    sed "s^ZIDESTORE_INIT_VERSION^${ZIDESTORE_INIT_VERSION}^g; \
         s^ZIDESTORE_INIT_PREFIX^${ZIDESTORE_INIT_PREFIX}^g" \
         "%{prefix}/share/zidestore-1.3/initscript_templates/suse_zidestore" \
         >%{_sysconfdir}/init.d/"${ZIDESTORE_INIT_VERSION}"
    chown root:root %{_sysconfdir}/init.d/"${ZIDESTORE_INIT_VERSION}"
    chmod 755 %{_sysconfdir}/init.d/"${ZIDESTORE_INIT_VERSION}"
    insserv -f %{_sysconfdir}/init.d/"${ZIDESTORE_INIT_VERSION}"
    ln -s %{_sysconfdir}/init.d/"${ZIDESTORE_INIT_VERSION}" /usr/sbin/rc"${ZIDESTORE_INIT_VERSION}"
  else
    sed "s^ZIDESTORE_INIT_VERSION^${ZIDESTORE_INIT_VERSION}^g; \
         s^ZIDESTORE_INIT_PREFIX^${ZIDESTORE_INIT_PREFIX}^g" \
         "%{prefix}/share/zidestore-1.3/initscript_templates/redhat_zidestore" \
         >%{_sysconfdir}/init.d/"${ZIDESTORE_INIT_VERSION}"
    chown root:root %{_sysconfdir}/init.d/"${ZIDESTORE_INIT_VERSION}"
    chmod 755 %{_sysconfdir}/init.d/"${ZIDESTORE_INIT_VERSION}"
    chkconfig --add "${ZIDESTORE_INIT_VERSION}"
  fi
  ##
  OGO_SYSCONF="ogo-webui-1.0a"
  OGO_PREFIX="%{prefix}"
  CRON_D="%{_sysconfdir}/cron.d"
  if [ -d "${CRON_D}" ]; then
    echo "*/5 * * * root %{prefix}/bin/ogo-aptnotify.sh >/dev/null" >%{_sysconfdir}/cron.d/ogo-aptnotify
  fi
  sed "s^OGO_SYSCONF^${OGO_SYSCONF}^g; \
       s^OGO_PREFIX^${OGO_PREFIX}^g" \
       "%{prefix}/share/opengroupware.org-1.0a/aptnotify_template/ogo-aptnotify.sh" \
       >"%{prefix}/bin/ogo-aptnotify.sh"
  chmod 750 "%{prefix}/bin/ogo-aptnotify.sh"
  ## link in /etc
  cd %{_sysconfdir}
  ln -s %{_var}/lib/opengroupware.org/.libFoundation opengroupware.org
  ## some defaults
  OGO_USER="ogo"
  OGO_HOME="/var/lib/opengroupware.org"
  export PATH=$PATH:%{prefix}/bin
  su - ${OGO_USER} -c "
  Defaults write NSGlobalDomain LSConnectionDictionary '{hostName=\"127.0.0.1\"; userName=OGo; password=\"\"; port=5432; databaseName=OGo}'
  Defaults write NSGlobalDomain LSNewsImagesPath '/var/lib/opengroupware.org/news'
  Defaults write NSGlobalDomain LSNewsImagesUrl '/ArticleImages'
  Defaults write NSGlobalDomain skyrix_id `hostname`
  Defaults write NSGlobalDomain TimeZoneName GMT
  Defaults write NSGlobalDomain WOHttpAllowHost '( localhost, 127.0.0.1, localhost.localdomain)'
  Defaults write ogo-nhsd-1.0a NGBundlePath '%{prefix}/lib/opengroupware.org-1.0a/conduits'
  "
  ##
  chmod 755 ${OGO_HOME}
  ##
  if [ -f "%{prefix}/share/opengroupware.org-1.0a/dbsetup/database_setup_psql.sh" ]; then
    %{prefix}/share/opengroupware.org-1.0a/dbsetup/database_setup_psql.sh initial
  fi
fi

if [ $1 = 2 ]; then
  OGO_USER="ogo"
  OGO_GROUP="skyrix"
  if [ -e /var/log/opengroupware ]; then
    chown -R ${OGO_USER}:${OGO_GROUP} /var/log/opengroupware
  fi
fi

# ****************************** postun *********************************
%postun
if [ $1 = 0 ]; then
  if [ -e %{_sysconfdir}/ld.so.conf.d/ogoall.conf ]; then
    rm -f %{_sysconfdir}/ld.so.conf.d/ogoall.conf
  fi
  ##
  if [ -L %{prefix}/OGo-GNUstep/Makefiles ]; then
    rm -f %{prefix}/OGo-GNUstep/Makefiles
  fi
  ##
  OGO_USER="ogo"
  OGO_GROUP="skyrix"
  if [ "`getent passwd ${OGO_USER}`" ]; then
    echo -en "removing user ${OGO_USER}.\n"
    /usr/sbin/userdel "${OGO_USER}" 2>/dev/null || :
  fi
  if [ "`getent group ${OGO_GROUP}`" ]; then
    echo -en "removing group ${OGO_GROUP}.\n"
    /usr/sbin/groupdel "${OGO_GROUP}" 2>/dev/null || :
  fi
  if [ -h "/etc/opengroupware.org" ]; then
    rm /etc/opengroupware.org
  fi
  /sbin/ldconfig
fi

# ****************************** preun *********************************
%preun
if [ $1 = 0 ]; then
  NHSD_INIT_VERSION="ogo-nhsd-1.0a"
  NHSD_INIT_PREFIX="%{prefix}"
  if [ -f "%{_sysconfdir}/init.d/${NHSD_INIT_VERSION}" ]; then
    if [ -f "/etc/SuSE-release" ]; then
      "%{_sysconfdir}/init.d/${NHSD_INIT_VERSION}" stop
      insserv --remove "%{_sysconfdir}/init.d/${NHSD_INIT_VERSION}"
      rm -f "%{_sysconfdir}/init.d/${NHSD_INIT_VERSION}"
      rm -f /usr/sbin/rc"${NHSD_INIT_VERSION}"
    else
      service "${NHSD_INIT_VERSION}" stop
      chkconfig "${NHSD_INIT_VERSION}" off
      chkconfig --del "${NHSD_INIT_VERSION}"
      rm -f "%{_sysconfdir}/init.d/${NHSD_INIT_VERSION}"
    fi
  fi
  ##
  OGO_INIT_VERSION="ogo-webui-1.0a"
  OGO_INIT_PREFIX="%{prefix}"
  if [ -f "%{_sysconfdir}/init.d/${OGO_INIT_VERSION}" ]; then
    if [ -f "/etc/SuSE-release" ]; then
      "%{_sysconfdir}/init.d/${OGO_INIT_VERSION}" stop
      insserv --remove "%{_sysconfdir}/init.d/${OGO_INIT_VERSION}"
      rm -f "%{_sysconfdir}/init.d/${OGO_INIT_VERSION}"
      rm -f /usr/sbin/rc"${OGO_INIT_VERSION}"
    else
      service "${OGO_INIT_VERSION}" stop
      chkconfig "${OGO_INIT_VERSION}" off
      chkconfig --del "${OGO_INIT_VERSION}"
      rm -f "%{_sysconfdir}/init.d/${OGO_INIT_VERSION}"
    fi 
  fi
  ##
  XMLRPCD_INIT_VERSION="ogo-xmlrpcd-1.0a"
  XMLRPCD_INIT_PREFIX="%{prefix}"
  if [ -f "%{_sysconfdir}/init.d/${XMLRPCD_INIT_VERSION}" ]; then
    if [ -f "/etc/SuSE-release" ]; then
      "%{_sysconfdir}/init.d/${XMLRPCD_INIT_VERSION}" stop
      insserv --remove "%{_sysconfdir}/init.d/${XMLRPCD_INIT_VERSION}"
      rm -f "%{_sysconfdir}/init.d/${XMLRPCD_INIT_VERSION}"
      rm -f /usr/sbin/rc"${XMLRPCD_INIT_VERSION}"
    else
      service "${XMLRPCD_INIT_VERSION}" stop
      chkconfig "${XMLRPCD_INIT_VERSION}" off
      chkconfig --del "${XMLRPCD_INIT_VERSION}"
      rm -f "%{_sysconfdir}/init.d/${XMLRPCD_INIT_VERSION}"
    fi 
  fi
  ##
  ZIDESTORE_INIT_VERSION="ogo-zidestore-1.3"
  ZIDESTORE_INIT_PREFIX="%{prefix}"
  if [ -f "%{_sysconfdir}/init.d/${ZIDESTORE_INIT_VERSION}" ]; then
    if [ -f "/etc/SuSE-release" ]; then
      "%{_sysconfdir}/init.d/${ZIDESTORE_INIT_VERSION}" stop
      insserv --remove "%{_sysconfdir}/init.d/${ZIDESTORE_INIT_VERSION}"
      rm -f "%{_sysconfdir}/init.d/${ZIDESTORE_INIT_VERSION}"
      rm -f /usr/sbin/rc"${ZIDESTORE_INIT_VERSION}"
    else
      service "${ZIDESTORE_INIT_VERSION}" stop
      chkconfig "${ZIDESTORE_INIT_VERSION}" off
      chkconfig --del "${ZIDESTORE_INIT_VERSION}"
      rm -f "%{_sysconfdir}/init.d/${ZIDESTORE_INIT_VERSION}"
    fi
  fi
  ##
  if [ -f "%{_sysconfdir}/cron.d/ogo-aptnotify" ]; then
    rm -f "%{_sysconfdir}/cron.d/ogo-aptnotify"
  fi
  if [ -f "%{prefix}/bin/ogo-aptnotify.sh" ]; then
    rm -f "%{prefix}/bin/ogo-aptnotify.sh"
  fi
fi

# ****************************** clean ********************************
%clean
rm -fr ${RPM_BUILD_ROOT}

# ****************************** files ********************************
%files
%defattr(-,root,root,-)
# libobjc-lf
%{prefix}/lib/libobjc*.so.lf2*

# libFoundation

%{prefix}/bin/Defaults
%{prefix}/lib/libFoundation*.so.%{ogoall_libfoundation_version}
%{prefix}/lib/libFoundation*.so.%{ogoall_libfoundation_major}.%{ogoall_libfoundation_minor}
%{prefix}/share/libFoundation/CharacterSets
%{prefix}/share/libFoundation/Defaults
%{prefix}/share/libFoundation/TimeZoneInfo

# sope
%{prefix}/bin/connect-EOAdaptor
%{prefix}/bin/load-EOAdaptor
%{prefix}/bin/xmlrpc_call
%{prefix}/lib/libDOM*.so.%{ogoall_sope_major}.%{ogoall_sope_minor}*
%{prefix}/lib/libEOControl*.so.%{ogoall_sope_major}.%{ogoall_sope_minor}*
%{prefix}/lib/libGDLAccess*.so.%{ogoall_sope_major}.%{ogoall_sope_minor}*
%{prefix}/lib/libNGExtensions*.so.%{ogoall_sope_major}.%{ogoall_sope_minor}*
%{prefix}/lib/libNGLdap*.so.%{ogoall_sope_major}.%{ogoall_sope_minor}*
%{prefix}/lib/libNGMime*.so.%{ogoall_sope_major}.%{ogoall_sope_minor}*
%{prefix}/lib/libNGObjWeb*.so.%{ogoall_sope_major}.%{ogoall_sope_minor}*
%{prefix}/lib/libNGStreams*.so.%{ogoall_sope_major}.%{ogoall_sope_minor}*
%{prefix}/lib/libNGXmlRpc*.so.%{ogoall_sope_major}.%{ogoall_sope_minor}*
%{prefix}/lib/libNGiCal*.so.%{ogoall_sope_major}.%{ogoall_sope_minor}*
%{prefix}/lib/libSaxObjC*.so.%{ogoall_sope_major}.%{ogoall_sope_minor}*
%{prefix}/lib/libSoOFS*.so.%{ogoall_sope_major}.%{ogoall_sope_minor}*
%{prefix}/lib/libWEExtensions*.so.%{ogoall_sope_major}.%{ogoall_sope_minor}*
%{prefix}/lib/libWOExtensions*.so.%{ogoall_sope_major}.%{ogoall_sope_minor}*
%{prefix}/lib/libWOXML*.so.%{ogoall_sope_major}.%{ogoall_sope_minor}*
%{prefix}/lib/libXmlRpc*.so.%{ogoall_sope_major}.%{ogoall_sope_minor}*
%{prefix}/lib/sope-%{ogoall_sope_major}.%{ogoall_sope_minor}/dbadaptors/PostgreSQL.gdladaptor
%{prefix}/lib/sope-%{ogoall_sope_major}.%{ogoall_sope_minor}/products/SoCore.sxp
%{prefix}/lib/sope-%{ogoall_sope_major}.%{ogoall_sope_minor}/products/SoOFS.sxp
%{prefix}/lib/sope-%{ogoall_sope_major}.%{ogoall_sope_minor}/saxdrivers/STXSaxDriver.sax
%{prefix}/lib/sope-%{ogoall_sope_major}.%{ogoall_sope_minor}/saxdrivers/libxmlSAXDriver.sax
%{prefix}/lib/sope-%{ogoall_sope_major}.%{ogoall_sope_minor}/saxdrivers/versitSaxDriver.sax
%{prefix}/lib/sope-%{ogoall_sope_major}.%{ogoall_sope_minor}/wox-builders/WEExtensions.wox
%{prefix}/lib/sope-%{ogoall_sope_major}.%{ogoall_sope_minor}/wox-builders/WOExtensions.wox
%{prefix}/sbin/sope-%{ogoall_sope_major}.%{ogoall_sope_minor}
%{prefix}/share/sope-%{ogoall_sope_major}.%{ogoall_sope_minor}/ngobjweb/DAVPropMap.plist
%{prefix}/share/sope-%{ogoall_sope_major}.%{ogoall_sope_minor}/ngobjweb/Defaults.plist
%{prefix}/share/sope-%{ogoall_sope_major}.%{ogoall_sope_minor}/ngobjweb/Languages.plist
%{prefix}/share/sope-%{ogoall_sope_major}.%{ogoall_sope_minor}/saxmappings/NGiCal.xmap

# ogo
%attr(0644,root,root) %config %{_sysconfdir}/sysconfig/ogo-webui-1.0a
%ghost %attr(0755,root,root) %config %{_sysconfdir}/init.d/ogo-webui-1.0a
%{prefix}/bin/load-LSModel
%{prefix}/bin/ogo-ppls-1.0a
%{prefix}/bin/ogo-account-add
%{prefix}/bin/ogo-account-del
%{prefix}/bin/ogo-account-list
%{prefix}/bin/ogo-acl-list
%{prefix}/bin/ogo-check-permission
%{prefix}/bin/ogo-defaults
%{prefix}/bin/ogo-instfilter-procmail
%{prefix}/bin/ogo-jobs-export
%{prefix}/bin/ogo-project-export
%{prefix}/bin/ogo-project-import
%{prefix}/bin/ogo-project-list
%{prefix}/bin/ogo-runcmd
%{prefix}/bin/sky_install_sieve
%{prefix}/bin/sky_send_bulk_messages
%{prefix}/bin/skyaptnotify
%{prefix}/share/opengroupware.org-1.0a/aptnotify_template/ogo-aptnotify.sh
%{prefix}/lib/%{ogo_libogopalmui}.so.5.1*
%{prefix}/lib/%{ogo_libogopalm}.so.5.1*
%{prefix}/lib/libLSAddress*.so.5.1*
%{prefix}/lib/libLSFoundation*.so.5.1*
%{prefix}/lib/libLSSearch*.so.5.1*
%{prefix}/lib/libOGoAccounts*.so.5.1*
%{prefix}/lib/libOGoBase*.so.5.1*
%{prefix}/lib/libOGoContacts*.so.5.1*
%{prefix}/lib/libOGoDatabaseProject*.so.5.1*
%{prefix}/lib/libOGoDocuments*.so.5.1*
%{prefix}/lib/libOGoFileSystemProject*.so.5.1*
%{prefix}/lib/libOGoFoundation*.so.5.1*
%{prefix}/lib/libOGoJobs*.so.5.1*
%{prefix}/lib/libOGoNHS*.so.5.1*
%{prefix}/lib/libOGoProject*.so.5.1*
%{prefix}/lib/libOGoRawDatabase*.so.5.1*
%{prefix}/lib/libOGoScheduler*.so.5.1*
%{prefix}/lib/libOGoSchedulerTools*.so.5.1*
%{prefix}/lib/libOGoWebMail*.so.5.1*
%{prefix}/lib/libPPSync*.so.5.1*
%{prefix}/lib/libZSAppointments*.so.1.3*
%{prefix}/lib/libZSBackend*.so.1.3*
%{prefix}/lib/libZSContacts*.so.1.3*
%{prefix}/lib/libZSFrontend*.so.1.3*
%{prefix}/lib/libZSProjects*.so.1.3*
%{prefix}/lib/libZSTasks*.so.1.3*
%{prefix}/lib/opengroupware.org-1.0a/commands/LSAccount.cmd
%{prefix}/lib/opengroupware.org-1.0a/commands/LSAddress.cmd
%{prefix}/lib/opengroupware.org-1.0a/commands/LSBase.cmd
%{prefix}/lib/opengroupware.org-1.0a/commands/LSDocuments.cmd
%{prefix}/lib/opengroupware.org-1.0a/commands/LSEnterprise.cmd
%{prefix}/lib/opengroupware.org-1.0a/commands/LSMail.cmd
%{prefix}/lib/opengroupware.org-1.0a/commands/LSNews.cmd
%{prefix}/lib/opengroupware.org-1.0a/commands/LSPerson.cmd
%{prefix}/lib/opengroupware.org-1.0a/commands/LSProject.cmd
%{prefix}/lib/opengroupware.org-1.0a/commands/LSScheduler.cmd
%{prefix}/lib/opengroupware.org-1.0a/commands/LSSearch.cmd
%{prefix}/lib/opengroupware.org-1.0a/commands/LSTasks.cmd
%{prefix}/lib/opengroupware.org-1.0a/commands/LSTeam.cmd
%{prefix}/lib/opengroupware.org-1.0a/commands/OGo.model
%{prefix}/lib/opengroupware.org-1.0a/conduits/OpenGroupwareNHS.conduit/OpenGroupwareNHS
%{prefix}/lib/opengroupware.org-1.0a/conduits/OpenGroupwareNHS.conduit/Resources/Info-gnustep.plist
%{prefix}/lib/opengroupware.org-1.0a/conduits/OpenGroupwareNHS.conduit/bundle-info.plist
%{prefix}/lib/opengroupware.org-1.0a/conduits/OpenGroupwareNHS.conduit/stamp.make
%{prefix}/lib/opengroupware.org-1.0a/datasources/OGoAccounts.ds
%{prefix}/lib/opengroupware.org-1.0a/datasources/OGoBase.ds
%{prefix}/lib/opengroupware.org-1.0a/datasources/OGoContacts.ds
%{prefix}/lib/opengroupware.org-1.0a/datasources/OGoDatabaseProject.ds
%{prefix}/lib/opengroupware.org-1.0a/datasources/OGoFileSystemProject.ds
%{prefix}/lib/opengroupware.org-1.0a/datasources/OGoJobs.ds
%{prefix}/lib/opengroupware.org-1.0a/datasources/OGoPalmDS.ds/OGoPalmDS
%{prefix}/lib/opengroupware.org-1.0a/datasources/OGoPalmDS.ds/Resources/Info-gnustep.plist
%{prefix}/lib/opengroupware.org-1.0a/datasources/OGoPalmDS.ds/bundle-info.plist
%{prefix}/lib/opengroupware.org-1.0a/datasources/OGoPalmDS.ds/stamp.make
%{prefix}/lib/opengroupware.org-1.0a/datasources/OGoProject.ds
%{prefix}/lib/opengroupware.org-1.0a/datasources/OGoRawDatabase.ds
%{prefix}/lib/opengroupware.org-1.0a/datasources/OGoScheduler.ds
%{prefix}/lib/opengroupware.org-1.0a/webui/AddressUI.lso
%{prefix}/lib/opengroupware.org-1.0a/webui/AdminUI.lso
%{prefix}/lib/opengroupware.org-1.0a/webui/BaseUI.lso
%{prefix}/lib/opengroupware.org-1.0a/webui/EnterprisesUI.lso
%{prefix}/lib/opengroupware.org-1.0a/webui/JobUI.lso
%{prefix}/lib/opengroupware.org-1.0a/webui/LDAPAccounts.lso
%{prefix}/lib/opengroupware.org-1.0a/webui/LSWMail.lso
%{prefix}/lib/opengroupware.org-1.0a/webui/LSWProject.lso
%{prefix}/lib/opengroupware.org-1.0a/webui/LSWScheduler.lso
%{prefix}/lib/opengroupware.org-1.0a/webui/NewsUI.lso
%{prefix}/lib/opengroupware.org-1.0a/webui/OGoDocInlineViewers.lso
%{prefix}/lib/opengroupware.org-1.0a/webui/OGoMailEditor.lso
%{prefix}/lib/opengroupware.org-1.0a/webui/OGoMailFilter.lso
%{prefix}/lib/opengroupware.org-1.0a/webui/OGoMailInfo.lso
%{prefix}/lib/opengroupware.org-1.0a/webui/OGoMailViewers.lso
%{prefix}/lib/opengroupware.org-1.0a/webui/OGoNote.lso
%{prefix}/lib/opengroupware.org-1.0a/webui/OGoPalm.lso
%{prefix}/lib/opengroupware.org-1.0a/webui/OGoProject.lso
%{prefix}/lib/opengroupware.org-1.0a/webui/OGoProjectInfo.lso
%{prefix}/lib/opengroupware.org-1.0a/webui/OGoProjectZip.lso
%{prefix}/lib/opengroupware.org-1.0a/webui/OGoRecipientLists.lso
%{prefix}/lib/opengroupware.org-1.0a/webui/OGoResourceScheduler.lso
%{prefix}/lib/opengroupware.org-1.0a/webui/OGoScheduler.lso
%{prefix}/lib/opengroupware.org-1.0a/webui/OGoSchedulerDock.lso
%{prefix}/lib/opengroupware.org-1.0a/webui/OGoSchedulerViews.lso
%{prefix}/lib/opengroupware.org-1.0a/webui/OGoUIElements.lso
%{prefix}/lib/opengroupware.org-1.0a/webui/OGoWebMail.lso
%{prefix}/lib/opengroupware.org-1.0a/webui/PersonsUI.lso
%{prefix}/lib/opengroupware.org-1.0a/webui/PreferencesUI.lso
%{prefix}/lib/opengroupware.org-1.0a/webui/PropertiesUI.lso
%{prefix}/lib/opengroupware.org-1.0a/webui/RelatedLinksUI.lso
%{prefix}/lib/opengroupware.org-1.0a/webui/SoOGo.lso
%{prefix}/lib/zidestore-1.3
%{prefix}/sbin/ogo-nhsd-1.0a
%attr(0644,root,root) %config %{_sysconfdir}/sysconfig/ogo-nhsd-1.0a
%ghost %attr(0755,root,root) %config %{_sysconfdir}/init.d/ogo-nhsd-1.0a
%{prefix}/sbin/ogo-webui-1.0a
%{prefix}/sbin/ogo-xmlrpcd-1.0a
%attr(0644,root,root) %config %{_sysconfdir}/sysconfig/ogo-xmlrpcd-1.0a
%ghost %attr(0755,root,root) %config %{_sysconfdir}/init.d/ogo-xmlrpcd-1.0a
%{prefix}/sbin/ogo-zidestore-1.3
%attr(0644,root,root) %config %{_sysconfdir}/sysconfig/ogo-zidestore-1.3
%ghost %attr(0755,root,root) %config %{_sysconfdir}/init.d/ogo-zidestore-1.3
%{prefix}/share/opengroupware.org-1.0a/initscript_templates/*xmlrpcd
%{prefix}/share/zidestore-1.3
%{prefix}/share/opengroupware.org-1.0a/INSTALLED.USING.OGOFULLPACKAGE
%{prefix}/share/opengroupware.org-1.0a/Holidays.plist
%{prefix}/share/opengroupware.org-1.0a/initscript_templates/*nhsd
%{prefix}/share/opengroupware.org-1.0a/initscript_templates/*opengroupware
%{prefix}/share/opengroupware.org-1.0a/templates/AddressUI
%{prefix}/share/opengroupware.org-1.0a/templates/AdminUI
%{prefix}/share/opengroupware.org-1.0a/templates/BaseUI
%{prefix}/share/opengroupware.org-1.0a/templates/EnterprisesUI
%{prefix}/share/opengroupware.org-1.0a/templates/JobUI
%{prefix}/share/opengroupware.org-1.0a/templates/LDAPAccounts
%{prefix}/share/opengroupware.org-1.0a/templates/LSWMail
%{prefix}/share/opengroupware.org-1.0a/templates/LSWProject
%{prefix}/share/opengroupware.org-1.0a/templates/LSWScheduler
%{prefix}/share/opengroupware.org-1.0a/templates/NewsUI
%{prefix}/share/opengroupware.org-1.0a/templates/OGoDocInlineViewers
%{prefix}/share/opengroupware.org-1.0a/templates/OGoMailEditor
%{prefix}/share/opengroupware.org-1.0a/templates/OGoMailFilter
%{prefix}/share/opengroupware.org-1.0a/templates/OGoMailInfo
%{prefix}/share/opengroupware.org-1.0a/templates/OGoMailViewers
%{prefix}/share/opengroupware.org-1.0a/templates/OGoNote
%{prefix}/share/opengroupware.org-1.0a/templates/OGoProject
%{prefix}/share/opengroupware.org-1.0a/templates/OGoProjectInfo
%{prefix}/share/opengroupware.org-1.0a/templates/OGoProjectZip
%{prefix}/share/opengroupware.org-1.0a/templates/OGoRecipientLists
%{prefix}/share/opengroupware.org-1.0a/templates/OGoResourceScheduler
%{prefix}/share/opengroupware.org-1.0a/templates/OGoScheduler
%{prefix}/share/opengroupware.org-1.0a/templates/OGoSchedulerDock
%{prefix}/share/opengroupware.org-1.0a/templates/OGoSchedulerViews
%{prefix}/share/opengroupware.org-1.0a/templates/OGoUIElements
%{prefix}/share/opengroupware.org-1.0a/templates/OGoWebMail
%{prefix}/share/opengroupware.org-1.0a/templates/PersonsUI
%{prefix}/share/opengroupware.org-1.0a/templates/PreferencesUI
%{prefix}/share/opengroupware.org-1.0a/templates/PropertiesUI
%{prefix}/share/opengroupware.org-1.0a/templates/RelatedLinksUI
%{prefix}/share/opengroupware.org-1.0a/templates/Themes/OOo
%{prefix}/share/opengroupware.org-1.0a/templates/Themes/blue
%{prefix}/share/opengroupware.org-1.0a/templates/Themes/kde
%{prefix}/share/opengroupware.org-1.0a/templates/Themes/orange
%{prefix}/share/opengroupware.org-1.0a/templates/ogo-webui-1.0a
%{prefix}/share/opengroupware.org-1.0a/www/Danish.lproj
%{prefix}/share/opengroupware.org-1.0a/www/English.lproj
%{prefix}/share/opengroupware.org-1.0a/www/English_OOo.lproj
%{prefix}/share/opengroupware.org-1.0a/www/English_blue.lproj
%{prefix}/share/opengroupware.org-1.0a/www/English_kde.lproj
%{prefix}/share/opengroupware.org-1.0a/www/English_orange.lproj
%{prefix}/share/opengroupware.org-1.0a/www/German.lproj
%{prefix}/share/opengroupware.org-1.0a/www/German_OOo.lproj
%{prefix}/share/opengroupware.org-1.0a/www/German_blue.lproj
%{prefix}/share/opengroupware.org-1.0a/www/German_orange.lproj
%{prefix}/share/opengroupware.org-1.0a/www/Italian.lproj
%{prefix}/share/opengroupware.org-1.0a/www/Polish.lproj
%{prefix}/share/opengroupware.org-1.0a/www/Spanish.lproj
%{prefix}/share/opengroupware.org-1.0a/www/WOStats.xsl
%{prefix}/share/opengroupware.org-1.0a/www/menu.js

# translations
%{prefix}/share/opengroupware.org-1.0a/translations/Basque.lproj
%{prefix}/share/opengroupware.org-1.0a/translations/Danish.lproj
%{prefix}/share/opengroupware.org-1.0a/translations/Dutch.lproj
%{prefix}/share/opengroupware.org-1.0a/translations/English.lproj
%{prefix}/share/opengroupware.org-1.0a/translations/French.lproj
%{prefix}/share/opengroupware.org-1.0a/translations/German.lproj
%{prefix}/share/opengroupware.org-1.0a/translations/Hungarian.lproj
%{prefix}/share/opengroupware.org-1.0a/translations/Italian.lproj
%{prefix}/share/opengroupware.org-1.0a/translations/Japanese.lproj
%{prefix}/share/opengroupware.org-1.0a/translations/Norwegian.lproj
%{prefix}/share/opengroupware.org-1.0a/translations/Polish.lproj
%{prefix}/share/opengroupware.org-1.0a/translations/Portuguese.lproj
%{prefix}/share/opengroupware.org-1.0a/translations/Slovak.lproj
%{prefix}/share/opengroupware.org-1.0a/translations/Spanish.lproj
%{prefix}/share/opengroupware.org-1.0a/translations/ptBR.lproj

# environment
%dir %attr(700,ogo,skyrix) %{_var}/lib/opengroupware.org/.libFoundation
%dir %attr(700,ogo,skyrix) %{_var}/lib/opengroupware.org/.libFoundation/Defaults
%dir %attr(700,ogo,skyrix) %{_var}/lib/opengroupware.org/documents
%dir %attr(755,ogo,skyrix) %{_var}/lib/opengroupware.org/news
%dir %attr(700,ogo,skyrix) %{_var}/log/opengroupware

# ogo-database-setup
%{prefix}/share/opengroupware.org-1.0a/dbsetup

# ********************************* changelog *************************
%changelog
* Fri May 20 2005 Frank Reppin <frank@opengroupware.org>
- proper ldconfig call in post
* Tue May 10 2005 Helge Hess <hh@opengroupware.org>
- fixed some tool names
- removed LSResource.cmd
* Thu Mar 18 2005 Frank Reppin <frank@opengroupware.org>
- be current and more descriptive descriptive description
- divided sharedir into sharedir_ogo/sharedir_zide
* Thu Mar 17 2005 Frank Reppin <frank@opengroupware.org>
- MFC (SHAREDIR wasn't even known yet...)
* Wed Mar 16 2005 Frank Reppin <frank@opengroupware.org>
- MFC
* Tue Mar 15 2005 Frank Reppin <frank@opengroupware.org>
- MFC
* Thu Mar 10 2005 Frank Reppin <frank@opengroupware.org>
- requires mod_ngobjweb; added ogo-database-setup
* Tue Mar 08 2005 Frank Reppin <frank@opengroupware.org>
- updated for ogo-alpha11
* Tue Mar 01 2005 Frank Reppin <frank@opengroupware.org>
- refix fix.
- added stuff from ogo-environment package
* Sat Feb 26 2005 Frank Reppin <frank@opengroupware.org>
- fixed what could be fixed (remains still broken by design due to
  install stages in build)
* Thu Feb 17 2005 Frank Reppin <frank@opengroupware.org>
- initial build
