Summary:		OGo environment
Name:			ogo-environment
Version:		%{ogo_env_version}
Release:		%{ogo_env_release}.%{ogo_env_buildcount}
Vendor:			http://www.opengroupware.org
Packager:		Frank Reppin <frank@opengroupware.org>	
License:		LGPL
URL:			http://www.gnustep.org
Group:			Development/Libraries
AutoReqProv:	off
#Source:			%{ogo_env_source}
Prefix:			%{ogo_env_prefix}
#Patch:
#Requires:		
#BuildPreReq:	
BuildRoot:		%{_tmppath}/%{name}-%{version}-%{release}-root

%description
Adds the required user and some configurations.

%prep
rm -fr ${RPM_BUILD_ROOT}

# ****************************** build ********************************
%build

# ****************************** install ******************************
%install
mkdir -p ${RPM_BUILD_ROOT}/var/lib/opengroupware.org/.libFoundation/Defaults
mkdir -p ${RPM_BUILD_ROOT}/var/lib/opengroupware.org/documents
mkdir -p ${RPM_BUILD_ROOT}/var/lib/opengroupware.org/news

# ****************************** post ********************************
%pre
if [ $1 = 1 ]; then
  OGO_USER="ogo"
  OGO_GROUP="skyrix"
  OGO_SHELL="`which bash`"
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
  ### some defaults
  OGO_USER="ogo"
  export PATH=$PATH:%{prefix}/bin
  su - ${OGO_USER} -c "
  Defaults write NSGlobalDomain LSConnectionDictionary '{hostName=localhost; userName=OGo; password=\"\"; port=5432; databaseName=OGo}'
  Defaults write NSGlobalDomain skyrix_id `hostname`
  Defaults write NSGlobalDomain TimeZoneName GMT
  Defaults write NSGlobalDomain WOHttpAllowHost '( localhost, 127.0.0.1, localhost.localdomain)'
  Defaults write nhsd NGBundlePath '%{prefix}/opengroupware.org-1.0a/conduits'
  "
  #################
  if [ -f %{_var}/lib/pgsql/data/pg_hba.conf ]; then
    if [ "`grep -iE '^host.*all.*all.*127.0.0.1.*trust$' /var/lib/pgsql/data/pg_hba.conf`" ]; then
      echo -en "pg_hba.conf seems to be OK.\n"
    else
      echo -en "pg_hba.conf needs to be edited - please refer to our FAQ\n"
    fi
  fi
  if [ -f %{_var}/lib/pgsql/data/postgresql.conf ]; then
    if [ "`grep -iE '^tcpip_socket.*=.*true$' /var/lib/pgsql/data/postgresql.conf`" ]; then
      echo -en "postgresql.conf seems to be OK.\n"
    else
      echo -en "postgresql.conf needs to be edited - please refer to our FAQ\n"
    fi
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
%dir %attr(700,ogo,skyrix) %{_var}/lib/opengroupware.org/news

# ********************************* changelog *************************
%changelog
* Wed Sep 09 2004 Frank Reppin <frank@opengroupware.org>
- initial release
