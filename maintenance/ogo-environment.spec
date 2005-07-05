Summary:      OGo environment setup.
Name:         ogo-environment
Version:      %{ogo_env_version}
Release:      %{ogo_env_buildcount}%{dist_suffix}
Vendor:       http://www.opengroupware.org
Packager:     Frank Reppin <frank@opengroupware.org>  
License:      LGPL
URL:          http://www.gnustep.org
Group:        Development/Libraries
AutoReqProv:  off
#Source:      %{ogo_env_source}
Prefix:       %{ogo_env_prefix}
Requires:     ogo-webui-app
BuildRoot:    %{_tmppath}/%{name}-%{version}-%{release}-root

%description
Adds the required user/group and some configurations.

%prep
rm -fr ${RPM_BUILD_ROOT}

# ****************************** build ********************************

# ****************************** install ******************************
%install
mkdir -p ${RPM_BUILD_ROOT}/var/lib/opengroupware.org/.libFoundation/Defaults
mkdir -p ${RPM_BUILD_ROOT}/var/lib/opengroupware.org/documents
mkdir -p ${RPM_BUILD_ROOT}/var/lib/opengroupware.org/news
mkdir -p ${RPM_BUILD_ROOT}/var/log/opengroupware

# ****************************** post ********************************
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
  cd %{_sysconfdir}
  ln -s %{_var}/lib/opengroupware.org/.libFoundation opengroupware.org
  ## some defaults
  OGO_USER="ogo"
  OGO_GROUP="skyrix"
  OGO_HOME="/var/lib/opengroupware.org"
  export PATH=$PATH:%{prefix}/bin
  su - ${OGO_USER} -c "
  Defaults write NSGlobalDomain LSConnectionDictionary '{hostName=\"127.0.0.1\"; userName=OGo; password=\"\"; port=5432; databaseName=OGo}'
  Defaults write NSGlobalDomain LSNewsImagesPath '${OGO_HOME}/news'
  Defaults write NSGlobalDomain LSNewsImagesUrl '/ArticleImages'
  Defaults write NSGlobalDomain skyrix_id `hostname`
  Defaults write NSGlobalDomain TimeZoneName GMT
  Defaults write NSGlobalDomain WOHttpAllowHost '( localhost, 127.0.0.1, localhost.localdomain)'
  Defaults write ogo-nhsd-1.1 NGBundlePath '%{prefix}/lib/opengroupware.org-1.1/conduits'
  Defaults write skyaptnotify AptNotifyVerbose NO
  Defaults write skyaptnotify AptNotifyFromAdress '${OGO_USER}@`hostname`'
  Defaults write skyaptnotify AptNotifySentResourcesFile '%{_var}/log/opengroupware/sent-resources'
  Defaults write skyaptnotify AptNotifySkyrixPassword '\"\"'
  Defaults write skyaptnotify AptNotifySkyrixUser root
  "
  ##
  chmod 755 ${OGO_HOME}
  chown -R ${OGO_USER}:${OGO_GROUP} ${OGO_HOME}
  ##
  if [ -d %{_sysconfdir}/ld.so.conf.d ]; then
    echo "%{prefix}/lib" > %{_sysconfdir}/ld.so.conf.d/opengroupware.conf
  elif [ ! "`grep '%{prefix}/lib' %{_sysconfdir}/ld.so.conf`" ]; then
    echo "%{prefix}/lib" >> %{_sysconfdir}/ld.so.conf
  fi
  /sbin/ldconfig
fi

if [ $1 = 2 ]; then
  OGO_USER="ogo"
  OGO_GROUP="skyrix"
  if [ -e /var/log/opengroupware ]; then
    chown -R ${OGO_USER}:${OGO_GROUP} /var/log/opengroupware
  fi
fi

# ****************************** postun *******************************
%postun
if [ $1 = 0 ]; then
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
  if [ -e %{_sysconfdir}/ld.so.conf.d/opengroupware.conf ]; then
    rm -f %{_sysconfdir}/ld.so.conf.d/opengroupware.conf
  fi
  /sbin/ldconfig
fi

# ****************************** clean ********************************
%clean
rm -fr ${RPM_BUILD_ROOT}

# ****************************** files ********************************
%files
%defattr(-,ogo,skyrix,-)
%dir %attr(700,ogo,skyrix) %{_var}/lib/opengroupware.org/.libFoundation
%dir %attr(700,ogo,skyrix) %{_var}/lib/opengroupware.org/.libFoundation/Defaults
%dir %attr(700,ogo,skyrix) %{_var}/lib/opengroupware.org/documents
%dir %attr(755,ogo,skyrix) %{_var}/lib/opengroupware.org/news
%dir %attr(700,ogo,skyrix) %{_var}/log/opengroupware

# ********************************* changelog *************************
%changelog
* Tue Jul 05 2005 Frank Reppin <frank@opengroupware.org>
- added suggestion from Olivier to chown ogo:skyrix in post
  to gather current uid/gid (after removal)
* Fri Jun 17 2005 Helge Hess <helge.hess@opengroupware.org>
- patched pathes for version 1.1
* Mon Mar 14 2005 Frank Reppin <frank@opengroupware.org>
- added skyaptnotify defaults
* Thu Mar 10 2005 Frank Reppin <frank@opengroupware.org>
- prep fix for initscripts
* Sat Feb 19 2005 Frank Reppin <frank@opengroupware.org>
- fixed OGo Bug #1230:
  added LSNewsImagesPath/LSNewsImagesUrl
  made homedir and newsdir accessible for 'o' (ro - in order
  to satisfy apache)
* Tue Feb 01 2005 Frank Reppin <frank@opengroupware.org>
- don't use 'which' to determine the path to 'bash'
  (every buildhost has /bin/bash)
* Mon Jan 31 2005 Frank Reppin <frank@opengroupware.org>
- put NGBundlePath pointing to the conduits from NSGlobalDomain.plist
  to ogo-nhsd-1.0a.plist
* Sat Jan 29 2005 Frank Reppin <frank@opengroupware.org>
- removed obsolete DB config checks (obsoleted by ogo-database-setup)
* Tue Jan 18 2005 Frank Reppin <frank@opengroupware.org>
- add logdir (/var/log/opengroupware)
* Wed Sep 09 2004 Frank Reppin <frank@opengroupware.org>
- initial release
