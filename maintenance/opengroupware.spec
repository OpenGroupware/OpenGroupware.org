Summary:       OpenGroupware.
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
OGo.

#########################################
%package dbsetup
Summary:  docapi
Group:  Development/Libraries
#Requires:  ogo-gnustep_make
AutoReqProv:  off

%description dbsetup
database setup.
#########################################
%package docapi
Summary:  docapi
Group:  Development/Libraries
#Requires:  ogo-gnustep_make 
AutoReqProv:  off

%description docapi
docapi package.

%package docapi-fs-project
Summary:  docapi fs project
Group:  Development/Libraries
#Requires:  ogo-gnustep_make 
AutoReqProv:  off

%description docapi-fs-project
docapi filesystem project package.

%package docapi-fs-project-devel
Summary:  docapi fs project devel
Group:  Development/Libraries
#Requires:  ogo-gnustep_make 
AutoReqProv:  off

%description docapi-fs-project-devel
docapi filesystem project devel package.

%package docapi-db-project
Summary:  docapi db project
Group:  Development/Libraries
#Requires:  ogo-gnustep_make 
AutoReqProv:  off

%description docapi-db-project
docapi database project package.

%package docapi-db-project-devel
Summary:  docapi db project devel
Group:  Development/Libraries
#Requires:  ogo-gnustep_make 
AutoReqProv:  off

%description docapi-db-project-devel
docapi database project devel package.

%package docapi-devel
Summary:  docapi-devel
Group:  Development/Libraries
#Requires:  ogo-gnustep_make 
AutoReqProv:  off

%description docapi-devel
docapi devel package.
#########################################
%package logic
Summary:  logic
Group:  Development/Libraries
#Requires:  ogo-gnustep_make 
AutoReqProv:  off

%description logic
logic package.
##
%package logic-tools
Summary:  logic-tools
Group:  Development/Libraries
#Requires:  ogo-gnustep_make 
AutoReqProv:  off

%description logic-tools
logic tools package.
##
%package logic-devel
Summary:  logic-devel
Group:  Development/Libraries
#Requires:  ogo-gnustep_make 
AutoReqProv:  off

%description logic-devel
logic devel package.
#########################################
%package pda
Summary:  pda
Group:  Development/Libraries
#Requires:  ogo-gnustep_make 
AutoReqProv:  off

%description pda
pda package.

%package pda-devel
Summary:  pda devel
Group:  Development/Libraries
#Requires:  ogo-gnustep_make 
AutoReqProv:  off

%description pda-devel
pda devel package.
#########################################
%package theme-default
Summary:  theme default
Group:  Development/Libraries
#Requires:  ogo-gnustep_make 
AutoReqProv:  off

%description theme-default
theme default package.
##
%package theme-ooo
Summary:  theme ooo
Group:  Development/Libraries
#Requires:  ogo-gnustep_make 
AutoReqProv:  off

%description theme-ooo
theme ooo package.
##
%package theme-blue
Summary:  theme blue
Group:  Development/Libraries
#Requires:  ogo-gnustep_make 
AutoReqProv:  off

%description theme-blue
theme blue package.
##
%package theme-kde
Summary:  theme kde
Group:  Development/Libraries
#Requires:  ogo-gnustep_make 
AutoReqProv:  off

%description theme-kde
theme kde package.
##
%package theme-orange
Summary:  theme orange
Group:  Development/Libraries
#Requires:  ogo-gnustep_make 
AutoReqProv:  off

%description theme-orange
theme orange package.
#########################################
%package tools
Summary:  tools
Group:  Development/Libraries
#Requires:  ogo-gnustep_make 
AutoReqProv:  off

%description tools
tools package.
#########################################
%package webui-app
Summary:  webui app
Group:  Development/Libraries
#Requires:  ogo-gnustep_make 
AutoReqProv:  off

%description webui-app
webui app package.
#
%package webui-core
Summary:  webui core
Group:  Development/Libraries
#Requires:  ogo-gnustep_make 
AutoReqProv:  off

%description webui-core
webui core package.
##
%package webui-core-devel
Summary:  webui core devel
Group:  Development/Libraries
#Requires:  ogo-gnustep_make 
AutoReqProv:  off

%description webui-core-devel
webui core devel package.
##
%package webui-calendar
Summary:  webui calendar
Group:  Development/Libraries
#Requires:  ogo-gnustep_make 
AutoReqProv:  off

%description webui-calendar
webui calendar package.
##
%package webui-contact
Summary:  webui contact
Group:  Development/Libraries
#Requires:  ogo-gnustep_make 
AutoReqProv:  off

%description webui-contact
webui contact package.
##
%package webui-mailer
Summary:  webui mailer
Group:  Development/Libraries
#Requires:  ogo-gnustep_make 
AutoReqProv:  off

