%define smaj 4
%define smin 5
%define lfmaj 1
%define lfmin 0
%define ogo_v 1.1
%define zide_v 1.5
%define libogo_v 5.3

Summary:       A free and open groupware suite.
Name:          ogo
Version:       %{ogo_version}
Release:       %{ogo_release}.%{ogo_buildcount}%{dist_suffix}
Vendor:        http://www.opengroupware.org
Packager:      Frank Reppin <frank@opengroupware.org>  
License:       GPL
URL:           http://www.opengroupware.org
Group:         Development/Libraries
AutoReqProv:   off
Source:        %{ogo_source}
Prefix:        %{ogo_prefix}
BuildRoot:     %{_tmppath}/%{name}-%{version}-%{release}-root
BuildPreReq:   ogo-gnustep_make
#UseSOPE:      trunk

%description
OpenGroupware.org aims at being an open source groupware server which
integrates with the leading open source office suite products and all
the leading groupware clients running across all major platforms, and
to provide access to all functionality and data through open XML-based
interfaces and APIs. Additionally it has a web User Interface for
platform independent usage. OpenGroupware.org is built on top of the
SOPE application server.

%package meta
Summary:      OpenGroupware.org META package
Group:        Development/Libraries
Requires:     libobjc-lf2 libfoundation%{lfmaj}%{lfmin} sope%{smaj}%{smin}-xml sope%{smaj}%{smin}-core sope%{smaj}%{smin}-mime sope%{smaj}%{smin}-appserver sope%{smaj}%{smin}-ldap sope%{smaj}%{smin}-ical sope%{smaj}%{smin}-gdl1-postgresql sope%{smaj}%{smin}-gdl1 ogo-docapi ogo-docapi-db-project ogo-docapi-fs-project ogo-logic ogo-logic-tools ogo-pda ogo-theme-default ogo-tools ogo-webui-app ogo-webui-calendar ogo-webui-contact ogo-webui-core ogo-webui-mailer ogo-webui-news ogo-webui-project ogo-webui-resource-de ogo-webui-resource-en ogo-webui-task ogo-xmlrpcd ogo-zidestore ogo-environment mod_ngobjweb
AutoReqProv:  off

%description meta
A so called META package which attempts to install
everything needed in order to run OpenGroupware.org
(this includes ZideStore and XMLRPCD as well as NHSD).
The package itself doesn't provide anything except
a lot of dependencies.
#########################################
%package docapi
Summary:      OpenGroupware.org document API
Group:        Development/Libraries
Requires:     sope%{smaj}%{smin}-core sope%{smaj}%{smin}-gdl1 sope%{smaj}%{smin}-ldap sope%{smaj}%{smin}-mime sope%{smaj}%{smin}-xml ogo-logic libfoundation%{lfmaj}%{lfmin}
AutoReqProv:  off

%description docapi
The Document API is a set of Objective-C libraries wrapping the SOPE
logic in a "document" API.

%package docapi-fs-project
Summary:      Filesystem storage for OpenGroupware.org projects
Group:        Development/Libraries
Requires:     sope%{smaj}%{smin}-core sope%{smaj}%{smin}-gdl1 sope%{smaj}%{smin}-ldap sope%{smaj}%{smin}-mime sope%{smaj}%{smin}-xml ogo-docapi ogo-logic libfoundation%{lfmaj}%{lfmin}
AutoReqProv:  off

%description docapi-fs-project
Files associated to OpenGroupware.org projects can be stored through different
storage backends. This package contains the filesystem storage backend, which
stores all files on the hosts filesystem.

%package docapi-fs-project-devel
Summary:      Development files for OpenGroupware.org's filesystem storage
Group:        Development/Libraries
Requires:     ogo-docapi-fs-project
AutoReqProv:  off

%description docapi-fs-project-devel
This package contains the development files for the ogo-docapi-fs-project package.

%package docapi-db-project
Summary:      Database storage for OpenGroupware.org projects
Group:        Development/Libraries
Requires:     sope%{smaj}%{smin}-core sope%{smaj}%{smin}-gdl1 sope%{smaj}%{smin}-ldap sope%{smaj}%{smin}-mime sope%{smaj}%{smin}-xml ogo-docapi ogo-logic libfoundation%{lfmaj}%{lfmin}
AutoReqProv:  off

%description docapi-db-project
Files associated to OpenGroupware.org projects can be stored through different
storage backends. This package contains the database storage backend.

%package docapi-db-project-devel
Summary:      Development files for OpenGroupware.org's database storage
Group:        Development/Libraries
Requires:     ogo-docapi-db-project
AutoReqProv:  off

%description docapi-db-project-devel
This package contains the development files for the ogo-docapi-db-project package.

%package docapi-devel
Summary:      Development files for the ogo-docapi package.
Group:        Development/Libraries
Requires:     ogo-gnustep_make ogo-docapi
AutoReqProv:  off

%description docapi-devel
This package contains the development files for the ogo-docapi package.
#########################################
%package logic
Summary:      OpenGroupware.org application logic
Group:        Development/Libraries
Requires:     sope%{smaj}%{smin}-core sope%{smaj}%{smin}-gdl1 sope%{smaj}%{smin}-ldap sope%{smaj}%{smin}-mime sope%{smaj}%{smin}-xml libfoundation%{lfmaj}%{lfmin}
AutoReqProv:  off

%description logic
This package contains OpenGroupware.org's application logic.
##
%package logic-tools
Summary:      OpenGroupware.org application logic tools
Group:        Development/Libraries
Requires:     ogo-logic sope%{smaj}%{smin}-core sope%{smaj}%{smin}-gdl1 sope%{smaj}%{smin}-ldap sope%{smaj}%{smin}-mime sope%{smaj}%{smin}-xml libfoundation%{lfmaj}%{lfmin} libobjc-lf2
AutoReqProv:  off

%description logic-tools
This package contains OpenGroupware.org application logic tools

 * load-LSModel

##
%package logic-devel
Summary:      Development files for the OpenGroupware.org application logic
Group:        Development/Libraries
Requires:     ogo-gnustep_make ogo-logic
AutoReqProv:  off

%description logic-devel
This package contains the development files for the OpenGroupware.org
application logic.
#########################################
%package pda
Summary:      PDA syncing framework for OpenGroupware.org
Group:        Development/Libraries
Requires:     sope%{smaj}%{smin}-gdl1 sope%{smaj}%{smin}-core sope%{smaj}%{smin}-xml sope%{smaj}%{smin}-ldap libfoundation%{lfmaj}%{lfmin} libobjc-lf2 ogo-webui-app ogo-docapi ogo-logic pilot-link
AutoReqProv:  off

%description pda
This package contains the PDA syncing framework for OpenGroupware.org.

%package pda-devel
Summary:      Development files for the PDA syncing framework of OpenGroupware.org
Group:        Development/Libraries
Requires:     ogo-gnustep_make ogo-pda
AutoReqProv:  off

%description pda-devel
This package contains the development files for the PDA syncing
framework of OpenGroupware.org
#########################################
%package theme-default
Summary:      Default theme for OpenGroupware.org's web UI
Group:        Development/Libraries
Requires:     ogo-webui-app
AutoReqProv:  off

%description theme-default
This package contains the default theme for OpenGroupware.org's web UI.
##
%package theme-ooo
Summary:      OOo alike theme for OpenGroupware.org's web UI
Group:        Development/Libraries
Requires:     ogo-webui-app
AutoReqProv:  off

%description theme-ooo
This package contains an OOo alike theme for OpenGroupware.org's web UI.
##
%package theme-blue
Summary:      Blue theme for OpenGroupware.org's web UI.
Group:        Development/Libraries
Requires:     ogo-webui-app
AutoReqProv:  off

%description theme-blue
This package contains a blue theme for OpenGroupware.org's web UI.
##
%package theme-kde
Summary:      KDE alike theme for OpenGroupware.org's web UI.
Group:        Development/Libraries
Requires:     ogo-webui-app
AutoReqProv:  off

%description theme-kde
This package contains a KDE alike theme for OpenGroupware.org's web UI.
##
%package theme-orange
Summary:      Orange theme for OpenGroupware.org's web UI.
Group:        Development/Libraries
Requires:     ogo-webui-app
AutoReqProv:  off

%description theme-orange
This package contains an orange theme for OpenGroupware.org's web UI.
#########################################
%package tools
Summary:      Various commandline Tools for OpenGroupware.org
Group:        Development/Libraries
Requires:     sope%{smaj}%{smin}-core sope%{smaj}%{smin}-mime sope%{smaj}%{smin}-xml sope%{smaj}%{smin}-ldap sope%{smaj}%{smin}-gdl1 libfoundation%{lfmaj}%{lfmin} libobjc-lf2 ogo-logic ogo-docapi
AutoReqProv:  off

%description tools
Various tools for OpenGroupware.org.
You might especially consider installing this package
if you want to use certain functionalities provided
with the ogo-webui-mailer package:

  * sky_send_bulk_messages - required for mailing lists in the
                             OpenGroupware.org webmailer.
  * sky_install_sieve - required for installing Sieve filters
                        from within the OpenGroupware.org webmailer.

#########################################
%package webui-app
Summary:      Web UI application of OpenGroupware.org
Group:        Development/Libraries
Requires:     sope%{smaj}%{smin}-appserver sope%{smaj}%{smin}-core sope%{smaj}%{smin}-gdl1 sope%{smaj}%{smin}-ldap sope%{smaj}%{smin}-mime sope%{smaj}%{smin}-xml ogo-webui-core ogo-logic ogo-docapi ogo-theme-default ogo-webui-resource-en ogo-webui-resource-de libfoundation%{lfmaj}%{lfmin} libobjc-lf2
AutoReqProv:  off

%description webui-app
This package contains the executable and resources of
OpenGroupware.org's web application server.
#
%package webui-core
Summary:      Core elements for OpenGroupware.org's Web UI
Group:        Development/Libraries
Requires:     sope%{smaj}%{smin}-core sope%{smaj}%{smin}-gdl1 sope%{smaj}%{smin}-ldap sope%{smaj}%{smin}-mime sope%{smaj}%{smin}-xml ogo-docapi ogo-logic ogo-logic-tools libfoundation%{lfmaj}%{lfmin}
AutoReqProv:  off

%description webui-core
This package contains UI elements that are used in various components
of OpenGroupware.org's web frontend.
##
%package webui-core-devel
Summary:      Development files for the core elements of OpenGroupware.org's Web UI
Group:        Development/Libraries
Requires:     ogo-gnustep_make ogo-webui-core
AutoReqProv:  off

