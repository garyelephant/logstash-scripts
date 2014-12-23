#! /bin/sh
#
#       /etc/rc.d/init.d/logstash
#
#       Starts Logstash as a daemon
#
# chkconfig: 2345 90 10
# description: Starts Logstash as a daemon
# this is for Logstash 1.4.0+

### BEGIN INIT INFO
# Provides: logstash
# Required-Start: $local_fs $remote_fs
# Required-Stop: $local_fs $remote_fs
# Default-Start: 2 3 4 5
# Default-Stop: S 0 1 6
# Short-Description: Logstash
# Description: Starts Logstash as a daemon.

### END INIT INFO

. /etc/rc.d/init.d/functions

# rember to include your JAVA bin PATH
PATH=/bin:/usr/bin:/sbin:/usr/sbin:/usr/local/jdk/bin/
NAME=logstash
DESC="Logstash Daemon"
DEFAULT=/etc/sysconfig/$NAME

if [ `id -u` -ne 0 ]; then
    echo "You need root privileges to run this script"
    exit 1
fi

# The following variables can be overwritten in $DEFAULT

# Directory where the logstash all in one jar lives
LS_HOME=/opt/logstash
LOGSTASH_BIN=${LS_HOME}/bin/logstash

# logstash log directory
LOG_DIR=/data0/logstash

# logstash configuration directory
CONF_DIR=/etc/logstash

# logstash log file
LOG_FILE=$LOG_DIR/$NAME.log

# Open File limit
OPEN_FILES=20480

# Nice level
NICE=19

# Filter threads(higer number means higer load)
# nproc: the number of processing units available
FILTER_THREADS=`nproc`

# End of variables that can be overwritten in $DEFAULT

if [ -f "$DEFAULT" ]; then
    . "$DEFAULT"
fi

# Define other required variables
PID_FILE=/var/run/$NAME.pid

JAVA=`which java`
ARGS="agent --config ${CONF_DIR} --log ${LOG_FILE} -w ${FILTER_THREADS}"

START=true # this should be configured in the file of $DEFAULT

is_true() {
    if [ "x$1" = "xtrue" -o "x$1" = "xyes" -o "x$1" = "x1" ] ; then
        return 0
    else
        return 1
    fi
}

#
# Function that starts the daemon/service
#
do_start()
{

    if ! is_true "$START" ; then
        echo "logstash not configured to start, please edit $DEFAULT to enable"
        exit 0
    fi

    if [ -z "$JAVA" ]; then
        echo "no JDK found - $JAVA"
        exit 1
    fi

    if pidofproc -p "$PID_FILE" >/dev/null; then
        failure
        exit 99
    fi

    ulimit -n $OPEN_FILES

    cd $LS_HOME
    $LOGSTASH_BIN $ARGS > /dev/null 1>&1 &

    RETVAL=$?
    local PID=`pgrep -f "${ARGS}"`
    echo $PID > $PID_FILE
    success
}

#
# Function that stops the daemon/service
#
do_stop()
{
    killproc -p $PID_FILE
    RETVAL=$?
    echo
    [ $RETVAL = 0 ] && rm -f ${PID_FILE}
}

case "$1" in
    start)
        echo -n "Starting $DESC: "
        do_start
        ;;
    stop)
        echo -n "Stopping $DESC: "
        do_stop
        ;;
    restart|reload)
        echo -n "Restarting $DESC: "
        do_stop
        do_start
        ;;
    status)
        echo -n "$DESC"
        status -p $PID_FILE
        exit $?
        ;;
    *)
        echo "Usage: $SCRIPTNAME {start|stop|status|restart}" >&2
        exit 3
        ;;
esac

echo
exit 0