%description webui-mailer
webui mailer package.
##
%package webui-mailer-devel
Summary:  webui mailer devel
Group:  Development/Libraries
#Requires:  ogo-gnustep_make 
AutoReqProv:  off

%description webui-mailer-devel
webui mailer devel package.
##
%package webui-news
Summary:  webui news
Group:  Development/Libraries
#Requires:  ogo-gnustep_make 
AutoReqProv:  off

%description webui-news
webui news package.
##
%package webui-task
Summary:  webui task
Group:  Development/Libraries
#Requires:  ogo-gnustep_make 
AutoReqProv:  off

%description webui-task
webui task package.
##
%package webui-project
Summary:  webui project
Group:  Development/Libraries
#Requires:  ogo-gnustep_make 
AutoReqProv:  off

%description webui-project
webui project package.
##
%package webui-resource-basque
Summary:  webui resource basque
Group:  Development/Libraries
#Requires:  ogo-gnustep_make 
AutoReqProv:  off

%description webui-resource-basque
webui resource basque package.
##
%package webui-resource-dk
Summary:  webui resource dk
Group:  Development/Libraries
#Requires:  ogo-gnustep_make 
AutoReqProv:  off

%description webui-resource-dk
webui resource dk package.
##
%package webui-resource-nl
Summary:  webui resource nl
Group:  Development/Libraries
#Requires:  ogo-gnustep_make 
AutoReqProv:  off

%description webui-resource-nl
webui resource nl package.
##
%package webui-resource-en
Summary:  webui resource en
Group:  Development/Libraries
#Requires:  ogo-gnustep_make 
AutoReqProv:  off

%description webui-resource-en
webui resource en package.
##
%package webui-resource-fr
Summary:  webui resource fr
Group:  Development/Libraries
#Requires:  ogo-gnustep_make 
AutoReqProv:  off

%description webui-resource-fr
webui resource fr package.
##
%package webui-resource-de
Summary:  webui resource de
Group:  Development/Libraries
#Requires:  ogo-gnustep_make 
AutoReqProv:  off

%description webui-resource-de
webui resource de package.
##
%package webui-resource-hu
Summary:  webui resource hu
Group:  Development/Libraries
#Requires:  ogo-gnustep_make 
AutoReqProv:  off

%description webui-resource-hu
webui resource hu package.
##
%package webui-resource-it
Summary:  webui resource it
Group:  Development/Libraries
#Requires:  ogo-gnustep_make 
AutoReqProv:  off

%description webui-resource-it
webui resource it package.
##
%package webui-resource-jp
Summary:  webui resource jp
Group:  Development/Libraries
#Requires:  ogo-gnustep_make 
AutoReqProv:  off

%description webui-resource-jp
webui resource jp package.
##
%package webui-resource-no
Summary:  webui resource no
Group:  Development/Libraries
#Requires:  ogo-gnustep_make 
AutoReqProv:  off

%description webui-resource-no
webui resource no package.
##
%package webui-resource-pl
Summary:  webui resource pl
Group:  Development/Libraries
#Requires:  ogo-gnustep_make 
AutoReqProv:  off

%description webui-resource-pl
webui resource pl package.
##
%package webui-resource-pt
Summary:  webui resource pt
Group:  Development/Libraries
#Requires:  ogo-gnustep_make 
AutoReqProv:  off

%description webui-resource-pt
webui resource pt package.
##
%package webui-resource-es
Summary:  webui resource es
Group:  Development/Libraries
#Requires:  ogo-gnustep_make 
AutoReqProv:  off

%description webui-resource-es
webui resource es package.
##
%package webui-resource-sk
Summary:  webui resource sk
Group:  Development/Libraries
#Requires:  ogo-gnustep_make 
AutoReqProv:  off

%description webui-resource-sk
webui resource sk package.
##
#%package webui-resource-se
#Summary:  webui resource se
#Group:  Development/Libraries
##Requires:  ogo-gnustep_make 
#AutoReqProv:  off
#
#%description webui-resource-se
#webui resource se package.
##
%package webui-resource-ptbr
Summary:  webui resource ptbr
Group:  Development/Libraries
#Requires:  ogo-gnustep_make 
AutoReqProv:  off

%description webui-resource-ptbr
webui resource ptbr package.
#########################################
%package xmlrpcd
Summary:  xmlrpcd
Group:  Development/Libraries
#Requires:  ogo-gnustep_make 
AutoReqProv:  off

%description xmlrpcd
xmlrpcd package.
#########################################
%package zidestore
Summary:  zidestore
Group:  Development/Libraries
#Requires:  ogo-gnustep_make 
AutoReqProv:  off

%description zidestore
zidestore package.

%package zidestore-devel
Summary:  zidestore devel
Group:  Development/Libraries
#Requires:  ogo-gnustep_make 
AutoReqProv:  off

%description zidestore-devel
zidestore devel package.

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
