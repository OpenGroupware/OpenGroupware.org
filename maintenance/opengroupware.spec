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
#UseSOPEsrc:   sope-4.4beta.1-voyager-r496.tar.gz
#UseSOPEspec:  sope-4.4beta.1-voyager.spec

%description
OpenGroupware.org aims at being an open source groupware server which
integrates with the leading open source office suite products and all
the leading groupware clients running across all major platforms, and
to provide access to all functionality and data through open XML-based
interfaces and APIs. Additionally it has a web User Interface for
platform independent usage. OpenGroupware.org is built on top of the
SOPE application server.

#########################################
%package dbsetup
Summary:      This package...
Group:        Development/Libraries
#Requires:    ogo-gnustep_make
AutoReqProv:  off

%description dbsetup
database setup.
#########################################
%package docapi
Summary:      OpenGroupware.org document API
Group:        Development/Libraries
#Requires:    ogo-gnustep_make 
AutoReqProv:  off

%description docapi
The Document API is a set of Objective-C libraries wrapping the SOPE
logic in a "document" API.

%package docapi-fs-project
Summary:      Filesystem storage for OpenGroupware.org projects
Group:        Development/Libraries
#Requires:    ogo-gnustep_make 
AutoReqProv:  off

%description docapi-fs-project
Files associated to OpenGroupware.org projects can be stored through different
storage backends. This package contains the filesystem storage backend, which
stores all files on the hosts filesystem.

%package docapi-fs-project-devel
Summary:      Development files for OpenGroupware.org's filesystem storage
Group:        Development/Libraries
#Requires:    ogo-gnustep_make 
AutoReqProv:  off

%description docapi-fs-project-devel
This package contains the development files for the ogo-docapi-fs-project package.

%package docapi-db-project
Summary:      Database storage for OpenGroupware.org projects
Group:        Development/Libraries
#Requires:    ogo-gnustep_make 
AutoReqProv:  off

%description docapi-db-project
Files associated to OpenGroupware.org projects can be stored through different
storage backends. This package contains the database storage backend.

%package docapi-db-project-devel
Summary:      Development files for OpenGroupware.org's database storage
Group:        Development/Libraries
#Requires:    ogo-gnustep_make 
AutoReqProv:  off

%description docapi-db-project-devel
This package contains the development files for the ogo-docapi-db-project package.

%package docapi-devel
Summary:      Development files for the ogo-docapi package.
Group:        Development/Libraries
#Requires:    ogo-gnustep_make 
AutoReqProv:  off

%description docapi-devel
This package contains the development files for the ogo-docapi package.
#########################################
%package logic
Summary:      OpenGroupware.org application logic
Group:        Development/Libraries
#Requires:    ogo-gnustep_make 
AutoReqProv:  off

%description logic
This package contains OpenGroupware.org's application logic.
##
%package logic-tools
Summary:      OpenGroupware.org application logic tools
Group:        Development/Libraries
#Requires:    ogo-gnustep_make 
AutoReqProv:  off

%description logic-tools
This package contains OpenGroupware.org application logic tools

 * load-LSModel

##
%package logic-devel
Summary:      Development files for the OpenGroupware.org application logic
Group:        Development/Libraries
#Requires:    ogo-gnustep_make
AutoReqProv:  off

%description logic-devel
This package contains the development files for the OpenGroupware.org
application logic.
#########################################
%package pda
Summary:      PDA syncing framework for OpenGroupware.org
Group:        Development/Libraries
#Requires:    ogo-gnustep_make 
AutoReqProv:  off

%description pda
This package contains the PDA syncing framework for OpenGroupware.org.

%package pda-devel
Summary:      Development files for the PDA syncing framework of OpenGroupware.org
Group:        Development/Libraries
#Requires:    ogo-gnustep_make 
AutoReqProv:  off

%description pda-devel
This package contains the development files for the PDA syncing
framework of OpenGroupware.org
#########################################
%package theme-default
Summary:      Default theme for OpenGroupware.org's web UI
Group:        Development/Libraries
#Requires:    ogo-gnustep_make 
AutoReqProv:  off

%description theme-default
This package contains the default theme for OpenGroupware.org's web UI.
##
%package theme-ooo
Summary:      OOo alike theme for OpenGroupware.org's web UI
Group:        Development/Libraries
#Requires:    ogo-gnustep_make 
AutoReqProv:  off

