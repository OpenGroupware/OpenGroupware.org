#!/bin/sh
# several database operations <frank@opengroupware.org>
# defaults to yes (hic et ubique :p) 
#
# NOTE: the following sysconfig settings get written by 'ogo-webui-app'
# and thus you have the chance to reset the sysconfig settings to your needs
# (prior installing ogo-database-setup ... which will run this script)

RUN_DBSCRIPT="YES"                  # will run the whole script - or not, as thou wish
PATCH_POSTGRESQL_CONF="YES"         # will backup and patch postgresql.conf - if needed
PATCH_PGHBA_CONF="YES"              # will backup and patch pg_hba.conf - if needed
CREATE_DB_USER="YES"                # will create a DB user for OpenGroupware.org
CREATE_DB_ITSELF="YES"              # will create the DB itself for OpenGroupware.org
ROLLIN_SCHEME="YES"                 # will roll'in the current base DB scheme of OGo
FORCE_OVERRIDE_PRESENT_SCHEME="YES" # might harm thy current scheme (or not?)
UPDATE_SCHEMA="YES"                 # will attempt to update the database scheme - if needed
OGO_USER="ogo"                      # default username (unix) of your OGo install - might vary
PGCLIENTENCODING="LATIN1"           # client encoding to use

# pull in sysconfig settings - if present
# and thus override predefined vars upon request
[ -f /etc/sysconfig/OGO_WEBUI_SYSCONFIG_NAME ] && . /etc/sysconfig/OGO_WEBUI_SYSCONFIG_NAME

# these variables shouldn't be overriden by custom
# sysconfig settings (unless you really know what you do ofcourse!)
# I thought it might be useful to be some more generic here...
# this might allow one to use this script even for non standard PostgreSQL installations
COMMON_PG_USER="postgres"
COMMON_PG_GROUP="postgres"
COMMON_PG_PROCESSNAME="postmaster"
COMMON_PG_DATADIR_PREFIX="/var/lib/pgsql/data"
COMMON_POSTGRESQL_CONF="${COMMON_PG_DATADIR_PREFIX}/postgresql.conf"
COMMON_PGHBA_CONF="${COMMON_PG_DATADIR_PREFIX}/pg_hba.conf"
COMMON_PG_INITSCRIPT="/etc/init.d/postgresql"
DEFAULT_OGO_DB_NAME="OGo"
DEFAULT_OGO_DB_USER="OGo"
TEMP_LOG_PATH="/tmp"
NOW=`date +%Y%m%d-%H%M%S`
RUNS_ON="`uname`"

# where are the schemes we need?
COMMON_OGO_CORE_SCHEME_LOCATION="/usr/local/share/opengroupware.org-1.0a/dbsetup/PostgreSQL/pg-build-schema.psql"
COMMON_OGO_UPDATE_SCHEME_LOCATION="/usr/local/share/opengroupware.org-1.0a/dbsetup/PostgreSQL/pg-update-schema.psql"

# be more verbose on certain errors!
OGO_BUGZILLA_INDEX="http://bugzilla.opengroupware.org"
OGO_FAQ_INDEX="http://www.opengroupware.org/en/users/faq/index.html"
OGO_ML_INDEX="http://www.opengroupware.org/en/users/lists/index.html"

# EVERYTHING NECESSARY BELOW SHOULD BE HANDLED BY THE VARS ABOVE!!!
# (except certain no|yes checks... in order to keep customizable parts
# visible at the begining using 1024x768 :p)
# very early exit if the user doesn't want us to do anything at all
# recommended to all people with very custom PostgreSQL setups
# unless further reading in this script :)
if [ "x${RUN_DBSCRIPT}" = "xNO" ]; then
  echo -e "You've choosen that I should *not* attempt to"
  echo -e "do anything with your PostgreSQL setup."
  echo -e ""
  exit 0
fi

