#!/bin/sh
# Frank Reppin
# (work in progress)

# PROVIDE: ogo-webui
# REQUIRE: postgresql
# KEYWORD: FreeBSD shutdown

# may be configured using the following
# rc.conf vars:
#
# ogo_webui_enable (bool): either YES or NO             (default: NO)
# ogo_webui_user (string): the user                     (default: ogo)
# ogo_webui_args (string): some defaults                (default: none, virtually everything
#                                                        can/and should be set in the configfiles)
# ogo_webui_version (string): the version               (default: currently 1.1)
# ogo_webui_delayedrestart (int): delay in seconds      (default: 3)


. /etc/rc.subr

name="ogo_webui"
rcvar=`set_rcvar`
load_rc_config ${name}

prefix="/usr/local"

ogo_webui_enable=${ogo_webui_enable:-"NO"}
ogo_webui_user=${ogo_webui_user:-"ogo"}
ogo_webui_args=${ogo_webui_args:-""}
ogo_webui_version=${ogo_webui_version:-"1.1"}
ogo_webui_delayedrestart=${ogo_webui_delayedrestart:-"3"}

procname="ogo-webui-${ogo_webui_version}"

pidfile="/var/lib/opengroupware.org/${procname}.pid"

command="${prefix}/sbin/ogo-webui-${ogo_webui_version}"
start_cmd="ogo_webui_start"
stop_cmd="ogo_webui_stop"
restart_cmd="ogo_webui_restart"
status_cmd="ogo_webui_status"

ogo_webui_start() {
  this_pids="`pgrep ${procname}`"
  if [ -n "${this_pids}" ]; then
    echo -e "${procname} already running - pids used: `echo ${this_pids}|sed -e 's^\n^ ^g'`"
    exit 0
  else
    echo -e "Starting ${procname}."
    su -l ${ogo_webui_user} -c \
      "daemon ${command} ${ogo_webui_args} \
       2>> /var/log/opengroupware/ogo-webui-err.log \
       1>> /var/log/opengroupware/ogo-webui-out.log \
      "
  fi
}

ogo_webui_stop() {
  echo -e "Stopping ${procname}."
  pkill ${procname}
}

ogo_webui_restart() {
  ogo_webui_stop
  # wait n seconds for things to settle...
  echo " ...waiting ${ogo_webui_delayedrestart} seconds to settle."
  sleep ${ogo_webui_delayedrestart}
  ogo_webui_start
}

ogo_webui_status() {
  this_pids="`pgrep ${procname}`"
  if [ -n "${this_pids}" ]; then
    echo -e "${procname} is running - pids used: `echo ${this_pids}|sed -e 's^\n^ ^g'`"
  else
    echo -e "${procname} not running."
  fi
}

run_rc_command "$1"