%description webui-core-devel
This package contains the development files for the core elements
of OpenGroupware.org's Web UI
##
%package webui-calendar
Summary:      Calendar component of OpenGroupware.org's Web UI
Group:        Development/Libraries
Requires:     sope%{smaj}%{smin}-appserver sope%{smaj}%{smin}-core sope%{smaj}%{smin}-gdl1 sope%{smaj}%{smin}-ldap sope%{smaj}%{smin}-mime sope%{smaj}%{smin}-xml ogo-docapi ogo-logic ogo-webui-app ogo-webui-core libfoundation%{lfmaj}%{lfmin} libobjc-lf2
AutoReqProv:  off

%description webui-calendar
The calendar component provides personal and shared calendars for
OpenGroupware.org's web UI. It allows to create and manage appointments
for individuals and groups and can also detect collisions when creating
new appointments.
##
%package webui-contact
Summary:      Contact component of OpenGroupware.org's Web UI
Group:        Development/Libraries
Requires:     sope%{smaj}%{smin}-appserver sope%{smaj}%{smin}-core sope%{smaj}%{smin}-gdl1 sope%{smaj}%{smin}-ldap sope%{smaj}%{smin}-mime sope%{smaj}%{smin}-xml ogo-docapi ogo-logic ogo-webui-app ogo-webui-core libfoundation%{lfmaj}%{lfmin} libobjc-lf2
AutoReqProv:  off

%description webui-contact
The contact component lets users add and manage contacts of individuals
or companies. Import and export of vcf files is supported, as well as
importing contacts from a csv file.
##
%package webui-mailer
Summary:      Mailer component of OpenGroupware.org's Web UI
Group:        Development/Libraries
Requires:     sope%{smaj}%{smin}-appserver sope%{smaj}%{smin}-core sope%{smaj}%{smin}-gdl1 sope%{smaj}%{smin}-ldap sope%{smaj}%{smin}-mime sope%{smaj}%{smin}-xml ogo-docapi ogo-logic ogo-webui-app ogo-webui-core libfoundation%{lfmaj}%{lfmin} libobjc-lf2
AutoReqProv:  off

%description webui-mailer
This package contains a webmail application for OpenGroupware.org's
web UI. It needs an IMAP server for the mail feed and and SMTP server
to enable the users to send mail.
##
%package webui-mailer-devel
Summary:      Development files for the mailer component of OpenGroupware.org's Web UI
Group:        Development/Libraries
Requires:     ogo-webui-mailer
AutoReqProv:  off

%description webui-mailer-devel
This package contains the development files for the mailer component
of OpenGroupware.org's Web UI
##
%package webui-news
Summary:      News component of OpenGroupware.org's Web UI
Group:        Development/Libraries
Requires:     sope%{smaj}%{smin}-appserver sope%{smaj}%{smin}-core sope%{smaj}%{smin}-gdl1 sope%{smaj}%{smin}-ldap sope%{smaj}%{smin}-mime sope%{smaj}%{smin}-xml ogo-docapi ogo-logic ogo-webui-app ogo-webui-core libfoundation%{lfmaj}%{lfmin} libobjc-lf2
AutoReqProv:  off

%description webui-news
The news component shows recent appointments and tasks for each user.
Additionally it supports the creation and display of simple news items.
##
%package webui-task
Summary:      Task component of OpenGroupware.org's Web UI
Group:        Development/Libraries
Requires:     ogo-webui-app ogo-webui-core
AutoReqProv:  off

%description webui-task
The task component enables users to assign and manage tasks
related to projects or standalone.
##
%package webui-project
Summary:      Project component of OpenGroupware.org's Web UI
Group:        Development/Libraries
Requires:     sope%{smaj}%{smin}-appserver sope%{smaj}%{smin}-core sope%{smaj}%{smin}-gdl1 sope%{smaj}%{smin}-ldap sope%{smaj}%{smin}-mime sope%{smaj}%{smin}-xml ogo-docapi ogo-logic ogo-webui-app ogo-webui-core libfoundation%{lfmaj}%{lfmin} libobjc-lf2
AutoReqProv:  off

%description webui-project
The project component adds project management capabilities to
OpenGroupware.org's web UI. It allows to assign and track a
project's status, add documents and links and interworks nicely
with the task component to assign specific tasks within a project.
##
%package webui-resource-basque
Summary:      Basque translation for OpenGroupware.org's web UI
Group:        Development/Libraries
Requires:     ogo-webui-app
AutoReqProv:  off

%description webui-resource-basque
This package contains the Basque translation for OpenGroupware.org's web UI.
##
%package webui-resource-dk
Summary:      Danish translation for OpenGroupware.org's web UI
Group:        Development/Libraries
Requires:     ogo-webui-app
AutoReqProv:  off

%description webui-resource-dk
This package contains the Danish translation for OpenGroupware.org's web UI.
##
%package webui-resource-nl
Summary:      Dutch translation for OpenGroupware.org's web UI
Group:        Development/Libraries
Requires:     ogo-webui-app
AutoReqProv:  off

%description webui-resource-nl
This package contains the Dutch translation for OpenGroupware.org's web UI.
##
%package webui-resource-en
Summary:      English translation for OpenGroupware.org's web UI
Group:        Development/Libraries
Requires:     ogo-webui-app
AutoReqProv:  off

%description webui-resource-en
This package contains the English translation for OpenGroupware.org's web UI.
##
%package webui-resource-fr
Summary:      French translation for OpenGroupware.org's web UI
Group:        Development/Libraries
Requires:     ogo-webui-app
AutoReqProv:  off

%description webui-resource-fr
This package contains the French translation for OpenGroupware.org's web UI.
##
%package webui-resource-de
Summary:      German translation for OpenGroupware.org's web UI
Group:        Development/Libraries
Requires:     ogo-webui-app
AutoReqProv:  off

%description webui-resource-de
This package contains the German translation for OpenGroupware.org's web UI.
##
%package webui-resource-hu
Summary:      Hungarian translation for OpenGroupware.org's web UI
Group:        Development/Libraries
Requires:     ogo-webui-app
AutoReqProv:  off

%description webui-resource-hu
This package contains the Hungarian translation for OpenGroupware.org's web UI.
##
%package webui-resource-it
Summary:      Italian translation for OpenGroupware.org's web UI
Group:        Development/Libraries
Requires:     ogo-webui-app
AutoReqProv:  off

%description webui-resource-it
This package contains the Italian translation for OpenGroupware.org's web UI.
##
%package webui-resource-jp
Summary:      Japanese translation for OpenGroupware.org's web UI
Group:        Development/Libraries
Requires:     ogo-webui-app
AutoReqProv:  off

%description webui-resource-jp
This package contains the Japanese translation for OpenGroupware.org's web UI.
##
%package webui-resource-no
Summary:      Norwegian translation for OpenGroupware.org's web UI
Group:        Development/Libraries
Requires:     ogo-webui-app
AutoReqProv:  off

%description webui-resource-no
This package contains the Norwegian translation for OpenGroupware.org's web UI.
##
%package webui-resource-pl
Summary:      Polish translation for OpenGroupware.org's web UI
Group:        Development/Libraries
Requires:     ogo-webui-app
AutoReqProv:  off

%description webui-resource-pl
This package contains the Polish translation for OpenGroupware.org's web UI.
##
%package webui-resource-pt
Summary:      Portuguese translation for OpenGroupware.org's web UI
Group:        Development/Libraries
Requires:     ogo-webui-app
AutoReqProv:  off

%description webui-resource-pt
This package contains the Portuguese translation for OpenGroupware.org's web UI.
##
%package webui-resource-es
Summary:      Spanish translation for OpenGroupware.org's web UI
Group:        Development/Libraries
Requires:     ogo-webui-app
AutoReqProv:  off

%description webui-resource-es
This package contains the Spanish translation for OpenGroupware.org's web UI.
##
%package webui-resource-sk
Summary:      Slovak translation for OpenGroupware.org's web UI
Group:        Development/Libraries
Requires:     ogo-webui-app
AutoReqProv:  off

%description webui-resource-sk
This package contains the Slovak translation for OpenGroupware.org's web UI.
##
%package webui-resource-ptbr
Summary:      Portuguese (Brazilian) translation for OpenGroupware.org's web UI
Group:        Development/Libraries
Requires:     ogo-webui-app
AutoReqProv:  off

%description webui-resource-ptbr
This package contains the Portuguese (Brazilian) translation for OpenGroupware.org's web UI.
#########################################
%package xmlrpcd
Summary:      XMLRPC daemon for OpenGroupware.org
Group:        Development/Libraries
Requires:     sope%{smaj}%{smin}-appserver sope%{smaj}%{smin}-gdl1 sope%{smaj}%{smin}-mime sope%{smaj}%{smin}-ldap sope%{smaj}%{smin}-core sope%{smaj}%{smin}-xml libfoundation%{lfmaj}%{lfmin} libobjc-lf2 ogo-logic ogo-docapi
AutoReqProv:  off

%description xmlrpcd
The XMLRPC daemon allows to execute groupware functions over the standardized
XMLRPC API. This is especially useful within scripts or custom applications.
#########################################
%package zidestore
Summary:      ZideStore server for OpenGroupware.org
Group:        Development/Libraries
Requires:     sope%{smaj}%{smin}-appserver sope%{smaj}%{smin}-gdl1 sope%{smaj}%{smin}-ical sope%{smaj}%{smin}-mime sope%{smaj}%{smin}-core sope%{smaj}%{smin}-xml sope%{smaj}%{smin}-ldap ogo-logic libfoundation%{lfmaj}%{lfmin}
AutoReqProv:  off

%description zidestore
The ZideStore Server provides WebDAV access to the OpenGroupware.org
data. It can be used to connect native groupware clients with
OpenGroupware.org. Currently supported are calendaring clients that use
iCal subscriptions, an Ximian Evolution plugin is under development.

%package zidestore-devel
Summary:      Development Files for the ZideStore server
Group:        Development/Libraries
Requires:     ogo-gnustep_make ogo-zidestore
AutoReqProv:  off

%description zidestore-devel
This package contains development files for the OpenGroupware.org ZideStore
server.
#########################################
%prep
rm -fr ${RPM_BUILD_ROOT}
%setup -q -n opengroupware.org

# ****************************** build ********************************
%build
./configure --prefix=${RPM_BUILD_ROOT}%{prefix} \
            --enable-debug \
            --gsmake=%{prefix}/OGo-GNUstep

make %{ogo_makeflags}