%description theme-ooo
This package contains an OOo alike theme for OpenGroupware.org's web UI.
##
%package theme-blue
Summary:      Blue theme for OpenGroupware.org's web UI.
Group:        Development/Libraries
#Requires:    ogo-gnustep_make
AutoReqProv:  off

%description theme-blue
This package contains a blue theme for OpenGroupware.org's web UI.
##
%package theme-kde
Summary:      KDE alike theme for OpenGroupware.org's web UI.
Group:        Development/Libraries
#Requires:    ogo-gnustep_make 
AutoReqProv:  off

%description theme-kde
This package contains a KDE alike theme for OpenGroupware.org's web UI.
##
%package theme-orange
Summary:      Orange theme for OpenGroupware.org's web UI.
Group:        Development/Libraries
#Requires:    ogo-gnustep_make
AutoReqProv:  off

%description theme-orange
This package contains an orange theme for OpenGroupware.org's web UI.
#########################################
%package tools
Summary:      Various commandline Tools for OpenGroupware.org
Group:        Development/Libraries
#Requires:    ogo-gnustep_make 
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
#Requires:    ogo-gnustep_make 
AutoReqProv:  off

%description webui-app
This package contains the executable and resources of
OpenGroupware.org's web application server.
#
%package webui-core
Summary:      Core elements for OpenGroupware.org's Web UI
Group:        Development/Libraries
#Requires:    ogo-gnustep_make 
AutoReqProv:  off

%description webui-core
This package contains UI elements that are used in various components
of OpenGroupware.org's web frontend.
##
%package webui-core-devel
Summary:      Development files for the core elements of OpenGroupware.org's Web UI
Group:        Development/Libraries
#Requires:    ogo-gnustep_make 
AutoReqProv:  off

%description webui-core-devel
This package contains the development files for the core elements
of OpenGroupware.org's Web UI
##
%package webui-calendar
Summary:      Calendar component of OpenGroupware.org's Web UI
Group:        Development/Libraries
#Requires:    ogo-gnustep_make 
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
#Requires:    ogo-gnustep_make 
AutoReqProv:  off

%description webui-contact
The contact component lets users add and manage contacts of individuals
or companies. Import and export of vcf files is supported, as well as
importing contacts from a csv file.
##
%package webui-mailer
Summary:      Mailer component of OpenGroupware.org's Web UI
Group:        Development/Libraries
#Requires:    ogo-gnustep_make
AutoReqProv:  off

%description webui-mailer
This package contains a webmail application for OpenGroupware.org's
web UI. It needs an IMAP server for the mail feed and and SMTP server
to enable the users to send mail.
##
%package webui-mailer-devel
Summary:      Development files for the mailer component of OpenGroupware.org's Web UI
Group:        Development/Libraries
#Requires:    ogo-gnustep_make
AutoReqProv:  off

%description webui-mailer-devel
This package contains the development files for the mailer component
of OpenGroupware.org's Web UI
##
%package webui-news
Summary:      News component of OpenGroupware.org's Web UI
Group:        Development/Libraries
#Requires:    ogo-gnustep_make
AutoReqProv:  off

%description webui-news
The news component shows recent appointments and tasks for each user.
Additionally it supports the creation and display of simple news items.
##
%package webui-task
Summary:      Task component of OpenGroupware.org's Web UI
Group:        Development/Libraries
#Requires:    ogo-gnustep_make
AutoReqProv:  off

%description webui-task
The task component enables users to assign and manage tasks
related to projects or standalone.
##
%package webui-project
Summary:      Project component of OpenGroupware.org's Web UI
Group:        Development/Libraries
#Requires:    ogo-gnustep_make
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
#Requires:    ogo-gnustep_make 
AutoReqProv:  off

%description webui-resource-basque
This package contains the Basque translation for OpenGroupware.org's web UI.
##
%package webui-resource-dk
Summary:      Danish translation for OpenGroupware.org's web UI
Group:        Development/Libraries
#Requires:    ogo-gnustep_make
AutoReqProv:  off

