Summary:      OGo database setup.
Name:         ogo-database-setup
Version:      %{ogo_dbsetup_version}
Release:      %{ogo_dbsetup_buildcount}%{dist_suffix}
Vendor:       http://www.opengroupware.org
Packager:     Frank Reppin <frank@opengroupware.org>  
License:      LGPL
URL:          http://www.opengroupware.org
Group:        Development/Libraries
AutoReqProv:  off
Source:       %{ogo_dbsetup_source}
Prefix:       %{ogo_dbsetup_prefix}
BuildRoot:    %{_tmppath}/%{name}-%{version}-%{release}-root

%if %{?_postgresql_server_is_within_postgresql:1}%{!?_postgresql_server_is_within_postgresql:0}
Requires: postgresql
%else
Requires: postgresql-server
%endif

%description
This package sets up the Database required by OGo.

%prep
rm -fr ${RPM_BUILD_ROOT}
%setup -n opengroupware.org

# ****************************** build ********************************

# ****************************** install ******************************
%install
DBSETUP_DEST="${RPM_BUILD_ROOT}%{prefix}/share/opengroupware.org-1.1/dbsetup"
OGO_WEBUI_SYSCONFIG_NAME="ogo-webui-1.1"
OGO_SHAREDIR="opengroupware.org-1.1"
mkdir -p ${DBSETUP_DEST}

cp -Rp Database/SQLite ${DBSETUP_DEST}/
cp -Rp Database/PostgreSQL ${DBSETUP_DEST}/
cp -Rp Database/FrontBase ${DBSETUP_DEST}/
sed "s^OGO_WEBUI_SYSCONFIG_NAME^${OGO_WEBUI_SYSCONFIG_NAME}^g; \
     s^OGO_SHAREDIR^${OGO_SHAREDIR}^g" \
    %{_specdir}/db_setup_template/database_setup_psql.sh \
    >${DBSETUP_DEST}/database_setup_psql.sh
chmod 750 ${DBSETUP_DEST}/database_setup_psql.sh

# ****************************** post ********************************
%post
if [ $1 = 1 ]; then
  if [ -f "%{prefix}/share/opengroupware.org-1.1/dbsetup/database_setup_psql.sh" ]; then
    %{prefix}/share/opengroupware.org-1.1/dbsetup/database_setup_psql.sh initial
  fi
fi

# ****************************** postun *******************************

# ****************************** clean ********************************
%clean
rm -fr ${RPM_BUILD_ROOT}

# ****************************** files ********************************
%files
%defattr(-,root,root,-)
%{prefix}/share/opengroupware.org-1.1/dbsetup

# ********************************* changelog *************************
%changelog
* Tue Jul 19 2005 Frank Reppin <frank@opengroupware.org>
- fix permissions of setup script
* Tue Jul 05 2005 Frank Reppin <frank@opengroupware.org>
- fix creation of database_setup_psql.sh
* Fri Jun 17 2005 Helge Hess <helge.hess@opengroupware.org>
- patched pathes for version 1.1
* Tue Mar 01 2005 Frank Reppin <frank@opengroupware.org>
- drop dependency on ogo-environment
* Sat Jan 29 2005 Frank Reppin <frank@opengroupware.org>
- run 'database_setup_psql.sh initial' in post (if 1)
  (execution can be fully disabled by editing sysconfig/ogo-webui-1.1)
* Tue Jan 25 2005 Frank Reppin <frank@opengroupware.org>
- fix for OGo Bug #1192
* Sun Jan 16 2005 Frank Reppin <frank@opengroupware.org>
- initial release