# ****************************** install ******************************
%install
FAKE_GSROOT="${RPM_BUILD_ROOT}%{prefix}/lib/OGo-GNUstep"
mkdir -p ${FAKE_GSROOT}

make %{ogo_makeflags} GNUSTEP_INSTALLATION_DIR=${FAKE_GSROOT} \
                      BUNDLE_INSTALL_DIR=${RPM_BUILD_ROOT}%{prefix} \
                      WOBUNDLE_INSTALL_DIR=${RPM_BUILD_ROOT}%{prefix} \
                      install

SHAREDIR="${RPM_BUILD_ROOT}%{prefix}/share/opengroupware.org-%{ogo_v}"
rm -f "${SHAREDIR}/templates"
rm -f "${SHAREDIR}/translations"
rm -f "${SHAREDIR}/www"
cp -Rp WebUI/Templates "${SHAREDIR}/templates"
cp -Rp WebUI/Resources "${SHAREDIR}/translations"
cp -Rp Themes/WebServerResources "${SHAREDIR}/www"
rm -fr "${SHAREDIR}/templates/ChangeLog"
rm -fr "${SHAREDIR}/templates/GNUmakefile"
rm -fr "${SHAREDIR}/templates/HelpUI"
rm -fr "${SHAREDIR}/translations/COPYRIGHT"
rm -fr "${SHAREDIR}/translations/ChangeLog"
rm -fr "${SHAREDIR}/translations/GNUmakefile"
rm -fr "${SHAREDIR}/www/GNUmakefile"
rm -fr "${SHAREDIR}/www/tools"

#one lonely file for meta package...
echo "You've installed OGo %{ogo_version}-%{ogo_release} using the meta package!" \
     >"${SHAREDIR}/INSTALLED.USING.METAPACKAGE"

#prepare initscript templates
INITSCRIPTS_TMP_DIR_OGO="${SHAREDIR}/initscript_templates"
INITSCRIPTS_TMP_DIR_ZIDE="${RPM_BUILD_ROOT}%{prefix}/share/zidestore-%{zide_v}/initscript_templates"
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
touch ${INITSCRIPT_DST}/ogo-nhsd
touch ${INITSCRIPT_DST}/ogo-webui
touch ${INITSCRIPT_DST}/ogo-xmlrpcd
touch ${INITSCRIPT_DST}/ogo-zidestore

#template for ogo-aptnotify
APTNOTIFY_TMP_DIR="${SHAREDIR}/aptnotify_template"
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
" >${RPM_BUILD_ROOT}%{_sysconfdir}/sysconfig/ogo-webui

echo "PGCLIENTENCODING=\"LATIN1\"           # client encoding to use
" >${RPM_BUILD_ROOT}%{_sysconfdir}/sysconfig/ogo-nhsd

echo "PGCLIENTENCODING=\"LATIN1\"           # client encoding to use
" >${RPM_BUILD_ROOT}%{_sysconfdir}/sysconfig/ogo-xmlrpcd

echo "PGCLIENTENCODING=\"LATIN1\"           # client encoding to use
" >${RPM_BUILD_ROOT}%{_sysconfdir}/sysconfig/ogo-zidestore

# ****************************** post *********************************
%post meta
if [ $1 = 1 ]; then
  /sbin/ldconfig
fi

%post docapi
/sbin/ldconfig

%post docapi-fs-project
/sbin/ldconfig

%post docapi-db-project
/sbin/ldconfig

%post logic
/sbin/ldconfig

%post webui-core
/sbin/ldconfig

%post webui-mailer
/sbin/ldconfig

%post tools
if [ $1 = 1 ]; then
  OGO_SYSCONF="ogo-webui"
  OGO_PREFIX="%{prefix}"
  CRON_D="%{_sysconfdir}/cron.d"
  if [ -d "${CRON_D}" ]; then
    echo "*/5 * * * root %{prefix}/bin/ogo-aptnotify.sh >/dev/null" >%{_sysconfdir}/cron.d/ogo-aptnotify
  fi
  sed "s^OGO_SYSCONF^${OGO_SYSCONF}^g; \
       s^OGO_PREFIX^${OGO_PREFIX}^g" \
       "%{prefix}/share/opengroupware.org-%{ogo_v}/aptnotify_template/ogo-aptnotify.sh" \
       >"%{prefix}/bin/ogo-aptnotify.sh"
  chmod 750 "%{prefix}/bin/ogo-aptnotify.sh"
fi

if [ $1 = 2 ]; then
  OGO_SYSCONF="ogo-webui"
  OGO_PREFIX="%{prefix}"
  CRON_D="%{_sysconfdir}/cron.d"
  if [ -d "${CRON_D}" ]; then
    echo "*/5 * * * root %{prefix}/bin/ogo-aptnotify.sh >/dev/null" >%{_sysconfdir}/cron.d/ogo-aptnotify
  fi
  sed "s^OGO_SYSCONF^${OGO_SYSCONF}^g; \
       s^OGO_PREFIX^${OGO_PREFIX}^g" \
       "%{prefix}/share/opengroupware.org-%{ogo_v}/aptnotify_template/ogo-aptnotify.sh" \
       >"%{prefix}/bin/ogo-aptnotify.sh"
  chmod 750 "%{prefix}/bin/ogo-aptnotify.sh"
fi

%post pda
if [ $1 = 1 ]; then
  NHSD_INIT_NAME="ogo-nhsd"
  NHSD_INIT_VERSION="ogo-nhsd-%{ogo_v}"
  NHSD_INIT_PREFIX="%{prefix}"
  if [ -f "/etc/SuSE-release" ]; then
    sed "s^NHSD_INIT_VERSION^${NHSD_INIT_VERSION}^g; \
         s^NHSD_INIT_PREFIX^${NHSD_INIT_PREFIX}^g" \
         "%{prefix}/share/opengroupware.org-%{ogo_v}/initscript_templates/suse_nhsd" \
         >%{_sysconfdir}/init.d/"${NHSD_INIT_NAME}"
    chown root:root %{_sysconfdir}/init.d/"${NHSD_INIT_NAME}"
    chmod 755 %{_sysconfdir}/init.d/"${NHSD_INIT_NAME}"
    insserv -f %{_sysconfdir}/init.d/"${NHSD_INIT_NAME}"
    ln -s %{_sysconfdir}/init.d/"${NHSD_INIT_NAME}" /usr/sbin/rc"${NHSD_INIT_NAME}"
  else
    sed "s^NHSD_INIT_VERSION^${NHSD_INIT_VERSION}^g; \
         s^NHSD_INIT_PREFIX^${NHSD_INIT_PREFIX}^g" \
         "%{prefix}/share/opengroupware.org-%{ogo_v}/initscript_templates/redhat_nhsd" \
         >%{_sysconfdir}/init.d/"${NHSD_INIT_NAME}"
    chown root:root %{_sysconfdir}/init.d/"${NHSD_INIT_NAME}"
    chmod 755 %{_sysconfdir}/init.d/"${NHSD_INIT_NAME}"
    chkconfig --add "${NHSD_INIT_NAME}"
  fi
  /sbin/ldconfig
fi

if [ $1 = 2 ]; then
  NHSD_INIT_NAME="ogo-nhsd"
  NHSD_INIT_VERSION="ogo-nhsd-%{ogo_v}"
  NHSD_INIT_PREFIX="%{prefix}"
  if [ ! -f "/etc/init.d/ogo-nhsd" ]; then
    if [ -f "/etc/SuSE-release" ]; then
      sed "s^NHSD_INIT_VERSION^${NHSD_INIT_VERSION}^g; \
           s^NHSD_INIT_PREFIX^${NHSD_INIT_PREFIX}^g" \
           "%{prefix}/share/opengroupware.org-%{ogo_v}/initscript_templates/suse_nhsd" \
           >%{_sysconfdir}/init.d/"${NHSD_INIT_NAME}"
      chown root:root %{_sysconfdir}/init.d/"${NHSD_INIT_NAME}"
      chmod 755 %{_sysconfdir}/init.d/"${NHSD_INIT_NAME}"
      insserv -f %{_sysconfdir}/init.d/"${NHSD_INIT_NAME}"
      ln -s %{_sysconfdir}/init.d/"${NHSD_INIT_NAME}" /usr/sbin/rc"${NHSD_INIT_NAME}"
    else
      sed "s^NHSD_INIT_VERSION^${NHSD_INIT_VERSION}^g; \
           s^NHSD_INIT_PREFIX^${NHSD_INIT_PREFIX}^g" \
           "%{prefix}/share/opengroupware.org-%{ogo_v}/initscript_templates/redhat_nhsd" \
           >%{_sysconfdir}/init.d/"${NHSD_INIT_NAME}"
      chown root:root %{_sysconfdir}/init.d/"${NHSD_INIT_NAME}"
      chmod 755 %{_sysconfdir}/init.d/"${NHSD_INIT_NAME}"
      chkconfig --add "${NHSD_INIT_NAME}"
      /sbin/ldconfig
    fi
  else
    if [ -f "/etc/SuSE-release" ]; then
      sed "s^NHSD_INIT_VERSION^${NHSD_INIT_VERSION}^g; \
           s^NHSD_INIT_PREFIX^${NHSD_INIT_PREFIX}^g" \
           "%{prefix}/share/opengroupware.org-%{ogo_v}/initscript_templates/suse_nhsd" \
           >%{_sysconfdir}/init.d/"${NHSD_INIT_NAME}"
    else
      sed "s^NHSD_INIT_VERSION^${NHSD_INIT_VERSION}^g; \
           s^NHSD_INIT_PREFIX^${NHSD_INIT_PREFIX}^g" \
           "%{prefix}/share/opengroupware.org-%{ogo_v}/initscript_templates/redhat_nhsd" \
           >%{_sysconfdir}/init.d/"${NHSD_INIT_NAME}"
    fi
    chown root:root %{_sysconfdir}/init.d/"${NHSD_INIT_NAME}"
    chmod 755 %{_sysconfdir}/init.d/"${NHSD_INIT_NAME}"
  fi
  /sbin/ldconfig
  if [ -f "%{_sysconfdir}/init.d/${NHSD_INIT_NAME}" ]; then
    "%{_sysconfdir}/init.d/${NHSD_INIT_NAME}" restart >/dev/null 2>&1
  fi
fi