%description webui-resource-dk
This package contains the Danish translation for OpenGroupware.org's web UI.
##
%package webui-resource-nl
Summary:      Dutch translation for OpenGroupware.org's web UI
Group:        Development/Libraries
#Requires:    ogo-gnustep_make
AutoReqProv:  off

%description webui-resource-nl
This package contains the Dutch translation for OpenGroupware.org's web UI.
##
%package webui-resource-en
Summary:      English translation for OpenGroupware.org's web UI
Group:        Development/Libraries
#Requires:    ogo-gnustep_make
AutoReqProv:  off

%description webui-resource-en
This package contains the English translation for OpenGroupware.org's web UI.
##
%package webui-resource-fr
Summary:      French translation for OpenGroupware.org's web UI
Group:        Development/Libraries
#Requires:    ogo-gnustep_make 
AutoReqProv:  off

%description webui-resource-fr
This package contains the French translation for OpenGroupware.org's web UI.
##
%package webui-resource-de
Summary:      German translation for OpenGroupware.org's web UI
Group:        Development/Libraries
#Requires:    ogo-gnustep_make
AutoReqProv:  off

%description webui-resource-de
This package contains the German translation for OpenGroupware.org's web UI.
##
%package webui-resource-hu
Summary:      Hungarian translation for OpenGroupware.org's web UI
Group:        Development/Libraries
#Requires:    ogo-gnustep_make
AutoReqProv:  off

%description webui-resource-hu
This package contains the Hungarian translation for OpenGroupware.org's web UI.
##
%package webui-resource-it
Summary:      Italian translation for OpenGroupware.org's web UI
Group:        Development/Libraries
#Requires:    ogo-gnustep_make
AutoReqProv:  off

%description webui-resource-it
This package contains the Italian translation for OpenGroupware.org's web UI.
##
%package webui-resource-jp
Summary:      Japanese translation for OpenGroupware.org's web UI
Group:        Development/Libraries
#Requires:    ogo-gnustep_make
AutoReqProv:  off

%description webui-resource-jp
This package contains the Japanese translation for OpenGroupware.org's web UI.
##
%package webui-resource-no
Summary:      Norwegian translation for OpenGroupware.org's web UI
Group:        Development/Libraries
#Requires:    ogo-gnustep_make
AutoReqProv:  off

%description webui-resource-no
This package contains the Norwegian translation for OpenGroupware.org's web UI.
##
%package webui-resource-pl
Summary:      Polish translation for OpenGroupware.org's web UI
Group:        Development/Libraries
#Requires:    ogo-gnustep_make
AutoReqProv:  off

%description webui-resource-pl
This package contains the Polish translation for OpenGroupware.org's web UI.
##
%package webui-resource-pt
Summary:      Portuguese translation for OpenGroupware.org's web UI
Group:        Development/Libraries
#Requires:    ogo-gnustep_make 
AutoReqProv:  off

%description webui-resource-pt
This package contains the Portuguese translation for OpenGroupware.org's web UI.
##
%package webui-resource-es
Summary:      Spanish translation for OpenGroupware.org's web UI
Group:        Development/Libraries
#Requires:    ogo-gnustep_make
AutoReqProv:  off

%description webui-resource-es
This package contains the Spanish translation for OpenGroupware.org's web UI.
##
%package webui-resource-sk
Summary:      Slovak translation for OpenGroupware.org's web UI
Group:        Development/Libraries
#Requires:    ogo-gnustep_make
AutoReqProv:  off

%description webui-resource-sk
This package contains the Slovak translation for OpenGroupware.org's web UI.
##
%package webui-resource-ptbr
Summary:      Portuguese (Brazilian) translation for OpenGroupware.org's web UI
Group:        Development/Libraries
#Requires:    ogo-gnustep_make
AutoReqProv:  off

%description webui-resource-ptbr
This package contains the Portuguese (Brazilian) translation for OpenGroupware.org's web UI.
#########################################
%package xmlrpcd
Summary:      XMLRPC daemon for OpenGroupware.org
Group:        Development/Libraries
#Requires:    ogo-gnustep_make
AutoReqProv:  off

%description xmlrpcd
The XMLRPC daemon allows to execute groupware functions over the standardized
XMLRPC API. This is especially useful within scripts or custom applications.
#########################################
%package zidestore
Summary:      ZideStore server for OpenGroupware.org
Group:        Development/Libraries
#Requires:    ogo-gnustep_make
AutoReqProv:  off

