Summary:       A free and open groupware suite.
Name:          ogoall
Version:       %{ogo_version}
Release:       %{ogo_release}.%{ogo_buildcount}%{dist_suffix}
Vendor:        http://www.opengroupware.org
Packager:      Frank Reppin <frank@opengroupware.org>  
License:       GPL
URL:           http://www.opengroupware.org
Group:         Development/Libraries
AutoReqProv:   off
%define ogo_gnustep_make_source gnustep-make-1.10.0.tar.gz
%define libf_objc_source        gnustep-objc-lf2.95.3-r85.tar.gz
%define libf_source             libFoundation-1.0.67-r91.tar.gz
%define sope_source             sope-4.4beta.2-voyager-r527.tar.gz
Source0:       %{ogo_gnustep_make_source}
Source1:       %{libf_objc_source}
Source2:       %{libf_source}
Source3:       %{sope_source}
Source4:       %{ogo_source}
Prefix:        %{ogo_prefix}
BuildRoot:     %{_tmppath}/%{name}-%{version}-%{release}-root
#XXUseSOPE:      sope-4.4beta.2-voyager

%description
OpenGroupware.org aims at being an open source groupware server which
integrates with the leading open source office suite products and all
the leading groupware clients running across all major platforms, and
to provide access to all functionality and data through open XML-based
interfaces and APIs. Additionally it has a web User Interface for
platform independent usage. OpenGroupware.org is built on top of the
SOPE application server.

#########################################
%prep
rm -fr ${RPM_BUILD_ROOT}
mkdir ${RPM_BUILD_ROOT}
cd ${RPM_BUILD_ROOT}
mkdir tmp