%post webui-app
if [ $1 = 1 ]; then
  OGO_INIT_NAME="ogo-webui"
  OGO_INIT_VERSION="ogo-webui-%{ogo_v}"
  OGO_INIT_PREFIX="%{prefix}"
  if [ -f "/etc/SuSE-release" ]; then
    sed "s^OGO_INIT_VERSION^${OGO_INIT_VERSION}^g; \
         s^OGO_INIT_PREFIX^${OGO_INIT_PREFIX}^g" \
         "%{prefix}/share/opengroupware.org-%{ogo_v}/initscript_templates/suse_opengroupware" \
         >%{_sysconfdir}/init.d/"${OGO_INIT_NAME}"
    chown root:root %{_sysconfdir}/init.d/"${OGO_INIT_NAME}"
    chmod 755 %{_sysconfdir}/init.d/"${OGO_INIT_NAME}"
    insserv -f %{_sysconfdir}/init.d/"${OGO_INIT_NAME}"
    ln -s %{_sysconfdir}/init.d/"${OGO_INIT_NAME}" /usr/sbin/rc"${OGO_INIT_NAME}"
  else
    sed "s^OGO_INIT_VERSION^${OGO_INIT_VERSION}^g; \
         s^OGO_INIT_PREFIX^${OGO_INIT_PREFIX}^g" \
         "%{prefix}/share/opengroupware.org-%{ogo_v}/initscript_templates/redhat_opengroupware" \
         >%{_sysconfdir}/init.d/"${OGO_INIT_NAME}"
    chown root:root %{_sysconfdir}/init.d/"${OGO_INIT_NAME}"
    chmod 755 %{_sysconfdir}/init.d/"${OGO_INIT_NAME}"
    chkconfig --add "${OGO_INIT_NAME}"
    chkconfig "${OGO_INIT_NAME}" on
  fi
  ##
  if [ -d %{_sysconfdir}/ld.so.conf.d ]; then
    echo "%{prefix}/lib" > %{_sysconfdir}/ld.so.conf.d/ogo.conf
  elif [ ! "`grep '%{prefix}/lib' %{_sysconfdir}/ld.so.conf`" ]; then
    echo "%{prefix}/lib" >> %{_sysconfdir}/ld.so.conf
  fi
  /sbin/ldconfig
fi

if [ $1 = 2 ]; then
  OGO_INIT_NAME="ogo-webui"
  OGO_INIT_VERSION="ogo-webui-%{ogo_v}"
  OGO_INIT_PREFIX="%{prefix}"
  if [ ! -f "/etc/init.d/ogo-webui" ]; then
    if [ -f "/etc/SuSE-release" ]; then
      sed "s^OGO_INIT_VERSION^${OGO_INIT_VERSION}^g; \
           s^OGO_INIT_PREFIX^${OGO_INIT_PREFIX}^g" \
           "%{prefix}/share/opengroupware.org-%{ogo_v}/initscript_templates/suse_opengroupware" \
           >%{_sysconfdir}/init.d/"${OGO_INIT_NAME}"
      chown root:root %{_sysconfdir}/init.d/"${OGO_INIT_NAME}"
      chmod 755 %{_sysconfdir}/init.d/"${OGO_INIT_NAME}"
      insserv -f %{_sysconfdir}/init.d/"${OGO_INIT_NAME}"
      ln -s %{_sysconfdir}/init.d/"${OGO_INIT_NAME}" /usr/sbin/rc"${OGO_INIT_NAME}"
    else
      sed "s^OGO_INIT_VERSION^${OGO_INIT_VERSION}^g; \
           s^OGO_INIT_PREFIX^${OGO_INIT_PREFIX}^g" \
           "%{prefix}/share/opengroupware.org-%{ogo_v}/initscript_templates/redhat_opengroupware" \
           >%{_sysconfdir}/init.d/"${OGO_INIT_NAME}"
      chown root:root %{_sysconfdir}/init.d/"${OGO_INIT_NAME}"
      chmod 755 %{_sysconfdir}/init.d/"${OGO_INIT_NAME}"
      chkconfig --add "${OGO_INIT_NAME}"
      chkconfig "${OGO_INIT_NAME}" on
    fi
  else
    if [ -f "/etc/SuSE-release" ]; then
      sed "s^OGO_INIT_VERSION^${OGO_INIT_VERSION}^g; \
           s^OGO_INIT_PREFIX^${OGO_INIT_PREFIX}^g" \
           "%{prefix}/share/opengroupware.org-%{ogo_v}/initscript_templates/suse_opengroupware" \
           >%{_sysconfdir}/init.d/"${OGO_INIT_NAME}"
    else
      sed "s^OGO_INIT_VERSION^${OGO_INIT_VERSION}^g; \
           s^OGO_INIT_PREFIX^${OGO_INIT_PREFIX}^g" \
           "%{prefix}/share/opengroupware.org-%{ogo_v}/initscript_templates/redhat_opengroupware" \
           >%{_sysconfdir}/init.d/"${OGO_INIT_NAME}"
    fi
    chown root:root %{_sysconfdir}/init.d/"${OGO_INIT_NAME}"
    chmod 755 %{_sysconfdir}/init.d/"${OGO_INIT_NAME}"
  fi
  /sbin/ldconfig
  if [ -f "%{_sysconfdir}/init.d/${OGO_INIT_NAME}" ]; then
    "%{_sysconfdir}/init.d/${OGO_INIT_NAME}" restart >/dev/null 2>&1
  fi
fi

%post xmlrpcd
if [ $1 = 1 ]; then
  XMLRPCD_INIT_NAME="ogo-xmlrpcd"
  XMLRPCD_INIT_VERSION="ogo-xmlrpcd-%{ogo_v}"
  XMLRPCD_INIT_PREFIX="%{prefix}"
  if [ -f "/etc/SuSE-release" ]; then
    sed "s^XMLRPCD_INIT_VERSION^${XMLRPCD_INIT_VERSION}^g; \
         s^XMLRPCD_INIT_PREFIX^${XMLRPCD_INIT_PREFIX}^g" \
         "%{prefix}/share/opengroupware.org-%{ogo_v}/initscript_templates/suse_xmlrpcd" \
         >%{_sysconfdir}/init.d/"${XMLRPCD_INIT_NAME}"
    chown root:root %{_sysconfdir}/init.d/"${XMLRPCD_INIT_NAME}"
    chmod 755 %{_sysconfdir}/init.d/"${XMLRPCD_INIT_NAME}"
    insserv -f %{_sysconfdir}/init.d/"${XMLRPCD_INIT_NAME}"
    ln -s %{_sysconfdir}/init.d/"${XMLRPCD_INIT_NAME}" /usr/sbin/rc"${XMLRPCD_INIT_NAME}"
  else
    sed "s^XMLRPCD_INIT_VERSION^${XMLRPCD_INIT_VERSION}^g; \
         s^XMLRPCD_INIT_PREFIX^${XMLRPCD_INIT_PREFIX}^g" \
         "%{prefix}/share/opengroupware.org-%{ogo_v}/initscript_templates/redhat_xmlrpcd" \
         >%{_sysconfdir}/init.d/"${XMLRPCD_INIT_NAME}"
    chown root:root %{_sysconfdir}/init.d/"${XMLRPCD_INIT_NAME}"
    chmod 755 %{_sysconfdir}/init.d/"${XMLRPCD_INIT_NAME}"
    chkconfig --add "${XMLRPCD_INIT_NAME}"
  fi
  /sbin/ldconfig
fi

if [ $1 = 2 ]; then
  XMLRPCD_INIT_NAME="ogo-xmlrpcd"
  XMLRPCD_INIT_VERSION="ogo-xmlrpcd-%{ogo_v}"
  XMLRPCD_INIT_PREFIX="%{prefix}"
  if [ ! -f "/etc/init.d/ogo-xmlrpcd" ]; then
    if [ -f "/etc/SuSE-release" ]; then
      sed "s^XMLRPCD_INIT_VERSION^${XMLRPCD_INIT_VERSION}^g; \
           s^XMLRPCD_INIT_PREFIX^${XMLRPCD_INIT_PREFIX}^g" \
           "%{prefix}/share/opengroupware.org-%{ogo_v}/initscript_templates/suse_xmlrpcd" \
           >%{_sysconfdir}/init.d/"${XMLRPCD_INIT_NAME}"
      chown root:root %{_sysconfdir}/init.d/"${XMLRPCD_INIT_NAME}"
      chmod 755 %{_sysconfdir}/init.d/"${XMLRPCD_INIT_NAME}"
      insserv -f %{_sysconfdir}/init.d/"${XMLRPCD_INIT_NAME}"
      ln -s %{_sysconfdir}/init.d/"${XMLRPCD_INIT_NAME}" /usr/sbin/rc"${XMLRPCD_INIT_NAME}"
    else
      sed "s^XMLRPCD_INIT_VERSION^${XMLRPCD_INIT_VERSION}^g; \
           s^XMLRPCD_INIT_PREFIX^${XMLRPCD_INIT_PREFIX}^g" \
           "%{prefix}/share/opengroupware.org-%{ogo_v}/initscript_templates/redhat_xmlrpcd" \
           >%{_sysconfdir}/init.d/"${XMLRPCD_INIT_NAME}"
      chown root:root %{_sysconfdir}/init.d/"${XMLRPCD_INIT_NAME}"
      chmod 755 %{_sysconfdir}/init.d/"${XMLRPCD_INIT_NAME}"
      chkconfig --add "${XMLRPCD_INIT_NAME}"
      /sbin/ldconfig
    fi
  else
    if [ -f "/etc/SuSE-release" ]; then
      sed "s^XMLRPCD_INIT_VERSION^${XMLRPCD_INIT_VERSION}^g; \
           s^XMLRPCD_INIT_PREFIX^${XMLRPCD_INIT_PREFIX}^g" \
           "%{prefix}/share/opengroupware.org-%{ogo_v}/initscript_templates/suse_xmlrpcd" \
           >%{_sysconfdir}/init.d/"${XMLRPCD_INIT_NAME}"
    else
      sed "s^XMLRPCD_INIT_VERSION^${XMLRPCD_INIT_VERSION}^g; \
           s^XMLRPCD_INIT_PREFIX^${XMLRPCD_INIT_PREFIX}^g" \
           "%{prefix}/share/opengroupware.org-%{ogo_v}/initscript_templates/redhat_xmlrpcd" \
           >%{_sysconfdir}/init.d/"${XMLRPCD_INIT_NAME}"
    fi
    chown root:root %{_sysconfdir}/init.d/"${XMLRPCD_INIT_NAME}"
    chmod 755 %{_sysconfdir}/init.d/"${XMLRPCD_INIT_NAME}"
  fi
  /sbin/ldconfig
  if [ -f "%{_sysconfdir}/init.d/${XMLRPCD_INIT_NAME}" ]; then
    "%{_sysconfdir}/init.d/${XMLRPCD_INIT_NAME}" restart >/dev/null 2>&1
  fi