%description zidestore
The ZideStore Server provides WebDAV access to the OpenGroupware.org
data. It can be used to connect native groupware clients with
OpenGroupware.org. Currently supported are calendaring clients that use
iCal subscriptions, an Ximian Evolution plugin is under development.

%package zidestore-devel
Summary:      Development Files for the ZideStore server
Group:        Development/Libraries
#Requires:    ogo-gnustep_make
AutoReqProv:  off

%description zidestore-devel
This package contains development files for the OpenGroupware.org ZideStore
server.
#########################################
%prep
rm -fr ${RPM_BUILD_ROOT}
%setup -n opengroupware.org

# ****************************** build ********************************
%build
source %{prefix}/OGo-GNUstep/Library/Makefiles/GNUstep.sh
make %{ogo_makeflags}


# ****************************** install ******************************
%install
source %{prefix}/OGo-GNUstep/Library/Makefiles/GNUstep.sh
mkdir -p GNUSTEP_INSTALLATION_DIR=${RPM_BUILD_ROOT}%{prefix}/lib/OGo-GNUstep

make %{ogo_makeflags} GNUSTEP_INSTALLATION_DIR=${RPM_BUILD_ROOT}%{prefix}/lib/OGo-GNUstep \
                      FHS_INSTALL_ROOT=${RPM_BUILD_ROOT}%{prefix} \
                      BUNDLE_INSTALL_DIR=${RPM_BUILD_ROOT}%{prefix} \
                      WOBUNDLE_INSTALL_DIR=${RPM_BUILD_ROOT}%{prefix} \
                      install

rm -f "${RPM_BUILD_ROOT}%{prefix}/share/opengroupware.org-1.0a/templates"
rm -f "${RPM_BUILD_ROOT}%{prefix}/share/opengroupware.org-1.0a/translations"
rm -f "${RPM_BUILD_ROOT}%{prefix}/share/opengroupware.org-1.0a/www"
cp -Rp WebUI/Templates "${RPM_BUILD_ROOT}%{prefix}/share/opengroupware.org-1.0a/templates"
cp -Rp WebUI/Resources "${RPM_BUILD_ROOT}%{prefix}/share/opengroupware.org-1.0a/translations"
cp -Rp Themes/WebServerResources "${RPM_BUILD_ROOT}%{prefix}/share/opengroupware.org-1.0a/www"
rm -fr "${RPM_BUILD_ROOT}%{prefix}/share/opengroupware.org-1.0a/templates/HelpUI"
rm -fr "${RPM_BUILD_ROOT}%{prefix}/share/opengroupware.org-1.0a/translations/COPYRIGHT"
rm -fr "${RPM_BUILD_ROOT}%{prefix}/share/opengroupware.org-1.0a/translations/ChangeLog"
rm -fr "${RPM_BUILD_ROOT}%{prefix}/share/opengroupware.org-1.0a/translations/GNUmakefile"
rm -fr "${RPM_BUILD_ROOT}%{prefix}/share/opengroupware.org-1.0a/www/GNUmakefile"
rm -fr "${RPM_BUILD_ROOT}%{prefix}/share/opengroupware.org-1.0a/www/tools"

# ****************************** post *********************************
%post

# ****************************** postun *********************************
%postun

# ****************************** clean ********************************
%clean

rm -fr ${RPM_BUILD_ROOT}

# ****************************** files ********************************
%files docapi
%defattr(-,root,root,-)
%{prefix}/lib/opengroupware.org-1.0a/datasources/OGoAccounts.ds
%{prefix}/lib/opengroupware.org-1.0a/datasources/OGoBase.ds
%{prefix}/lib/opengroupware.org-1.0a/datasources/OGoContacts.ds
%{prefix}/lib/opengroupware.org-1.0a/datasources/OGoJobs.ds
%{prefix}/lib/opengroupware.org-1.0a/datasources/OGoProject.ds
%{prefix}/lib/opengroupware.org-1.0a/datasources/OGoRawDatabase.ds
%{prefix}/lib/opengroupware.org-1.0a/datasources/OGoScheduler.ds
%{prefix}/lib/libOGoAccounts*.so.5.1*
%{prefix}/lib/libOGoBase*.so.5.1*
%{prefix}/lib/libOGoContacts*.so.5.1*
%{prefix}/lib/libOGoDocuments*.so.5.1*
%{prefix}/lib/libOGoJobs*.so.5.1*
%{prefix}/lib/libOGoProject*.so.5.1*
%{prefix}/lib/libOGoRawDatabase*.so.5.1*
%{prefix}/lib/libOGoScheduler*.so.5.1*

