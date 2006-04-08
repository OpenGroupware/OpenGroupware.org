#!/bin/sh
# Frank Reppin
# (work in progress)

# PROVIDE: ogo-zidestore
# REQUIRE: postgresql
# KEYWORD: FreeBSD shutdown

# may be configured using the following
# rc.conf vars:
#
# ogo_zidestore_enable (bool): either YES or NO             (default: NO)
# ogo_zidestore_user (string): the user                     (default: ogo)
# ogo_zidestore_args (string): some defaults                (default: none, virtually everything
#                                                            can/and should be set in the configfiles)
# ogo_zidestore_version (string): the version               (default: currently 1.5)
# ogo_zidestore_delayedrestart (int): delay in seconds      (default: 3)


. /etc/rc.subr

name="ogo_zidestore"
rcvar=`set_rcvar`
load_rc_config ${name}

prefix="/usr/local"

ogo_zidestore_enable=${ogo_zidestore_enable:-"NO"}
ogo_zidestore_user=${ogo_zidestore_user:-"ogo"}
ogo_zidestore_args=${ogo_zidestore_args:-""}
ogo_zidestore_version=${ogo_zidestore_version:-"1.5"}
ogo_zidestore_delayedrestart=${ogo_zidestore_delayedrestart:-"3"}

procname="ogo-zidestore-${ogo_zidestore_version}"

pidfile="/var/lib/opengroupware.org/${procname}.pid"

command="${prefix}/sbin/ogo-zidestore-${ogo_zidestore_version}"
start_cmd="ogo_zidestore_start"
stop_cmd="ogo_zidestore_stop"
restart_cmd="ogo_zidestore_restart"
status_cmd="ogo_zidestore_status"

ogo_zidestore_start() {
  this_pids="`pgrep ${procname}`"
  if [ -n "${this_pids}" ]; then
    echo -e "${procname} already running - pids used: `echo ${this_pids}|sed -e 's^\n^ ^g'`"
    exit 0
  else
    echo -e "Starting ${procname}."
    su -l ${ogo_zidestore_user} -c \
      "daemon ${command} ${ogo_zidestore_args} \
       2>> /var/log/opengroupware/ogo-zidestore-err.log \
       1>> /var/log/opengroupware/ogo-zidestore-out.log \
      "
  fi
}

ogo_zidestore_stop() {
  echo -e "Stopping ${procname}."
  pkill ${procname}
}

ogo_zidestore_restart() {
  ogo_zidestore_stop
  # wait n seconds for things to settle...
  echo " ...waiting ${ogo_zidestore_delayedrestart} seconds to settle."
  sleep ${ogo_zidestore_delayedrestart}
  ogo_zidestore_start
}

ogo_zidestore_status() {
  this_pids="`pgrep ${procname}`"
  if [ -n "${this_pids}" ]; then
    echo -e "${procname} is running - pids used: `echo ${this_pids}|sed -e 's^\n^ ^g'`"
  else
    echo -e "${procname} not running."
  fi
}

run_rc_command "$1"