fi

%post zidestore
if [ $1 = 1 ]; then
  ZIDESTORE_INIT_NAME="ogo-zidestore"
  ZIDESTORE_INIT_VERSION="ogo-zidestore-%{zide_v}"
  ZIDESTORE_INIT_PREFIX="%{prefix}"
  if [ -f "/etc/SuSE-release" ]; then
    sed "s^ZIDESTORE_INIT_VERSION^${ZIDESTORE_INIT_VERSION}^g; \
         s^ZIDESTORE_INIT_PREFIX^${ZIDESTORE_INIT_PREFIX}^g" \
         "%{prefix}/share/zidestore-%{zide_v}/initscript_templates/suse_zidestore" \
         >%{_sysconfdir}/init.d/"${ZIDESTORE_INIT_NAME}"
    chown root:root %{_sysconfdir}/init.d/"${ZIDESTORE_INIT_NAME}"
    chmod 755 %{_sysconfdir}/init.d/"${ZIDESTORE_INIT_NAME}"
    insserv -f %{_sysconfdir}/init.d/"${ZIDESTORE_INIT_NAME}"
    ln -s %{_sysconfdir}/init.d/"${ZIDESTORE_INIT_NAME}" /usr/sbin/rc"${ZIDESTORE_INIT_NAME}"
  else
    sed "s^ZIDESTORE_INIT_VERSION^${ZIDESTORE_INIT_VERSION}^g; \
         s^ZIDESTORE_INIT_PREFIX^${ZIDESTORE_INIT_PREFIX}^g" \
         "%{prefix}/share/zidestore-%{zide_v}/initscript_templates/redhat_zidestore" \
         >%{_sysconfdir}/init.d/"${ZIDESTORE_INIT_NAME}"
    chown root:root %{_sysconfdir}/init.d/"${ZIDESTORE_INIT_NAME}"
    chmod 755 %{_sysconfdir}/init.d/"${ZIDESTORE_INIT_NAME}"
    chkconfig --add "${ZIDESTORE_INIT_NAME}"
  fi
  /sbin/ldconfig
fi

if [ $1 = 2 ]; then
  ZIDESTORE_INIT_NAME="ogo-zidestore"
  ZIDESTORE_INIT_VERSION="ogo-zidestore-%{zide_v}"
  ZIDESTORE_INIT_PREFIX="%{prefix}"
  if [ ! -f "/etc/init.d/ogo-zidestore" ]; then
    if [ -f "/etc/SuSE-release" ]; then
      sed "s^ZIDESTORE_INIT_VERSION^${ZIDESTORE_INIT_VERSION}^g; \
           s^ZIDESTORE_INIT_PREFIX^${ZIDESTORE_INIT_PREFIX}^g" \
           "%{prefix}/share/zidestore-%{zide_v}/initscript_templates/suse_zidestore" \
           >%{_sysconfdir}/init.d/"${ZIDESTORE_INIT_NAME}"
      chown root:root %{_sysconfdir}/init.d/"${ZIDESTORE_INIT_NAME}"
      chmod 755 %{_sysconfdir}/init.d/"${ZIDESTORE_INIT_NAME}"
      insserv -f %{_sysconfdir}/init.d/"${ZIDESTORE_INIT_NAME}"
      ln -s %{_sysconfdir}/init.d/"${ZIDESTORE_INIT_NAME}" /usr/sbin/rc"${ZIDESTORE_INIT_NAME}"
    else
      sed "s^ZIDESTORE_INIT_VERSION^${ZIDESTORE_INIT_VERSION}^g; \
           s^ZIDESTORE_INIT_PREFIX^${ZIDESTORE_INIT_PREFIX}^g" \
           "%{prefix}/share/zidestore-%{zide_v}/initscript_templates/redhat_zidestore" \
           >%{_sysconfdir}/init.d/"${ZIDESTORE_INIT_NAME}"
      chown root:root %{_sysconfdir}/init.d/"${ZIDESTORE_INIT_NAME}"
      chmod 755 %{_sysconfdir}/init.d/"${ZIDESTORE_INIT_NAME}"
      chkconfig --add "${ZIDESTORE_INIT_NAME}"
      /sbin/ldconfig
    fi
  else
    if [ -f "/etc/SuSE-release" ]; then
      sed "s^ZIDESTORE_INIT_VERSION^${ZIDESTORE_INIT_VERSION}^g; \
           s^ZIDESTORE_INIT_PREFIX^${ZIDESTORE_INIT_PREFIX}^g" \
           "%{prefix}/share/zidestore-%{zide_v}/initscript_templates/suse_zidestore" \
           >%{_sysconfdir}/init.d/"${ZIDESTORE_INIT_NAME}"
    else
      sed "s^ZIDESTORE_INIT_VERSION^${ZIDESTORE_INIT_VERSION}^g; \
           s^ZIDESTORE_INIT_PREFIX^${ZIDESTORE_INIT_PREFIX}^g" \
           "%{prefix}/share/zidestore-%{zide_v}/initscript_templates/redhat_zidestore" \
           >%{_sysconfdir}/init.d/"${ZIDESTORE_INIT_NAME}"
    fi
    chown root:root %{_sysconfdir}/init.d/"${ZIDESTORE_INIT_NAME}"
    chmod 755 %{_sysconfdir}/init.d/"${ZIDESTORE_INIT_NAME}"
  fi
  /sbin/ldconfig
  if [ -f "%{_sysconfdir}/init.d/${ZIDESTORE_INIT_NAME}" ]; then
    "%{_sysconfdir}/init.d/${ZIDESTORE_INIT_NAME}" restart >/dev/null 2>&1
  fi
fi

# ****************************** preun *********************************
%preun tools
if [ $1 = 0 ]; then
  if [ -f "%{_sysconfdir}/cron.d/ogo-aptnotify" ]; then
    rm -f "%{_sysconfdir}/cron.d/ogo-aptnotify"
  fi
  if [ -f "%{prefix}/bin/ogo-aptnotify.sh" ]; then
    rm -f "%{prefix}/bin/ogo-aptnotify.sh"
  fi
fi

%preun pda
if [ $1 = 0 ]; then
  NHSD_INIT_NAME="ogo-nhsd"
  NHSD_INIT_VERSION="ogo-nhsd-%{ogo_v}"
  NHSD_INIT_PREFIX="%{prefix}"
  if [ -f "%{_sysconfdir}/init.d/${NHSD_INIT_NAME}" ]; then
    if [ -f "/etc/SuSE-release" ]; then
      "%{_sysconfdir}/init.d/${NHSD_INIT_NAME}" stop
      insserv --remove "%{_sysconfdir}/init.d/${NHSD_INIT_NAME}"
      rm -f "%{_sysconfdir}/init.d/${NHSD_INIT_NAME}"
      rm -f /usr/sbin/rc"${NHSD_INIT_NAME}"
    else
      service "${NHSD_INIT_NAME}" stop
      chkconfig "${NHSD_INIT_NAME}" off
      chkconfig --del "${NHSD_INIT_NAME}"
      rm -f "%{_sysconfdir}/init.d/${NHSD_INIT_NAME}"
    fi
  fi
  /sbin/ldconfig
fi

%pre pda
if [ $1 = 2 ]; then
  NHSD_OLD_INIT="ogo-nhsd-1.0a"
  if [ -f "%{_sysconfdir}/init.d/${NHSD_OLD_INIT}" ]; then
    if [ -f "/etc/SuSE-release" ]; then
      "%{_sysconfdir}/init.d/${NHSD_OLD_INIT}" stop
      insserv --remove "%{_sysconfdir}/init.d/${NHSD_OLD_INIT}"
      rm -f "%{_sysconfdir}/init.d/${NHSD_OLD_INIT}"
      rm -f /usr/sbin/rc"${NHSD_OLD_INIT}"
    else
      service "${NHSD_OLD_INIT}" stop
      chkconfig "${NHSD_OLD_INIT}" off
      chkconfig --del "${NHSD_OLD_INIT}"
      rm -f "%{_sysconfdir}/init.d/${NHSD_OLD_INIT}"
    fi
  fi 
fi  

%preun webui-app
if [ $1 = 0 ]; then
  OGO_INIT_NAME="ogo-webui"
  OGO_INIT_VERSION="ogo-webui-%{ogo_v}"
  OGO_INIT_PREFIX="%{prefix}"
  if [ -f "%{_sysconfdir}/init.d/${OGO_INIT_NAME}" ]; then
    if [ -f "/etc/SuSE-release" ]; then
      "%{_sysconfdir}/init.d/${OGO_INIT_NAME}" stop
      insserv --remove "%{_sysconfdir}/init.d/${OGO_INIT_NAME}"
      rm -f "%{_sysconfdir}/init.d/${OGO_INIT_NAME}"
      rm -f /usr/sbin/rc"${OGO_INIT_NAME}"
    else
      service "${OGO_INIT_NAME}" stop
      chkconfig "${OGO_INIT_NAME}" off
      chkconfig --del "${OGO_INIT_NAME}"
      rm -f "%{_sysconfdir}/init.d/${OGO_INIT_NAME}"
    fi 
  fi
  ##
  if [ -e %{_sysconfdir}/ld.so.conf.d/ogo.conf ]; then
    rm -f %{_sysconfdir}/ld.so.conf.d/ogo.conf
  fi
  /sbin/ldconfig
fi

%pre webui-app
if [ $1 = 2 ]; then
  WEBUI_OLD_INIT="ogo-webui-1.0a"
  if [ -f "%{_sysconfdir}/init.d/${WEBUI_OLD_INIT}" ]; then
    if [ -f "/etc/SuSE-release" ]; then
      "%{_sysconfdir}/init.d/${WEBUI_OLD_INIT}" stop
      insserv --remove "%{_sysconfdir}/init.d/${WEBUI_OLD_INIT}"
      rm -f "%{_sysconfdir}/init.d/${WEBUI_OLD_INIT}"
      rm -f /usr/sbin/rc"${WEBUI_OLD_INIT}"
    else
      service "${WEBUI_OLD_INIT}" stop
      chkconfig "${WEBUI_OLD_INIT}" off
      chkconfig --del "${WEBUI_OLD_INIT}"
      rm -f "%{_sysconfdir}/init.d/${WEBUI_OLD_INIT}"
    fi
  fi 
fi  