%files docapi-fs-project
%defattr(-,root,root,-)
%{prefix}/lib/opengroupware.org-1.0a/datasources/OGoFileSystemProject.ds
%{prefix}/lib/libOGoFileSystemProject*.so.5.1*

%files docapi-fs-project-devel
%defattr(-,root,root,-)
%{prefix}/include/OGoFileSystemProject
%{prefix}/lib/libOGoFileSystemProject*.so

%files docapi-db-project
%defattr(-,root,root,-)
%{prefix}/lib/opengroupware.org-1.0a/datasources/OGoDatabaseProject.ds
%{prefix}/lib/libOGoDatabaseProject*.so.5.1*

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
%{prefix}/lib/opengroupware.org-1.0a/commands/LSAccount.cmd
%{prefix}/lib/opengroupware.org-1.0a/commands/LSAddress.cmd
%{prefix}/lib/opengroupware.org-1.0a/commands/LSBase.cmd
%{prefix}/lib/opengroupware.org-1.0a/commands/LSDocuments.cmd
%{prefix}/lib/opengroupware.org-1.0a/commands/LSEnterprise.cmd
%{prefix}/lib/opengroupware.org-1.0a/commands/LSMail.cmd
%{prefix}/lib/opengroupware.org-1.0a/commands/LSNews.cmd
%{prefix}/lib/opengroupware.org-1.0a/commands/LSPerson.cmd
%{prefix}/lib/opengroupware.org-1.0a/commands/LSProject.cmd
%{prefix}/lib/opengroupware.org-1.0a/commands/LSResource.cmd
%{prefix}/lib/opengroupware.org-1.0a/commands/LSScheduler.cmd
%{prefix}/lib/opengroupware.org-1.0a/commands/LSSearch.cmd
%{prefix}/lib/opengroupware.org-1.0a/commands/LSTasks.cmd
%{prefix}/lib/opengroupware.org-1.0a/commands/LSTeam.cmd
%{prefix}/lib/opengroupware.org-1.0a/commands/OGo.model
%{prefix}/lib/libLSAddress*.so.5.1*
%{prefix}/lib/libLSFoundation*.so.5.1*
%{prefix}/lib/libLSSearch*.so.5.1*
%{prefix}/lib/libOGoSchedulerTools*.so.5.1*

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

%files pda
%defattr(-,root,root,-)
%{prefix}/sbin/ogo-nhsd-1.0a
%{prefix}/bin/ogo-ppls-1.0a
%{prefix}/lib/libOGoNHS*.so.5.1*
%{prefix}/lib/%{ogo_libogopalmui}.so.5.1*
%{prefix}/lib/%{ogo_libogopalm}.so.5.1*
%{prefix}/lib/libPPSync*.so.5.1*
%{prefix}/lib/opengroupware.org-1.0a/conduits/OpenGroupwareNHS.conduit/OpenGroupwareNHS
%{prefix}/lib/opengroupware.org-1.0a/conduits/OpenGroupwareNHS.conduit/Resources/Info-gnustep.plist
%{prefix}/lib/opengroupware.org-1.0a/conduits/OpenGroupwareNHS.conduit/bundle-info.plist
%{prefix}/lib/opengroupware.org-1.0a/conduits/OpenGroupwareNHS.conduit/stamp.make
%{prefix}/lib/opengroupware.org-1.0a/datasources/OGoPalmDS.ds/OGoPalmDS
%{prefix}/lib/opengroupware.org-1.0a/datasources/OGoPalmDS.ds/Resources/Info-gnustep.plist
%{prefix}/lib/opengroupware.org-1.0a/datasources/OGoPalmDS.ds/bundle-info.plist
%{prefix}/lib/opengroupware.org-1.0a/datasources/OGoPalmDS.ds/stamp.make
%{prefix}/lib/opengroupware.org-1.0a/webui/OGoPalm.lso

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
%{prefix}/share/opengroupware.org-1.0a/www/Danish.lproj
%{prefix}/share/opengroupware.org-1.0a/www/English.lproj
%{prefix}/share/opengroupware.org-1.0a/www/German.lproj
%{prefix}/share/opengroupware.org-1.0a/www/Italian.lproj
%{prefix}/share/opengroupware.org-1.0a/www/Polish.lproj
%{prefix}/share/opengroupware.org-1.0a/www/Spanish.lproj
%{prefix}/share/opengroupware.org-1.0a/www/WOStats.xsl
%{prefix}/share/opengroupware.org-1.0a/www/menu.js