# get needed values from already installed plist
# LSConnectionDictionary might be present
LS_CONNECTION_DIR="`su - ${OGO_USER} -c \"Defaults read NSGlobalDomain LSConnectionDictionary\" 2>/dev/null`"
OGO_DB_USER="`echo ${LS_CONNECTION_DIR} | sed -r 's#.*userName[[:space:]]=[[:space:]]##;s#;.*$##;s#\"##g'`"
OGO_DB_ITSELF="`echo ${LS_CONNECTION_DIR} | sed -r 's#.*databaseName[[:space:]]=[[:space:]]##;s#;.*$##;s#\"##g'`"
# use default values if we don't have a LSConnectionDictionary
if [ "x${OGO_DB_USER}" = "x" ]; then
  #the default `Defaults` value == OGo
  OGO_DB_USER="${DEFAULT_OGO_DB_USER}"
fi

if [ "x${OGO_DB_ITSELF}" = "x" ]; then
  #the default `Defaults` value == OGo
  OGO_DB_ITSELF="${DEFAULT_OGO_DB_NAME}"
fi

initial()
{
  # get current postgres state
  # postgresql is already installed due to dependencies
  if [ ! -f "${COMMON_PG_DATADIR_PREFIX}/PG_VERSION"  ]; then
    echo -e "PostgreSQL not yet initialized."
    echo -e "(will be initialized by the initscript)"
    MUST_START_PG="YES"
  elif [ ! "`pgrep -u ${COMMON_PG_USER} ${COMMON_PG_PROCESSNAME}`" ]; then
    echo -e "PostgreSQL doesn't run yet."
    MUST_START_PG="YES"
  else
    echo -e "PostgreSQL seems to be already initialized"
    echo -e "and I can see it running:"
    PIDS="`pgrep -u ${COMMON_PG_USER} ${COMMON_PG_PROCESSNAME}`"
    PIDS="`echo ${PIDS} | sed -r 's#\n# #g'`"
    echo -e "PIDS used: ${PIDS}"
  fi
  
  if [ "x${MUST_START_PG}" = "xYES" ]; then
    #the initscript is named 'rhdb' on at least RHEL3
    if [ -f "/etc/init.d/rhdb" ]; then
      echo -e "Found '/etc/init.d/rhdb'..."
      /etc/init.d/rhdb start
      COMMON_PG_INITSCRIPT="/etc/init.d/rhdb"
    #everywhere else it should be 'postgresql'
    #(at least on all our RPM buildhosts)
    elif [ -f "/etc/init.d/postgresql" ]; then
      echo -e "Found '/etc/init.d/postgresql'"
      /etc/init.d/postgresql start
      #and check if we had success....
      #I cannot really rely on the returncode here...
      #while SUSE returns the actually true exitcode, Fedora doesn't
      #(SUSE returns indeed 1 if the start failed... Fedora returns 0 in every case
      #where the initscript itself exited with 0 - which doesn't necessarily suggest
      #that PostgreSQL is indeed running again :p)
      PIDS="`pgrep -u ${COMMON_PG_USER} ${COMMON_PG_PROCESSNAME}`"
      PIDS="`echo ${PIDS} | sed -r 's#\n# #g'`"
      if [ -n "${PIDS}" ]; then
        echo -e "OK! PostgreSQL runs now: ($PIDS)"
      else
        echo -e "Arrr! PostgreSQL doesn't run!"
        echo -e "It probably failed to start."
        exit 1
      fi
    else
      echo -e "Don't know how to start PostgreSQL."
      exit 1
    fi
  fi

  # check where we run on and get stats of config files
  if [ "x${RUNS_ON}" = "xLinux" ]; then
    POSTGRESQL_CONF_UID="`stat -c %u ${COMMON_POSTGRESQL_CONF}`"
    POSTGRESQL_CONF_GID="`stat -c %g ${COMMON_POSTGRESQL_CONF}`"
    POSTGRESQL_CONF_ACR="`stat -c %a ${COMMON_POSTGRESQL_CONF}`"
    PGHBA_CONF_UID="`stat -c %u ${COMMON_PGHBA_CONF}`"
    PGHBA_CONF_GID="`stat -c %g ${COMMON_PGHBA_CONF}`"
    PGHBA_CONF_ACR="`stat -c %a ${COMMON_PGHBA_CONF}`"
  fi

  #bail out immediately - if none exists... shouldn't happen in known cases
  #after we had an successful initdb with running postgresql
  if [ ! -f "${COMMON_POSTGRESQL_CONF}" ]; then
    echo -e "Although we had an initdb... I cannot see ${COMMON_POSTGRESQL_CONF}"
    echo -e "this indicates a probably really fatal error."
    echo -e "I cannot proceed setting up the OGo Database ${OGO_DB_ITSELF}"
    echo -e "... I quit!"
    echo -e "I suggest that you consult:"
    echo -e "  ${OGO_ML_INDEX}"
    echo -e "  ${OGO_FAQ_INDEX}"
    echo -e "  ${OGO_BUGZILLA_INDEX}"
    exit 1
  fi
  if [ ! -f "${COMMON_PGHBA_CONF}" ]; then
    echo -e "Although we had an initdb... I cannot see ${COMMON_PGHBA_CONF}"
    echo -e "this indicates a probably really fatal error."
    echo -e "I cannot proceed setting up the OGo Database ${OGO_DB_ITSELF}"
    echo -e "... I quit!"
    echo -e "I suggest that you consult:"
    echo -e "  ${OGO_ML_INDEX}"
    echo -e "  ${OGO_FAQ_INDEX}"
    echo -e "  ${OGO_BUGZILLA_INDEX}"
    exit 1
  fi
  
  if [ "x${PATCH_POSTGRESQL_CONF}" = "xYES" ]; then
    echo -e "checking ${COMMON_POSTGRESQL_CONF}"
    if [ "`grep -E "^tcpip_socket[[:space:]]*=[[:space:]]*true$" ${COMMON_POSTGRESQL_CONF}`"  ]; then
      echo -e "  no patching needed for ${COMMON_POSTGRESQL_CONF}"
      echo -e "  'tcpip_socket = true' already set."
      NEED_RESTART_TO_ACTIVATE="NO"
    else
      echo -e "  need to patch ${COMMON_POSTGRESQL_CONF}"
      echo -e "  backup current one to ${COMMON_POSTGRESQL_CONF}.${NOW}"
      sed -i.${NOW} -r "s~^#tcpip_socket.*~tcpip_socket = true~" ${COMMON_POSTGRESQL_CONF}
      chmod ${POSTGRESQL_CONF_ACR} ${COMMON_POSTGRESQL_CONF}
      chmod ${POSTGRESQL_CONF_ACR} ${COMMON_POSTGRESQL_CONF}.${NOW}
      chown ${POSTGRESQL_CONF_UID}:${POSTGRESQL_CONF_GID} ${COMMON_POSTGRESQL_CONF}
      chown ${POSTGRESQL_CONF_UID}:${POSTGRESQL_CONF_GID} ${COMMON_POSTGRESQL_CONF}.${NOW}
      NEED_RESTART_TO_ACTIVATE="YES"
    fi
  else
    echo -e "You didn't set PATCH_POSTGRESQL_CONF to \"YES\"... is set to ${PATCH_POSTGRESQL_CONF}"
    echo -e "So you don't want me to check your ${COMMON_POSTGRESQL_CONF}!"
    echo -e "skipping to next step..."
  fi
  
  if [ "x${PATCH_PGHBA_CONF}" = "xYES" ]; then
    echo -e "checking ${COMMON_PGHBA_CONF}"
    if [ "`grep -E "^host[[:space:]]*${OGO_DB_ITSELF}[[:space:]]*${OGO_DB_USER}[[:space:]]*127.0.0.1[[:space:]]*255.255.255.255[[:space:]]*trust$" ${COMMON_PGHBA_CONF}`" ]; then
      echo -e "  no patching needed for ${COMMON_PGHBA_CONF}"
      #restart to activate is already either `yes` or `no`
    else
      echo -e "  need to patch ${COMMON_PGHBA_CONF}"
      echo -e "  backup current one to ${COMMON_PGHBA_CONF}.${NOW}"
      cp ${COMMON_PGHBA_CONF} ${COMMON_PGHBA_CONF}.${NOW}
      #sed -i.${NOW} -r "s~#host\s+all\s+all\s+127.0.0.1\s+255.255.255.255.*~host    ${OGO_DB_ITSELF}    ${OGO_DB_USER}    127.0.0.1    255.255.255.255    trust~" ${COMMON_PGHBA_CONF}
      echo "host  ${OGO_DB_ITSELF}    ${OGO_DB_USER}    127.0.0.1    255.255.255.255    trust" >>${COMMON_PGHBA_CONF}
      chmod ${PGHBA_CONF_ACR} ${COMMON_PGHBA_CONF}
      chmod ${PGHBA_CONF_ACR} ${COMMON_PGHBA_CONF}.${NOW}
      chown ${PGHBA_CONF_UID}:${PGHBA_CONF_GID} ${COMMON_PGHBA_CONF}
      chown ${PGHBA_CONF_UID}:${PGHBA_CONF_GID} ${COMMON_PGHBA_CONF}.${NOW}
      NEED_RESTART_TO_ACTIVATE="YES"
    fi
  else
    echo -e "You didn't set PATCH_PGHBA_CONF to \"YES\"... is set to ${PATCH_PGHBA_CONF}"
    echo -e "So you don't want me to check your ${COMMON_PGHBA_CONF}!"
    echo -e "skipping to next step..."
  fi
  
  # config changes are done...
  # restart if required
  if [ "x${NEED_RESTART_TO_ACTIVATE}" = "xYES" ]; then
    echo -e "The changes we've made require that we restart PostgreSQL..."
    ${COMMON_PG_INITSCRIPT} stop
    ${COMMON_PG_INITSCRIPT} start
    PIDS="`pgrep -u ${COMMON_PG_USER} ${COMMON_PG_PROCESSNAME}`"
    PIDS="`echo ${PIDS} | sed -r 's#\n# #g'`"
    if [ -n "${PIDS}" ]; then
      echo -e "OK! PostgreSQL runs again: ($PIDS)"
    else
      # PAX VOBISCUM!
      # hopefully not due to an error in above mentioned patch section :p
      echo -e "Arrr! PostgreSQL doesn't run!"
      echo -e "It probably failed to restart."
      exit 1
    fi
  fi
  
  # create user...
  if [ "x${CREATE_DB_USER}" = "xYES" ]; then
    echo -e "creating database user: ${OGO_DB_USER}"
    RC_CREATE_USER="`su - ${COMMON_PG_USER} -c \"createuser -A -D ${OGO_DB_USER}\" 2>&1>/dev/null`"
    if [ -n "${RC_CREATE_USER}" ]; then
      echo -e "  Whoups! We've encountered an error during 'createuser':"
      echo -e "  The errormessage was => ${RC_CREATE_USER}"
      if [ "`echo ${RC_CREATE_USER} | grep -iE 'already[[:space:]]*exists'`" ]; then
        echo -e "  This isn't necessarily an error - I was *maybe* summoned via commandline with the wrong options"
        echo -e "  or you've attempted to recreate the database user '${OGO_DB_USER}' without removing him/her(?) first"
        CREATE_DB_USER_WAS_PRESENT="YES"
      else
        echo -e "  I don't know how to handle this exception - might be FATAL... please consider reading the FAQ/Bugzilla"
        echo -e "  regarding database setup issues or feel free to participate in our mailinglists - you're very welcome"
        echo -e "  to suggest further enhancements to our installation processes. ThankYou!!"
        echo -e "  ${OGO_ML_INDEX}"
        echo -e "  ${OGO_FAQ_INDEX}"
        echo -e "  ${OGO_BUGZILLA_INDEX}"
        exit 1
      fi
    else
      echo -e "  ... OK! (${RC_CREATE_USER})"
      CREATE_DB_USER_SUCCESS="YES"
    fi
  fi
  
  # create database...
  if [ "x${CREATE_DB_ITSELF}" = "xYES" ]; then
    echo -e "creating the database itself: ${OGO_DB_ITSELF}"
    RC_CREATE_DB="`su - ${COMMON_PG_USER} -c \"createdb -E ${PGCLIENTENCODING} -O ${OGO_DB_USER} ${OGO_DB_ITSELF}\" 2>&1>/dev/null`"
    if [ -n "${RC_CREATE_DB}" ]; then
      echo -e "  Whoups! We've encountered an error during 'createdb':"
      echo -e "  The errormessage was => ${RC_CREATE_DB}"
      if [ "`echo ${RC_CREATE_DB} | grep -iE 'already[[:space:]]*exists'`" ]; then
        echo -e "  This isn't necessarily an error - I was *maybe* summoned via commandline with the wrong options"
        echo -e "  or you've attempted to recreate the database '${OGO_DB_ITSELF}' without removing him/her(?) first"
        CREATE_DB_ITSELF_WAS_PRESENT="YES"
      else
        echo -e "  I don't know how to handle this exception - might be FATAL... please consider reading the FAQ/Bugzilla"
        echo -e "  regarding database setup issues or feel free to participate in our mailinglists - you're very welcome"
        echo -e "  to suggest further enhancements to our installation processes. Thank You!!"
        echo -e "  ${OGO_ML_INDEX}"
        echo -e "  ${OGO_FAQ_INDEX}"
        echo -e "  ${OGO_BUGZILLA_INDEX}"
        exit 1
      fi
    else
      echo -e "  ... OK! (${RC_CREATE_DB})"
      CREATE_DB_ITSELF_SUCCESS="YES"
    fi
  fi
  
  
  # roll in pg-build-scheme.psql
  # veni, vidi, vici!
  
  if [ "x${CREATE_DB_USER_SUCCESS}" = "xYES" -a "x${CREATE_DB_ITSELF_SUCCESS}" = "xYES" -o "x${FORCE_OVERRIDE_PRESENT_SCHEME}" = "xYES" ]; then
    echo -e "  we've successfully created both the user ${OGO_DB_USER} and the raw database ${OGO_DB_ITSELF}"
    echo -e "  we'll now fill the database with the scheme itself"
    # there shouldn't be an error in the scheme itself! take care!
    IAM="`basename $0`"
    LOG="${TEMP_LOG_PATH}/${IAM}.${NOW}.log"
    su - ${COMMON_PG_USER} -c "psql -h 127.0.0.1 -U ${OGO_DB_USER} -d ${OGO_DB_ITSELF} -f ${COMMON_OGO_CORE_SCHEME_LOCATION}" 1>/dev/null 2>${LOG}
    if [ -f "${LOG}" ]; then
      echo -e "checking the logfile created during scheme rollin... ${LOG}"
      LOG_SYNTAX_ERR="`grep -iE 'syntax[[:space:]]*error' ${LOG} | sed -r 's~^~  ~g'`"
      LOG_FATAL_ERR="`grep -E 'FATAL' ${LOG} | sed -r 's~^~  ~g'`"
      #LOG_NOTICE_ERR="`grep -E 'NOTICE' ${LOG} | sed -r 's~^~  ~g'`"
      if [ -n "${LOG_SYNTAX_ERR}" ]; then
        echo -e "  syntax error found:"
        echo -e "${LOG_SYNTAX_ERR}"
      fi
      if [ -n "${LOG_FATAL_ERR}" ]; then
        echo -e "  FATAL error found:"
        echo -e "${LOG_FATAL_ERR}"
      fi
      #if [ -n "${LOG_NOTICE_ERR}" ]; then
      #  echo -e "  NOTICE found:"
      #  echo -e "  ${LOG_NOTICE_ERR}"
      #fi
      # NOTICE is neither classified as FATAL or ERROR according to PostgreSQL code... and it should prolly be
      # on stdout rather than on stderr... however - nice to know that there are NOTICES'es anyways
      # ... maybe we got a use for it.
      # I don't want to stop the setup only if we see some `NOTICE`es when we rollin the scheme
      # since it only points to situations where nothing particular weird happened (which might harm the setup itself)
      # (and therefor it's commented out - might change in future PostgreSQL version - therefor still part of this script)
      if [ ! -n "${LOG_SYNTAX_ERR}" -a ! -n "${LOG_FATAL_ERR}" ]; then
        echo -e "removing log - not needed anymore"
        rm -f ${LOG}
      fi
    fi
    if [ -n "${LOG_SYNTAX_ERR}" -o "${LOG_FATAL_ERR}" ]; then
      echo -e "The above shown errors will significantly harm the functionality of your OpenGroupware"
      echo -e "installation."
      echo -e "I suggest that you consult:"
      echo -e "  ${OGO_ML_INDEX}"
      echo -e "  ${OGO_FAQ_INDEX}"
      echo -e "  ${OGO_BUGZILLA_INDEX}"
      echo -e "before you proceed! Thankyou!"
      exit 1
    fi
  fi
}

case "${1}" in
  initial)
    initial
  ;;
  *)
    echo -e "Usage: $0 initial"
  ;;
esac