%preun xmlrpcd
if [ $1 = 0 ]; then
  XMLRPCD_INIT_NAME="ogo-xmlrpcd"
  XMLRPCD_INIT_VERSION="ogo-xmlrpcd-%{ogo_v}"
  XMLRPCD_INIT_PREFIX="%{prefix}"
  if [ -f "%{_sysconfdir}/init.d/${XMLRPCD_INIT_NAME}" ]; then
    if [ -f "/etc/SuSE-release" ]; then
      "%{_sysconfdir}/init.d/${XMLRPCD_INIT_NAME}" stop
      insserv --remove "%{_sysconfdir}/init.d/${XMLRPCD_INIT_NAME}"
      rm -f "%{_sysconfdir}/init.d/${XMLRPCD_INIT_NAME}"
      rm -f /usr/sbin/rc"${XMLRPCD_INIT_NAME}"
    else
      service "${XMLRPCD_INIT_NAME}" stop
      chkconfig "${XMLRPCD_INIT_NAME}" off
      chkconfig --del "${XMLRPCD_INIT_NAME}"
      rm -f "%{_sysconfdir}/init.d/${XMLRPCD_INIT_NAME}"
    fi 
  fi
  /sbin/ldconfig
fi

%pre xmlrpcd
if [ $1 = 2 ]; then
  XMLRPCD_OLD_INIT="ogo-xmlrpcd-1.0a"
  if [ -f "%{_sysconfdir}/init.d/${XMLRPCD_OLD_INIT}" ]; then
    if [ -f "/etc/SuSE-release" ]; then
      "%{_sysconfdir}/init.d/${XMLRPCD_OLD_INIT}" stop
      insserv --remove "%{_sysconfdir}/init.d/${XMLRPCD_OLD_INIT}"
      rm -f "%{_sysconfdir}/init.d/${XMLRPCD_OLD_INIT}"
      rm -f /usr/sbin/rc"${XMLRPCD_OLD_INIT}"
    else
      service "${XMLRPCD_OLD_INIT}" stop
      chkconfig "${XMLRPCD_OLD_INIT}" off
      chkconfig --del "${XMLRPCD_OLD_INIT}"
      rm -f "%{_sysconfdir}/init.d/${XMLRPCD_OLD_INIT}"
    fi
  fi 
fi  

%preun zidestore
if [ $1 = 0 ]; then
  ZIDESTORE_INIT_NAME="ogo-zidestore"
  ZIDESTORE_INIT_VERSION="ogo-zidestore-%{zide_v}"
  ZIDESTORE_INIT_PREFIX="%{prefix}"
  if [ -f "%{_sysconfdir}/init.d/${ZIDESTORE_INIT_NAME}" ]; then
    if [ -f "/etc/SuSE-release" ]; then
      "%{_sysconfdir}/init.d/${ZIDESTORE_INIT_NAME}" stop
      insserv --remove "%{_sysconfdir}/init.d/${ZIDESTORE_INIT_NAME}"
      rm -f "%{_sysconfdir}/init.d/${ZIDESTORE_INIT_NAME}"
      rm -f /usr/sbin/rc"${ZIDESTORE_INIT_NAME}"
    else
      service "${ZIDESTORE_INIT_NAME}" stop
      chkconfig "${ZIDESTORE_INIT_NAME}" off
      chkconfig --del "${ZIDESTORE_INIT_NAME}"
      rm -f "%{_sysconfdir}/init.d/${ZIDESTORE_INIT_NAME}"
    fi
  fi
  /sbin/ldconfig
fi

%pre zidestore
if [ $1 = 2 ]; then
  ZIDESTORE_OLD_INIT="ogo-zidestore-1.3"
  if [ -f "%{_sysconfdir}/init.d/${ZIDESTORE_OLD_INIT}" ]; then
    if [ -f "/etc/SuSE-release" ]; then
      "%{_sysconfdir}/init.d/${ZIDESTORE_OLD_INIT}" stop
      insserv --remove "%{_sysconfdir}/init.d/${ZIDESTORE_OLD_INIT}"
      rm -f "%{_sysconfdir}/init.d/${ZIDESTORE_OLD_INIT}"
      rm -f /usr/sbin/rc"${ZIDESTORE_OLD_INIT}"
    else
      service "${ZIDESTORE_OLD_INIT}" stop
      chkconfig "${ZIDESTORE_OLD_INIT}" off
      chkconfig --del "${ZIDESTORE_OLD_INIT}"
      rm -f "%{_sysconfdir}/init.d/${ZIDESTORE_OLD_INIT}"
    fi
  fi 
fi  

# ****************************** clean ********************************
%clean
rm -fr ${RPM_BUILD_ROOT}

# ****************************** files ********************************
%files docapi
%defattr(-,root,root,-)
%{prefix}/lib/opengroupware.org-%{ogo_v}/datasources/OGoAccounts.ds
%{prefix}/lib/opengroupware.org-%{ogo_v}/datasources/OGoBase.ds
%{prefix}/lib/opengroupware.org-%{ogo_v}/datasources/OGoContacts.ds
%{prefix}/lib/opengroupware.org-%{ogo_v}/datasources/OGoJobs.ds
%{prefix}/lib/opengroupware.org-%{ogo_v}/datasources/OGoProject.ds
%{prefix}/lib/opengroupware.org-%{ogo_v}/datasources/OGoRawDatabase.ds
%{prefix}/lib/opengroupware.org-%{ogo_v}/datasources/OGoScheduler.ds
%{prefix}/lib/libOGoAccounts*.so.%{libogo_v}*
%{prefix}/lib/libOGoBase*.so.%{libogo_v}*
%{prefix}/lib/libOGoContacts*.so.%{libogo_v}*
%{prefix}/lib/libOGoDocuments*.so.%{libogo_v}*
%{prefix}/lib/libOGoJobs*.so.%{libogo_v}*
%{prefix}/lib/libOGoProject*.so.%{libogo_v}*
%{prefix}/lib/libOGoRawDatabase*.so.%{libogo_v}*
%{prefix}/lib/libOGoScheduler*.so.%{libogo_v}*

%files docapi-fs-project
%defattr(-,root,root,-)
%{prefix}/lib/opengroupware.org-%{ogo_v}/datasources/OGoFileSystemProject.ds
%{prefix}/lib/libOGoFileSystemProject*.so.%{libogo_v}*

%files docapi-fs-project-devel
%defattr(-,root,root,-)
%{prefix}/include/OGoFileSystemProject
%{prefix}/lib/libOGoFileSystemProject*.so

%files docapi-db-project
%defattr(-,root,root,-)
%{prefix}/lib/opengroupware.org-%{ogo_v}/datasources/OGoDatabaseProject.ds
%{prefix}/lib/libOGoDatabaseProject*.so.%{libogo_v}*

%files docapi-db-project-devel
%defattr(-,root,root,-)
%{prefix}/include/OGoDatabaseProject
%{prefix}/lib/libOGoDatabaseProject*.so

%files docapi-devel
%defattr(-,root,root,-)
%{prefix}/include/OGoAccounts
%{prefix}/include/OGoBase
%{prefix}/include/OGoContacts
%{prefix}/include/OGoDocuments
%{prefix}/include/OGoJobs
%{prefix}/include/OGoProject
%{prefix}/include/OGoRawDatabase
%{prefix}/include/OGoScheduler
%{prefix}/lib/libOGoAccounts*.so
%{prefix}/lib/libOGoBase*.so
%{prefix}/lib/libOGoContacts*.so
%{prefix}/lib/libOGoDocuments*.so
%{prefix}/lib/libOGoJobs*.so
%{prefix}/lib/libOGoProject*.so
%{prefix}/lib/libOGoRawDatabase*.so
%{prefix}/lib/libOGoScheduler*.so

%files logic
%defattr(-,root,root,-)
%{prefix}/lib/opengroupware.org-%{ogo_v}/commands/LSAccount.cmd
%{prefix}/lib/opengroupware.org-%{ogo_v}/commands/LSAddress.cmd
%{prefix}/lib/opengroupware.org-%{ogo_v}/commands/LSBase.cmd
%{prefix}/lib/opengroupware.org-%{ogo_v}/commands/LSDocuments.cmd
%{prefix}/lib/opengroupware.org-%{ogo_v}/commands/LSEnterprise.cmd
%{prefix}/lib/opengroupware.org-%{ogo_v}/commands/LSMail.cmd
%{prefix}/lib/opengroupware.org-%{ogo_v}/commands/LSNews.cmd
%{prefix}/lib/opengroupware.org-%{ogo_v}/commands/LSPerson.cmd
%{prefix}/lib/opengroupware.org-%{ogo_v}/commands/LSProject.cmd
%{prefix}/lib/opengroupware.org-%{ogo_v}/commands/LSScheduler.cmd
%{prefix}/lib/opengroupware.org-%{ogo_v}/commands/LSSearch.cmd
%{prefix}/lib/opengroupware.org-%{ogo_v}/commands/LSTasks.cmd
%{prefix}/lib/opengroupware.org-%{ogo_v}/commands/LSTeam.cmd
%{prefix}/lib/opengroupware.org-%{ogo_v}/commands/OGo.model
%{prefix}/lib/libLSAddress*.so.%{libogo_v}*
%{prefix}/lib/libLSFoundation*.so.%{libogo_v}*
%{prefix}/lib/libLSSearch*.so.%{libogo_v}*
%{prefix}/lib/libOGoSchedulerTools*.so.%{libogo_v}*

%files logic-tools
%defattr(-,root,root,-)
%{prefix}/bin/load-LSModel

%files logic-devel
%defattr(-,root,root,-)
%{prefix}/include/LSFoundation
%{prefix}/include/OGoSchedulerTools
%{prefix}/lib/libLSAddress*.so
%{prefix}/lib/libLSFoundation*.so
%{prefix}/lib/libLSSearch*.so
%{prefix}/lib/libOGoSchedulerTools*.so

%files meta
%defattr(-,root,root,-)
%{prefix}/share/opengroupware.org-%{ogo_v}/INSTALLED.USING.METAPACKAGE

