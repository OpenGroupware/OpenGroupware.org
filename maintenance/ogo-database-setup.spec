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

# ****************************** post ********************************
%post
if [ $1 = 1 ]; then
  OGO_DB_NAME="OGo"
  OGO_DB_USER="OGo"
  PG_USER="postgres"
  echo -en "adding PostgreSQL User: ${OGO_DB_USER}.\n"
  su - "${PG_USER}" -c "createdb \"${OGO_DB_NAME}\"; createuser -A -D \"${OGO_DB_USER}\"" 2>/dev/null || :
  echo -en "creating database ${OGO_DB_NAME}\n"
  su - "${PG_USER}" -c "/usr/bin/psql -U ${OGO_DB_USER} -d ${OGO_DB_NAME} \
        -f %{prefix}/share/opengroupware.org-1.0a/dbsetup/PostgreSQL/pg-build-schema.psql" 2>/dev/null || :
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
* Tue Jan 25 2005 Frank Reppin <frank@opengroupware.org>
- fix for OGo Bug #1192
* Sun Jan 16 2005 Frank Reppin <frank@opengroupware.org>
- initial release