%files theme-ooo
%defattr(-,root,root,-)
%{prefix}/share/opengroupware.org-1.0a/templates/Themes/OOo
%{prefix}/share/opengroupware.org-1.0a/www/English_OOo.lproj
%{prefix}/share/opengroupware.org-1.0a/www/German_OOo.lproj

%files theme-blue
%defattr(-,root,root,-)
%{prefix}/share/opengroupware.org-1.0a/templates/Themes/blue
%{prefix}/share/opengroupware.org-1.0a/www/English_blue.lproj
%{prefix}/share/opengroupware.org-1.0a/www/German_blue.lproj

%files theme-kde
%defattr(-,root,root,-)
%{prefix}/share/opengroupware.org-1.0a/templates/Themes/kde
%{prefix}/share/opengroupware.org-1.0a/www/English_kde.lproj

%files theme-orange
%defattr(-,root,root,-)
%{prefix}/share/opengroupware.org-1.0a/templates/Themes/orange
%{prefix}/share/opengroupware.org-1.0a/www/English_orange.lproj
%{prefix}/share/opengroupware.org-1.0a/www/German_orange.lproj

%files tools
%defattr(-,root,root,-)
%{prefix}/bin/sky_add_account
%{prefix}/bin/sky_del_account
%{prefix}/bin/sky_get_login_names
%{prefix}/bin/sky_install_procmail
%{prefix}/bin/sky_install_sieve
%{prefix}/bin/sky_send_bulk_messages
%{prefix}/bin/skyaptnotify
%{prefix}/bin/skycheckperm
%{prefix}/bin/skydefaults
%{prefix}/bin/skyjobs2ical
%{prefix}/bin/skylistacls
%{prefix}/bin/skylistprojects
%{prefix}/bin/skyprojectexporter
%{prefix}/bin/skyprojectimporter
%{prefix}/bin/skyruncmd

%files webui-app
%defattr(-,root,root,-)
%{prefix}/sbin/ogo-webui-1.0a
%{prefix}/lib/opengroupware.org-1.0a/webui
%{prefix}/share/opengroupware.org-1.0a/templates

%files webui-core
%defattr(-,root,root,-)
%{prefix}/lib/libOGoFoundation*.so.5.1*
%{prefix}/lib/opengroupware.org-1.0a/webui/AdminUI.lso
%{prefix}/lib/opengroupware.org-1.0a/webui/BaseUI.lso
%{prefix}/lib/opengroupware.org-1.0a/webui/OGoUIElements.lso
%{prefix}/lib/opengroupware.org-1.0a/webui/PreferencesUI.lso
%{prefix}/lib/opengroupware.org-1.0a/webui/PropertiesUI.lso
%{prefix}/lib/opengroupware.org-1.0a/webui/RelatedLinksUI.lso
%{prefix}/share/opengroupware.org-1.0a/templates/AdminUI
%{prefix}/share/opengroupware.org-1.0a/templates/BaseUI
%{prefix}/share/opengroupware.org-1.0a/templates/OGoUIElements
%{prefix}/share/opengroupware.org-1.0a/templates/PreferencesUI
%{prefix}/share/opengroupware.org-1.0a/templates/PropertiesUI
%{prefix}/share/opengroupware.org-1.0a/templates/RelatedLinksUI

%files webui-core-devel
%defattr(-,root,root,-)
%{prefix}/include/OGoFoundation
%{prefix}/lib/libOGoFoundation*.so

