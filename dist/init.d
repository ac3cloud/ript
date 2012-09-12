#!/bin/sh
### BEGIN INIT INFO
# Provides:          ript
# Required-Start:
# Required-Stop:
# Default-Start:     2 3 4 5
# Default-Stop:      0 1 6
# Short-Description: start and stop ript firewall
# Description:       Start, stop and save ript firewall
### END INIT INFO

# Author: John Ferlito <johnf@bulletproof.net>

PATH=/sbin:/bin
DESC="Restore ript firewall"
NAME=ript
IPTABLES_RESTORE=/sbin/iptables-restore
IPTABLES_STATE=/var/lib/ript/iptables.state
SCRIPTNAME=/etc/init.d/$NAME

# Exit if the package is not installed
[ -x "$IPTABLES_RESTORE" ] || exit 0

# Exit if no rules
[ -f "$IPTABLES_STATE" ] || exit 0

# Load the VERBOSE setting and other rcS variables
. /lib/init/vars.sh

# Define LSB log_* functions.
# Depend on lsb-base (>= 3.2-14) to ensure that this file is present
# and status_of_proc is working.
. /lib/lsb/init-functions

case "$1" in
  start|restart|force-reload)
    log_daemon_msg "Starting $DESC" "$NAME"
    $IPTABLES_RESTORE < $IPTABLES_STATE
    case "$?" in
      0|1) log_end_msg 0 ;;
      2) log_end_msg 1 ;;
    esac
    ;;
  *)
    echo "Usage: $SCRIPTNAME {start|restart|force-reload}" >&2
    exit 3
    ;;
esac