%files pda
%defattr(-,root,root,-)
%{prefix}/sbin/ogo-nhsd-%{ogo_v}
%{prefix}/bin/ogo-ppls-%{ogo_v}
%{prefix}/lib/libOGoNHS*.so.%{libogo_v}*
%{prefix}/lib/%{ogo_libogopalmui}.so.%{libogo_v}*
%{prefix}/lib/%{ogo_libogopalm}.so.%{libogo_v}*
%{prefix}/lib/libPPSync*.so.%{libogo_v}*
%{prefix}/lib/opengroupware.org-%{ogo_v}/conduits/OpenGroupwareNHS.conduit/OpenGroupwareNHS
%{prefix}/lib/opengroupware.org-%{ogo_v}/conduits/OpenGroupwareNHS.conduit/Resources/Info-gnustep.plist
%{prefix}/lib/opengroupware.org-%{ogo_v}/conduits/OpenGroupwareNHS.conduit/bundle-info.plist
%{prefix}/lib/opengroupware.org-%{ogo_v}/conduits/OpenGroupwareNHS.conduit/stamp.make
%{prefix}/lib/opengroupware.org-%{ogo_v}/datasources/OGoPalmDS.ds/OGoPalmDS
%{prefix}/lib/opengroupware.org-%{ogo_v}/datasources/OGoPalmDS.ds/Resources/Info-gnustep.plist
%{prefix}/lib/opengroupware.org-%{ogo_v}/datasources/OGoPalmDS.ds/bundle-info.plist
%{prefix}/lib/opengroupware.org-%{ogo_v}/datasources/OGoPalmDS.ds/stamp.make
%{prefix}/lib/opengroupware.org-%{ogo_v}/webui/OGoPalm.lso
%{prefix}/share/opengroupware.org-%{ogo_v}/initscript_templates/*nhsd
%attr(0644,root,root) %config(noreplace) %{_sysconfdir}/sysconfig/ogo-nhsd
%ghost %attr(0755,root,root) %config %{_sysconfdir}/init.d/ogo-nhsd

%files pda-devel
%defattr(-,root,root,-)
%{prefix}/include/OGoNHS
%{prefix}/include/OGoPalm
%{prefix}/include/OGoPalmUI
%{prefix}/include/PPSync
%{prefix}/lib/libOGoNHS*.so
%{prefix}/lib/%{ogo_libogopalmui}.so
%{prefix}/lib/%{ogo_libogopalm}.so
%{prefix}/lib/libPPSync*.so

%files theme-default
%defattr(-,root,root,-)
%{prefix}/share/opengroupware.org-%{ogo_v}/www/Danish.lproj
%{prefix}/share/opengroupware.org-%{ogo_v}/www/English.lproj
%{prefix}/share/opengroupware.org-%{ogo_v}/www/German.lproj
%{prefix}/share/opengroupware.org-%{ogo_v}/www/Italian.lproj
%{prefix}/share/opengroupware.org-%{ogo_v}/www/Polish.lproj
%{prefix}/share/opengroupware.org-%{ogo_v}/www/Spanish.lproj
%{prefix}/share/opengroupware.org-%{ogo_v}/www/WOStats.xsl
%{prefix}/share/opengroupware.org-%{ogo_v}/www/menu.js

%files theme-ooo
%defattr(-,root,root,-)
%{prefix}/share/opengroupware.org-%{ogo_v}/templates/Themes/OOo
%{prefix}/share/opengroupware.org-%{ogo_v}/www/English_OOo.lproj
%{prefix}/share/opengroupware.org-%{ogo_v}/www/German_OOo.lproj

%files theme-blue
%defattr(-,root,root,-)
%{prefix}/share/opengroupware.org-%{ogo_v}/templates/Themes/blue
%{prefix}/share/opengroupware.org-%{ogo_v}/www/English_blue.lproj
%{prefix}/share/opengroupware.org-%{ogo_v}/www/German_blue.lproj

%files theme-kde
%defattr(-,root,root,-)
%{prefix}/share/opengroupware.org-%{ogo_v}/templates/Themes/kde
%{prefix}/share/opengroupware.org-%{ogo_v}/www/English_kde.lproj

%files theme-orange
%defattr(-,root,root,-)
%{prefix}/share/opengroupware.org-%{ogo_v}/templates/Themes/orange
%{prefix}/share/opengroupware.org-%{ogo_v}/www/English_orange.lproj
%{prefix}/share/opengroupware.org-%{ogo_v}/www/German_orange.lproj

%files tools
%defattr(-,root,root,-)
%{prefix}/bin/ogo-account-add
%{prefix}/bin/ogo-account-del
%{prefix}/bin/ogo-account-list
%{prefix}/bin/ogo-acl-list
%{prefix}/bin/ogo-check-aptconflicts
%{prefix}/bin/ogo-check-permission
%{prefix}/bin/ogo-defaults
%{prefix}/bin/ogo-instfilter-procmail
%{prefix}/bin/ogo-jobs-export
%{prefix}/bin/ogo-project-export
%{prefix}/bin/ogo-project-import
%{prefix}/bin/ogo-project-list
%{prefix}/bin/ogo-prop-list
%{prefix}/bin/ogo-prop-set
%{prefix}/bin/ogo-runcmd
%{prefix}/bin/ogo-vcard-get
%{prefix}/bin/ogo-vcard-put
%{prefix}/bin/sky_install_sieve
%{prefix}/bin/sky_send_bulk_messages
%{prefix}/bin/skyaptnotify
%{prefix}/share/opengroupware.org-%{ogo_v}/aptnotify_template/ogo-aptnotify.sh

%files webui-app
%defattr(-,root,root,-)
%{prefix}/sbin/ogo-webui-%{ogo_v}
%{prefix}/share/opengroupware.org-%{ogo_v}/templates/ogo-webui-%{ogo_v}
%{prefix}/share/opengroupware.org-%{ogo_v}/initscript_templates/*opengroupware
%attr(0644,root,root) %config(noreplace) %{_sysconfdir}/sysconfig/ogo-webui
%ghost %attr(0755,root,root) %config %{_sysconfdir}/init.d/ogo-webui

%files webui-core
%defattr(-,root,root,-)
%{prefix}/lib/libOGoFoundation*.so.%{libogo_v}*
%{prefix}/lib/opengroupware.org-%{ogo_v}/webui/AdminUI.lso
%{prefix}/lib/opengroupware.org-%{ogo_v}/webui/BaseUI.lso
%{prefix}/lib/opengroupware.org-%{ogo_v}/webui/GroupsUI.lso
%{prefix}/lib/opengroupware.org-%{ogo_v}/webui/OGoUIElements.lso
%{prefix}/lib/opengroupware.org-%{ogo_v}/webui/PreferencesUI.lso
%{prefix}/lib/opengroupware.org-%{ogo_v}/webui/PropertiesUI.lso
%{prefix}/lib/opengroupware.org-%{ogo_v}/webui/RelatedLinksUI.lso
%{prefix}/lib/opengroupware.org-%{ogo_v}/webui/SoOGo.lso
%{prefix}/share/opengroupware.org-%{ogo_v}/templates/AdminUI
%{prefix}/share/opengroupware.org-%{ogo_v}/templates/BaseUI
%{prefix}/share/opengroupware.org-%{ogo_v}/templates/GroupsUI
%{prefix}/share/opengroupware.org-%{ogo_v}/templates/OGoUIElements
%{prefix}/share/opengroupware.org-%{ogo_v}/templates/PreferencesUI
%{prefix}/share/opengroupware.org-%{ogo_v}/templates/PropertiesUI
%{prefix}/share/opengroupware.org-%{ogo_v}/templates/RegUI
%{prefix}/share/opengroupware.org-%{ogo_v}/templates/RelatedLinksUI

%files webui-core-devel
%defattr(-,root,root,-)
%{prefix}/include/OGoFoundation
%{prefix}/lib/libOGoFoundation*.so

%files webui-calendar
%defattr(-,root,root,-)
%{prefix}/lib/opengroupware.org-%{ogo_v}/webui/LSWScheduler.lso
%{prefix}/lib/opengroupware.org-%{ogo_v}/webui/OGoResourceScheduler.lso
%{prefix}/lib/opengroupware.org-%{ogo_v}/webui/OGoScheduler.lso
%{prefix}/lib/opengroupware.org-%{ogo_v}/webui/OGoSchedulerDock.lso
%{prefix}/lib/opengroupware.org-%{ogo_v}/webui/OGoSchedulerViews.lso
%{prefix}/share/opengroupware.org-%{ogo_v}/templates/LSWScheduler
%{prefix}/share/opengroupware.org-%{ogo_v}/templates/OGoResourceScheduler
%{prefix}/share/opengroupware.org-%{ogo_v}/templates/OGoScheduler
%{prefix}/share/opengroupware.org-%{ogo_v}/templates/OGoSchedulerDock
%{prefix}/share/opengroupware.org-%{ogo_v}/templates/OGoSchedulerViews

%{prefix}/share/opengroupware.org-%{ogo_v}/Holidays.plist

%files webui-contact
%defattr(-,root,root,-)
%{prefix}/lib/opengroupware.org-%{ogo_v}/webui/AddressUI.lso
%{prefix}/lib/opengroupware.org-%{ogo_v}/webui/EnterprisesUI.lso
%{prefix}/lib/opengroupware.org-%{ogo_v}/webui/LDAPAccounts.lso
%{prefix}/lib/opengroupware.org-%{ogo_v}/webui/PersonsUI.lso
%{prefix}/share/opengroupware.org-%{ogo_v}/templates/AddressUI
%{prefix}/share/opengroupware.org-%{ogo_v}/templates/EnterprisesUI
%{prefix}/share/opengroupware.org-%{ogo_v}/templates/LDAPAccounts
%{prefix}/share/opengroupware.org-%{ogo_v}/templates/PersonsUI

%files webui-mailer
%defattr(-,root,root,-)
%{prefix}/lib/libOGoWebMail*.so.%{libogo_v}*
%{prefix}/lib/opengroupware.org-%{ogo_v}/webui/LSWMail.lso
%{prefix}/lib/opengroupware.org-%{ogo_v}/webui/OGoMailEditor.lso
%{prefix}/lib/opengroupware.org-%{ogo_v}/webui/OGoMailFilter.lso
%{prefix}/lib/opengroupware.org-%{ogo_v}/webui/OGoMailInfo.lso
%{prefix}/lib/opengroupware.org-%{ogo_v}/webui/OGoMailViewers.lso
%{prefix}/lib/opengroupware.org-%{ogo_v}/webui/OGoRecipientLists.lso
%{prefix}/lib/opengroupware.org-%{ogo_v}/webui/OGoWebMail.lso
%{prefix}/share/opengroupware.org-%{ogo_v}/templates/LSWMail
%{prefix}/share/opengroupware.org-%{ogo_v}/templates/OGoMailEditor
%{prefix}/share/opengroupware.org-%{ogo_v}/templates/OGoMailFilter
%{prefix}/share/opengroupware.org-%{ogo_v}/templates/OGoMailInfo
%{prefix}/share/opengroupware.org-%{ogo_v}/templates/OGoMailViewers
%{prefix}/share/opengroupware.org-%{ogo_v}/templates/OGoRecipientLists
%{prefix}/share/opengroupware.org-%{ogo_v}/templates/OGoWebMail

%files webui-mailer-devel
%defattr(-,root,root,-)
%{prefix}/include/OGoWebMail
%{prefix}/lib/libOGoWebMail*.so

%files webui-news
%defattr(-,root,root,-)
%{prefix}/lib/opengroupware.org-%{ogo_v}/webui/NewsUI.lso
%{prefix}/share/opengroupware.org-%{ogo_v}/templates/NewsUI

%files webui-task
%defattr(-,root,root,-)
%{prefix}/lib/opengroupware.org-%{ogo_v}/webui/JobUI.lso
%{prefix}/share/opengroupware.org-%{ogo_v}/templates/JobUI

%files webui-project
%defattr(-,root,root,-)
%{prefix}/lib/opengroupware.org-%{ogo_v}/webui/LSWProject.lso
%{prefix}/lib/opengroupware.org-%{ogo_v}/webui/OGoDocInlineViewers.lso
%{prefix}/lib/opengroupware.org-%{ogo_v}/webui/OGoNote.lso
%{prefix}/lib/opengroupware.org-%{ogo_v}/webui/OGoProject.lso
%{prefix}/lib/opengroupware.org-%{ogo_v}/webui/OGoProjectInfo.lso
%{prefix}/lib/opengroupware.org-%{ogo_v}/webui/OGoProjectZip.lso
%{prefix}/share/opengroupware.org-%{ogo_v}/templates/LSWProject
%{prefix}/share/opengroupware.org-%{ogo_v}/templates/OGoDocInlineViewers
%{prefix}/share/opengroupware.org-%{ogo_v}/templates/OGoNote
%{prefix}/share/opengroupware.org-%{ogo_v}/templates/OGoProject
%{prefix}/share/opengroupware.org-%{ogo_v}/templates/OGoProjectInfo
%{prefix}/share/opengroupware.org-%{ogo_v}/templates/OGoProjectZip

%files webui-resource-basque
%defattr(-,root,root,-)
%{prefix}/share/opengroupware.org-%{ogo_v}/translations/Basque.lproj

%files webui-resource-dk
%defattr(-,root,root,-)
%{prefix}/share/opengroupware.org-%{ogo_v}/translations/Danish.lproj

%files webui-resource-nl
%defattr(-,root,root,-)
%{prefix}/share/opengroupware.org-%{ogo_v}/translations/Dutch.lproj

%files webui-resource-en
%defattr(-,root,root,-)
%{prefix}/share/opengroupware.org-%{ogo_v}/translations/English.lproj

%files webui-resource-fr
%defattr(-,root,root,-)
%{prefix}/share/opengroupware.org-%{ogo_v}/translations/French.lproj

%files webui-resource-de
%defattr(-,root,root,-)
%{prefix}/share/opengroupware.org-%{ogo_v}/translations/German.lproj

%files webui-resource-hu
%defattr(-,root,root,-)
%{prefix}/share/opengroupware.org-%{ogo_v}/translations/Hungarian.lproj

%files webui-resource-it
%defattr(-,root,root,-)
%{prefix}/share/opengroupware.org-%{ogo_v}/translations/Italian.lproj

%files webui-resource-jp
%defattr(-,root,root,-)
%{prefix}/share/opengroupware.org-%{ogo_v}/translations/Japanese.lproj

%files webui-resource-no
%defattr(-,root,root,-)
%{prefix}/share/opengroupware.org-%{ogo_v}/translations/Norwegian.lproj

%files webui-resource-pl
%defattr(-,root,root,-)
%{prefix}/share/opengroupware.org-%{ogo_v}/translations/Polish.lproj

%files webui-resource-pt
%defattr(-,root,root,-)
%{prefix}/share/opengroupware.org-%{ogo_v}/translations/Portuguese.lproj

%files webui-resource-sk
%defattr(-,root,root,-)
%{prefix}/share/opengroupware.org-%{ogo_v}/translations/Slovak.lproj

%files webui-resource-es
%defattr(-,root,root,-)
%{prefix}/share/opengroupware.org-%{ogo_v}/translations/Spanish.lproj

%files webui-resource-ptbr
%defattr(-,root,root,-)
%{prefix}/share/opengroupware.org-%{ogo_v}/translations/ptBR.lproj

%files xmlrpcd
%defattr(-,root,root,-)
%{prefix}/sbin/ogo-xmlrpcd-%{ogo_v}
%{prefix}/share/opengroupware.org-%{ogo_v}/initscript_templates/*xmlrpcd
%attr(0644,root,root) %config(noreplace) %{_sysconfdir}/sysconfig/ogo-xmlrpcd
%ghost %attr(0755,root,root) %{_sysconfdir}/init.d/ogo-xmlrpcd

%files zidestore
%defattr(-,root,root,-)
%{prefix}/sbin/ogo-zidestore-%{zide_v}
%{prefix}/lib/libZSAppointments*.so.%{zide_v}*
%{prefix}/lib/libZSBackend*.so.%{zide_v}*
%{prefix}/lib/libZSContacts*.so.%{zide_v}*
%{prefix}/lib/libZSFrontend*.so.%{zide_v}*
%{prefix}/lib/libZSProjects*.so.%{zide_v}*
%{prefix}/lib/libZSTasks*.so.%{zide_v}*
%{prefix}/lib/zidestore-%{zide_v}
%{prefix}/share/zidestore-%{zide_v}
%attr(0644,root,root) %config(noreplace) %{_sysconfdir}/sysconfig/ogo-zidestore
%ghost %attr(0755,root,root) %{_sysconfdir}/init.d/ogo-zidestore

%files zidestore-devel
%defattr(-,root,root,-)
%{prefix}/include/ZSBackend
%{prefix}/include/ZSFrontend
%{prefix}/lib/libZSAppointments*.so
%{prefix}/lib/libZSBackend*.so
%{prefix}/lib/libZSContacts*.so
%{prefix}/lib/libZSFrontend*.so
%{prefix}/lib/libZSProjects*.so
%{prefix}/lib/libZSTasks*.so

# ********************************* changelog *************************
%changelog
* Mon Jan 30 2006 Frank Reppin <frank@opengroupware.org>
- added ogo-prop-list/ogo-prop-set to tools
* Fri Oct 30 2005 Frank Reppin <frank@opengroupware.org>
- templates/GroupsUI
* Fri Aug 26 2005 Frank Reppin <frank@opengroupware.org>
- added ogo-check-aptconflicts
- use SOPE trunk for OGo trunk builds
* Thu Aug 18 2005 Frank Reppin <frank@opengroupware.org>
- pda requires pilot-link (pilot-link provides libpisock)
* Fri Jul 08 2005 Frank Reppin <frank@opengroupware.org>
- cleanse init.d/ prior update (some pre sections)
- restart services in post for update
- call ldconfig in post for packages providing libraries
* Tue Jul 05 2005 Frank Reppin <frank@opengroupware.org>
- defined ogo_v/zide_v/libogo_v in header and replaced
  all occurances
- dropped use of version suffix for initscripts and sysconfig
  files
- added upgrade to post-stages to properly deal with this
  change
- updated #UseSOPE to current release (sope-4.4rc.1-rock)
* Fri Jun 17 2005 Helge Hess <helge.hess@opengroupware.org>
- patched pathes for version 1.1
* Wed May 11 2005 Frank Reppin <frank@opengroupware.org>
- added ogo-vcard-get/ogo-vcard-put
* Tue May 10 2005 Helge Hess <hh@opengroupware.org>
- fixed some tool names
- removed LSResource.cmd
* Wed Mar 16 2005 Frank Reppin <frank@opengroupware.org>
- added initscripts as ghosts.
* Tue Mar 15 2005 Frank Reppin <frank@opengroupware.org>
- added sysconfigs to packages xmlrpcd/zidestore/pda
* Mon Mar 14 2005 Frank Reppin <frank@opengroupware.org>
- added ogo-aptnotify.sh
* Thu Mar 10 2005 Frank Reppin <frank@opengroupware.org>
- added PGCLIENTENCODING to sysconfig settings
  (thus dealing with OGo Bug #1292)
* Sun Jan 30 2005 Frank Reppin <frank@opengroupware.org>
- some additional ldconfig calls
- changed files section for ogo-zidestore
* Sat Jan 29 2005 Frank Reppin <frank@opengroupware.org>
- added sysconfig settings (will summon /etc/sysconfig/ogo-webui-1.1)
  with some variables regarding automated database setup operations
* Fri Jan 28 2005 Frank Reppin <frank@opengroupware.org>
- major dependency rework
* Wed Jan 26 2005 Frank Reppin <frank@opengroupware.org>
- dealt with OGo Bug #1202 (insserve on SUSE && symlink rc* scripts in /usr/sbin)
* Tue Jan 25 2005 Frank Reppin <frank@opengroupware.org>
- fixed OGo Bug #1197
* Wed Jan 19 2005 Frank Reppin <frank@opengroupware.org>
- added 'preun' stages for the initscripts
- added meta package
* Tue Jan 18 2005 Frank Reppin <frank@opengroupware.org>
- began to include more or less generic initscripts which
  should work on both SUSE and RedHat `based` distributions;
  and thus I distinguish between redhat_ and suse_ based initscripts
  for now...
  (I define Conectiva, Mandrake and Fedora as RedHat based)
* Fri Jan 14 2005 Frank Reppin <frank@opengroupware.org>
-'#UseSOPE: <foo>' acts as a hint for `purveyor_of_rpms.pl`
  and will trigger the installation of the named SOPE release
  prior building the OGo RPMS [replaces (UseSOPEsrc|UseSOPEspec)]!
  (<foo> expands to 'sope-<version>-<codename>')
* Wed Jan 05 2005 Frank Reppin <frank@opengroupware.org>
- added buildhints (UseSOPEsrc|UseSOPEspec) - these hints get
  triggered in our buildprocess and from now on OGo will be
  build using the SOPE version given there (if valid ofcourse).
- get rid of tabs in specfile
* Wed Dec 29 2004 Frank Reppin <frank@opengroupware.org>
- added Slovak.lproj (webui-resource-sk)
* Tue Nov 30 2004 Frank Reppin <frank@opengroupware.org>
- removed webui-resource-se since it's not part
  of the build anymore.
* Wed Sep 09 2004 Frank Reppin <frank@opengroupware.org>
- initial build