%files webui-calendar
%defattr(-,root,root,-)
%{prefix}/lib/opengroupware.org-1.0a/webui/LSWScheduler.lso
%{prefix}/lib/opengroupware.org-1.0a/webui/OGoResourceScheduler.lso
%{prefix}/lib/opengroupware.org-1.0a/webui/OGoScheduler.lso
%{prefix}/lib/opengroupware.org-1.0a/webui/OGoSchedulerDock.lso
%{prefix}/lib/opengroupware.org-1.0a/webui/OGoSchedulerViews.lso
%{prefix}/share/opengroupware.org-1.0a/templates/LSWScheduler
%{prefix}/share/opengroupware.org-1.0a/templates/OGoResourceScheduler
%{prefix}/share/opengroupware.org-1.0a/templates/OGoScheduler
%{prefix}/share/opengroupware.org-1.0a/templates/OGoSchedulerDock
%{prefix}/share/opengroupware.org-1.0a/templates/OGoSchedulerViews

%{prefix}/share/opengroupware.org-1.0a/Holidays.plist

%files webui-contact
%defattr(-,root,root,-)
%{prefix}/lib/opengroupware.org-1.0a/webui/AddressUI.lso
%{prefix}/lib/opengroupware.org-1.0a/webui/EnterprisesUI.lso
%{prefix}/lib/opengroupware.org-1.0a/webui/LDAPAccounts.lso
%{prefix}/lib/opengroupware.org-1.0a/webui/PersonsUI.lso
%{prefix}/share/opengroupware.org-1.0a/templates/AddressUI
%{prefix}/share/opengroupware.org-1.0a/templates/EnterprisesUI
%{prefix}/share/opengroupware.org-1.0a/templates/LDAPAccounts
%{prefix}/share/opengroupware.org-1.0a/templates/PersonsUI

%files webui-mailer
%defattr(-,root,root,-)
%{prefix}/lib/libOGoWebMail*.so.5.1*
%{prefix}/lib/opengroupware.org-1.0a/webui/LSWMail.lso
%{prefix}/lib/opengroupware.org-1.0a/webui/OGoMailEditor.lso
%{prefix}/lib/opengroupware.org-1.0a/webui/OGoMailFilter.lso
%{prefix}/lib/opengroupware.org-1.0a/webui/OGoMailInfo.lso
%{prefix}/lib/opengroupware.org-1.0a/webui/OGoMailViewers.lso
%{prefix}/lib/opengroupware.org-1.0a/webui/OGoRecipientLists.lso
%{prefix}/lib/opengroupware.org-1.0a/webui/OGoWebMail.lso
%{prefix}/share/opengroupware.org-1.0a/templates/LSWMail
%{prefix}/share/opengroupware.org-1.0a/templates/OGoMailEditor
%{prefix}/share/opengroupware.org-1.0a/templates/OGoMailFilter
%{prefix}/share/opengroupware.org-1.0a/templates/OGoMailInfo
%{prefix}/share/opengroupware.org-1.0a/templates/OGoMailViewers
%{prefix}/share/opengroupware.org-1.0a/templates/OGoRecipientLists
%{prefix}/share/opengroupware.org-1.0a/templates/OGoWebMail

%files webui-mailer-devel
%defattr(-,root,root,-)
%{prefix}/include/OGoWebMail
%{prefix}/lib/libOGoWebMail*.so

%files webui-news
%defattr(-,root,root,-)
%{prefix}/lib/opengroupware.org-1.0a/webui/NewsUI.lso
%{prefix}/share/opengroupware.org-1.0a/templates/NewsUI

%files webui-task
%defattr(-,root,root,-)
%{prefix}/lib/opengroupware.org-1.0a/webui/JobUI.lso
%{prefix}/share/opengroupware.org-1.0a/templates/JobUI