tar zxf %{_sourcedir}/%{ogo_gnustep_make_source} -C tmp
mv tmp/* gnustep-make
tar zxf %{_sourcedir}/%{libf_objc_source} -C tmp
mv tmp/* libobjc-lf2
tar zxf %{_sourcedir}/%{libf_source} -C tmp
mv tmp/* libfoundation
tar zxf %{_sourcedir}/%{sope_source} -C tmp
mv tmp/* sope
tar zxf %{_sourcedir}/%{ogo_source} -C tmp
mv tmp/* ogo

rm -rf tmp

# ****************************** build ********************************
%build

cd ${RPM_BUILD_ROOT}

OGO_INSTALL_ROOT=${RPM_BUILD_ROOT}%{prefix}/OGo-GNUstep

cd ${RPM_BUILD_ROOT}/gnustep-make
export CPPFLAGS=-Wno-import
export CFLAGS=-O0
./configure --prefix=${OGO_INSTALL_ROOT} \
  --with-library-combo=gnu-fd-nil \
  --with-user-root=${OGO_INSTALL_ROOT} \
  --with-network-root=${OGO_INSTALL_ROOT} \
  --with-local-root=${OGO_INSTALL_ROOT} \
  --without-system-root

make %{ogo_gnustep_make_makeflags} install

source ${RPM_BUILD_ROOT}%{prefix}/OGo-GNUstep/Library/Makefiles/GNUstep.sh

cd ${RPM_BUILD_ROOT}/libobjc-lf2
make %{libf_objc_makeflags} all
make %{libf_objc_makeflags} install

cd ${RPM_BUILD_ROOT}/libfoundation
export CFLAGS="-Wno-import -O0"
./configure
make %{libf_makeflags} all
make %{libf_makeflags} install
unset CFLAGS

cd ${RPM_BUILD_ROOT}/sope
make %{sope_makeflags}
make %{sope_makeflags} install

cd ${RPM_BUILD_ROOT}/ogo
make %{ogo_makeflags}

# ****************************** install ******************************
%install
source ${RPM_BUILD_ROOT}%{prefix}/OGo-GNUstep/Library/Makefiles/GNUstep.sh
mkdir -p GNUSTEP_INSTALLATION_DIR=${RPM_BUILD_ROOT}%{prefix}/lib/OGo-GNUstep

# libobjc-lf

cd ${RPM_BUILD_ROOT}/libobjc-lf2
make %{libf_objc_makeflags} GNUSTEP_INSTALLATION_DIR=${RPM_BUILD_ROOT}%{prefix}/OGo-GNUstep install

mkdir -p ${RPM_BUILD_ROOT}%{prefix}/lib
mv ${RPM_BUILD_ROOT}%{prefix}/OGo-GNUstep/Library/Libraries/libobjc*.so.lf2* \
   ${RPM_BUILD_ROOT}%{prefix}/lib/

# libFoundation

cd ${RPM_BUILD_ROOT}/libfoundation
mkdir -p ${RPM_BUILD_ROOT}%{prefix}/lib
mkdir -p ${RPM_BUILD_ROOT}%{prefix}/OGo-GNUstep/Library/Makefiles/Additional

make %{libf_makeflags} INSTALL_ROOT_DIR=${RPM_BUILD_ROOT} \
                       GNUSTEP_INSTALLATION_DIR=${RPM_BUILD_ROOT}%{prefix} \
                       FHS_INSTALL_ROOT=${RPM_BUILD_ROOT}%{prefix} \
                       install

rm -f ${RPM_BUILD_ROOT}%{prefix}/Library/Headers/libFoundation/extensions/exceptions/FoundationException.h
rm -f ${RPM_BUILD_ROOT}%{prefix}/Library/Headers/libFoundation/extensions/exceptions/GeneralExceptions.h
rm -f ${RPM_BUILD_ROOT}%{prefix}/Library/Headers/libFoundation/extensions/exceptions/NSCoderExceptions.h

# SOPE

cd ${RPM_BUILD_ROOT}/sope
mkdir -p ${RPM_BUILD_ROOT}%{prefix}/lib/lib
make %{sope_makeflags} INSTALL_ROOT_DIR=${RPM_BUILD_ROOT} \
                       GNUSTEP_INSTALLATION_DIR=${RPM_BUILD_ROOT}%{prefix} \
                       FHS_INSTALL_ROOT=${RPM_BUILD_ROOT}%{prefix} \
                       install

rm -f ${RPM_BUILD_ROOT}%{prefix}/bin/rss2plist1
rm -f ${RPM_BUILD_ROOT}%{prefix}/bin/rss2plist2
rm -f ${RPM_BUILD_ROOT}%{prefix}/bin/rssparse
rm -f ${RPM_BUILD_ROOT}%{prefix}/bin/testqp

# OGo

cd ${RPM_BUILD_ROOT}/ogo
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
rm -fr "${RPM_BUILD_ROOT}%{prefix}/share/opengroupware.org-1.0a/templates/ChangeLog"
rm -fr "${RPM_BUILD_ROOT}%{prefix}/share/opengroupware.org-1.0a/templates/GNUmakefile"
rm -fr "${RPM_BUILD_ROOT}%{prefix}/share/opengroupware.org-1.0a/templates/HelpUI"
rm -fr "${RPM_BUILD_ROOT}%{prefix}/share/opengroupware.org-1.0a/translations/COPYRIGHT"
rm -fr "${RPM_BUILD_ROOT}%{prefix}/share/opengroupware.org-1.0a/translations/ChangeLog"
rm -fr "${RPM_BUILD_ROOT}%{prefix}/share/opengroupware.org-1.0a/translations/GNUmakefile"
rm -fr "${RPM_BUILD_ROOT}%{prefix}/share/opengroupware.org-1.0a/www/GNUmakefile"
rm -fr "${RPM_BUILD_ROOT}%{prefix}/share/opengroupware.org-1.0a/www/tools"

#one lonely file for meta package...
echo "You've installed OGo %{ogo_version}-%{ogo_release} using the monolithic mega package!" \
     >"${RPM_BUILD_ROOT}%{prefix}/share/opengroupware.org-1.0a/INSTALLED.USING.MEGAPACKAGE"

INITSCRIPTS_TMP_DIR_OGO="${RPM_BUILD_ROOT}%{prefix}/share/opengroupware.org-1.0a/initscript_templates"
INITSCRIPTS_TMP_DIR_ZIDE="${RPM_BUILD_ROOT}%{prefix}/share/zidestore-1.3/initscript_templates"
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
" >${RPM_BUILD_ROOT}%{_sysconfdir}/sysconfig/ogo-webui-1.0a

# ****************************** post *********************************
%post
# libobjc-lf
if [ $1 = 1 ]; then
  if [ -d %{_sysconfdir}/ld.so.conf.d ]; then
    echo "%{prefix}/lib" > %{_sysconfdir}/ld.so.conf.d/libobjc-lf2.conf
  elif [ ! "`grep '%{prefix}/lib' %{_sysconfdir}/ld.so.conf`" ]; then
    echo "%{prefix}/lib" >> %{_sysconfdir}/ld.so.conf
  fi
fi

# libFoundation

if [ $1 = 1 ]; then
  if [ -d %{_sysconfdir}/ld.so.conf.d ]; then
    echo "%{prefix}/lib" > %{_sysconfdir}/ld.so.conf.d/libfoundation.conf
  elif [ ! "`grep '%{prefix}/lib' %{_sysconfdir}/ld.so.conf`" ]; then
    echo "%{prefix}/lib" >> %{_sysconfdir}/ld.so.conf
  fi
fi

# SOPE

if [ $1 = 1 ]; then
  if [ -d %{_sysconfdir}/ld.so.conf.d ]; then
    echo "%{prefix}/lib" > %{_sysconfdir}/ld.so.conf.d/sope%{sope_major_version}%{sope_minor_version}.conf
  elif [ ! "`grep '%{prefix}/lib' %{_sysconfdir}/ld.so.conf`" ]; then
    echo "%{prefix}/lib" >> %{_sysconfdir}/ld.so.conf
  fi
fi

# OGo

if [ $1 = 1 ]; then
  #must rework dependencies
  /sbin/ldconfig
fi

# pda
if [ $1 = 1 ]; then
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
    /sbin/ldconfig
  fi
fi

# webui-app
if [ $1 = 1 ]; then
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
  if [ -d %{_sysconfdir}/ld.so.conf.d ]; then
    echo "%{prefix}/lib" > %{_sysconfdir}/ld.so.conf.d/ogo.conf
  elif [ ! "`grep '%{prefix}/lib' %{_sysconfdir}/ld.so.conf`" ]; then
    echo "%{prefix}/lib" >> %{_sysconfdir}/ld.so.conf
  fi
  /sbin/ldconfig
fi

# xmlrpcd
if [ $1 = 1 ]; then
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
    /sbin/ldconfig
  fi
fi

# zidestore
if [ $1 = 1 ]; then
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
    /sbin/ldconfig
  fi
fi

# ****************************** postun *********************************
%postun
# SOPE
if [ $1 = 0 ]; then
  if [ -e %{_sysconfdir}/ld.so.conf.d/sope%{sope_major_version}%{sope_minor_version}.conf ]; then
    rm -f %{_sysconfdir}/ld.so.conf.d/sope%{sope_major_version}%{sope_minor_version}.conf
  fi
fi

# libFoundation

if [ $1 = 0 ]; then
  if [ -e %{_sysconfdir}/ld.so.conf.d/libfoundation.conf ]; then
    rm -f %{_sysconfdir}/ld.so.conf.d/libfoundation.conf
  fi
fi

# libobjc-lf
if [ $1 = 0 ]; then
  if [ -h %{prefix}/OGo-GNUstep/Library/Libraries/libobjc_d.so.lf2 ]; then
    rm -f %{prefix}/OGo-GNUstep/Library/Libraries/libobjc_d.so.lf2
  fi
  if [ -h %{prefix}/OGo-GNUstep/Library/Libraries/libobjc.so.lf2 ]; then
    rm -f %{prefix}/OGo-GNUstep/Library/Libraries/libobjc.so.lf2
  fi
  if [ -e %{_sysconfdir}/ld.so.conf.d/libobjc-lf2.conf ]; then
    rm -f %{_sysconfdir}/ld.so.conf.d/libobjc-lf2.conf
  fi
fi

# run ldconfig
if [ $1 = 0 ]; then
  /sbin/ldconfig
fi

# gstep-make
if [ $1 = 0 ]; then
cd %{prefix}/OGo-GNUstep
  rm -f Makefiles
fi

# ****************************** preun *********************************
%preun
# pda
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
  /sbin/ldconfig
fi

# webui-app
if [ $1 = 0 ]; then
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
  if [ -e %{_sysconfdir}/ld.so.conf.d/ogo.conf ]; then
    rm -f %{_sysconfdir}/ld.so.conf.d/ogo.conf
  fi
  /sbin/ldconfig
fi

# xmlrpcd
if [ $1 = 0 ]; then
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
  /sbin/ldconfig
fi

# zidestore
if [ $1 = 0 ]; then
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
  /sbin/ldconfig
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
%{prefix}/lib/libFoundation*.so.%{libf_version}
%{prefix}/lib/libFoundation*.so.%{libf_major_version}.%{libf_minor_version}
%{prefix}/share/libFoundation/CharacterSets
%{prefix}/share/libFoundation/Defaults
%{prefix}/share/libFoundation/TimeZoneInfo

# sope
%{prefix}/bin/connect-EOAdaptor
%{prefix}/bin/load-EOAdaptor
%{prefix}/bin/xmlrpc_call
%{prefix}/lib/libDOM*.so.%{sope_libversion}*
%{prefix}/lib/libEOControl*.so.%{sope_libversion}*
%{prefix}/lib/libGDLAccess*.so.%{sope_libversion}*
%{prefix}/lib/libNGExtensions*.so.%{sope_libversion}*
%{prefix}/lib/libNGLdap*.so.%{sope_libversion}*
%{prefix}/lib/libNGMime*.so.%{sope_libversion}*
%{prefix}/lib/libNGObjWeb*.so.%{sope_libversion}*
%{prefix}/lib/libNGStreams*.so.%{sope_libversion}*
%{prefix}/lib/libNGXmlRpc*.so.%{sope_libversion}*
%{prefix}/lib/libNGiCal*.so.%{sope_libversion}*
%{prefix}/lib/libSaxObjC*.so.%{sope_libversion}*
%{prefix}/lib/libSoOFS*.so.%{sope_libversion}*
%{prefix}/lib/libWEExtensions*.so.%{sope_libversion}*
%{prefix}/lib/libWOExtensions*.so.%{sope_libversion}*
%{prefix}/lib/libWOXML*.so.%{sope_libversion}*
%{prefix}/lib/libXmlRpc*.so.%{sope_libversion}*
%{prefix}/lib/sope-%{sope_libversion}/dbadaptors/PostgreSQL.gdladaptor
%{prefix}/lib/sope-%{sope_libversion}/products/SoCore.sxp
%{prefix}/lib/sope-%{sope_libversion}/products/SoOFS.sxp
%{prefix}/lib/sope-%{sope_libversion}/saxdrivers/STXSaxDriver.sax
%{prefix}/lib/sope-%{sope_libversion}/saxdrivers/libxmlSAXDriver.sax
%{prefix}/lib/sope-%{sope_libversion}/saxdrivers/versitSaxDriver.sax
%{prefix}/lib/sope-%{sope_libversion}/wox-builders/WEExtensions.wox
%{prefix}/lib/sope-%{sope_libversion}/wox-builders/WOExtensions.wox
%{prefix}/sbin/sope-%{sope_major_version}.%{sope_minor_version}
%{prefix}/share/sope-%{sope_libversion}/ngobjweb/DAVPropMap.plist
%{prefix}/share/sope-%{sope_libversion}/ngobjweb/Defaults.plist
%{prefix}/share/sope-%{sope_libversion}/ngobjweb/Languages.plist
%{prefix}/share/sope-%{sope_libversion}/saxmappings/NGiCal.xmap

# ogo
%attr(0644,root,root) %config %{_sysconfdir}/sysconfig/ogo-webui-1.0a
%{prefix}/bin/load-LSModel
%{prefix}/bin/ogo-ppls-1.0a
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
%{prefix}/lib/opengroupware.org-1.0a/commands/LSResource.cmd
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
%{prefix}/sbin/ogo-webui-1.0a
%{prefix}/sbin/ogo-xmlrpcd-1.0a
%{prefix}/sbin/ogo-zidestore-1.3
%{prefix}/share/opengroupware.org-1.0a/initscript_templates/*xmlrpcd
%{prefix}/share/zidestore-1.3
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


# ********************************* changelog *************************
%changelog
* Thu Feb 17 2005 Frank Reppin <frank@opengroupware.org>
- initial build
