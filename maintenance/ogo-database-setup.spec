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
Requires:     ogo-environment
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
DBSETUP_DEST="${RPM_BUILD_ROOT}%{prefix}/share/opengroupware.org-1.0a/dbsetup"
mkdir -p ${DBSETUP_DEST}

cp -Rp Database/SQLite ${DBSETUP_DEST}/
cp -Rp Database/PostgreSQL ${DBSETUP_DEST}/
cp -Rp Database/FrontBase ${DBSETUP_DEST}/
cp %{_specdir}/db_setup_template/database_setup_psql.sh ${DBSETUP_DEST}/

# ****************************** post ********************************
%post
if [ $1 = 1 ]; then
  if [ -f "%{prefix}/share/opengroupware.org-1.0a/dbsetup/database_setup_psql.sh" ]; then
    %{prefix}/share/opengroupware.org-1.0a/dbsetup/database_setup_psql.sh initial
  fi
fi

# ****************************** postun *******************************

# ****************************** clean ********************************
%clean
rm -fr ${RPM_BUILD_ROOT}

# ****************************** files ********************************
%files
%defattr(-,root,root,-)
%{prefix}/share/opengroupware.org-1.0a/dbsetup

# ********************************* changelog *************************
%changelog
* Sat Jan 29 2005 Frank Reppin <frank@opengroupware.org>
- run 'database_setup_psql.sh initial' in post (if 1)
  (execution can be fully disabled by editing sysconfig/ogo-webui-1.0a)
* Tue Jan 25 2005 Frank Reppin <frank@opengroupware.org>
- fix for OGo Bug #1192
* Sun Jan 16 2005 Frank Reppin <frank@opengroupware.org>
- initial release