%files webui-project
%defattr(-,root,root,-)
%{prefix}/lib/opengroupware.org-1.0a/webui/LSWProject.lso
%{prefix}/lib/opengroupware.org-1.0a/webui/OGoDocInlineViewers.lso
%{prefix}/lib/opengroupware.org-1.0a/webui/OGoNote.lso
%{prefix}/lib/opengroupware.org-1.0a/webui/OGoProject.lso
%{prefix}/lib/opengroupware.org-1.0a/webui/OGoProjectInfo.lso
%{prefix}/lib/opengroupware.org-1.0a/webui/OGoProjectZip.lso
%{prefix}/share/opengroupware.org-1.0a/templates/LSWProject
%{prefix}/share/opengroupware.org-1.0a/templates/OGoDocInlineViewers
%{prefix}/share/opengroupware.org-1.0a/templates/OGoNote
%{prefix}/share/opengroupware.org-1.0a/templates/OGoProject
%{prefix}/share/opengroupware.org-1.0a/templates/OGoProjectInfo
%{prefix}/share/opengroupware.org-1.0a/templates/OGoProjectZip

%files webui-resource-basque
%defattr(-,root,root,-)
%{prefix}/share/opengroupware.org-1.0a/translations/Basque.lproj

%files webui-resource-dk
%defattr(-,root,root,-)
%{prefix}/share/opengroupware.org-1.0a/translations/Danish.lproj

%files webui-resource-nl
%defattr(-,root,root,-)
%{prefix}/share/opengroupware.org-1.0a/translations/Dutch.lproj

%files webui-resource-en
%defattr(-,root,root,-)
%{prefix}/share/opengroupware.org-1.0a/translations/English.lproj

%files webui-resource-fr
%defattr(-,root,root,-)
%{prefix}/share/opengroupware.org-1.0a/translations/French.lproj

%files webui-resource-de
%defattr(-,root,root,-)
%{prefix}/share/opengroupware.org-1.0a/translations/German.lproj

%files webui-resource-hu
%defattr(-,root,root,-)
%{prefix}/share/opengroupware.org-1.0a/translations/Hungarian.lproj

%files webui-resource-it
%defattr(-,root,root,-)
%{prefix}/share/opengroupware.org-1.0a/translations/Italian.lproj

%files webui-resource-jp
%defattr(-,root,root,-)
%{prefix}/share/opengroupware.org-1.0a/translations/Japanese.lproj

%files webui-resource-no
%defattr(-,root,root,-)
%{prefix}/share/opengroupware.org-1.0a/translations/Norwegian.lproj

%files webui-resource-pl
%defattr(-,root,root,-)
%{prefix}/share/opengroupware.org-1.0a/translations/Polish.lproj

%files webui-resource-pt
%defattr(-,root,root,-)
%{prefix}/share/opengroupware.org-1.0a/translations/Portuguese.lproj

%files webui-resource-sk
%defattr(-,root,root,-)
%{prefix}/share/opengroupware.org-1.0a/translations/Slovak.lproj

%files webui-resource-es
%defattr(-,root,root,-)
%{prefix}/share/opengroupware.org-1.0a/translations/Spanish.lproj

#%files webui-resource-se
#%defattr(-,root,root,-)
#%{prefix}/share/opengroupware.org-1.0a/translations/Swedish.lproj

%files webui-resource-ptbr
%defattr(-,root,root,-)
%{prefix}/share/opengroupware.org-1.0a/translations/ptBR.lproj

%files xmlrpcd
%defattr(-,root,root,-)
%{prefix}/sbin/ogo-xmlrpcd-1.0a

%files zidestore
%defattr(-,root,root,-)
%{prefix}/sbin/ogo-zidestore-1.3
%{prefix}/lib/libZSAppointments*.so.1.3*
%{prefix}/lib/libZSBackend*.so.1.3*
%{prefix}/lib/libZSContacts*.so.1.3*
%{prefix}/lib/libZSFrontend*.so.1.3*
%{prefix}/lib/libZSProjects*.so.1.3*
%{prefix}/lib/libZSTasks*.so.1.3*
%{prefix}/lib/zidestore-1.3/Appointments.zsp
%{prefix}/lib/zidestore-1.3/Contacts.zsp
%{prefix}/lib/zidestore-1.3/EvoConnect.zsp
%{prefix}/lib/zidestore-1.3/PrefsUI.zsp
%{prefix}/lib/zidestore-1.3/Projects.zsp
%{prefix}/lib/zidestore-1.3/RSS.zsp
%{prefix}/lib/zidestore-1.3/Tasks.zsp
%{prefix}/lib/zidestore-1.3/WCAP.zsp
%{prefix}/lib/zidestore-1.3/ZSCommon.zsp
%{prefix}/share/zidestore-1.3

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
