#!/bin/bash

# defind environment 
PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin
export PATH

# dir bug fix
cd `dirname $0`

# check root, don't use root to run
if [[ "$(whoami)" = "root" ]]; then
    echo "please don't use root run this script!" >&2
    exit 1
fi 

# JDK
JDK_FILE_PATH=""
# 配置文件
ACTIVE_PROFILES=""
# 没有配置文件
NO_ACTIVE=""
# PID
PID_FILE_PATH=""
# JVM参数
VM_OPTIONS=""
# JAR
JAR_FILE_PATH=""

default_jdk_file_path(){
    echo "/data/service/java/bin"
}

default_active_profiles(){
    echo "dev"
}

default_jar_file_path(){
    echo `ls -t | grep "**.jar$" | head -n 1`
}

default_pid_file_path(){
    jar_file="$(default_jar_file_path)"
    if [ -z ${jar_file} ] 
    then
        jar_file="application"
    fi
    echo "${jar_file}.pid"
}

default_vm_options(){
    vm_params=" -server \
        -Xmx1g \
        -Xms1g \
        -Xmn512m \
        -XX:PermSize=128m \
        -Xss256k \
        -XX:+DisableExplicitGC \
        -XX:+UseConcMarkSweepGC \
        -XX:+CMSParallelRemarkEnabled \
        -XX:+UseCMSCompactAtFullCollection \
        -XX:LargePageSizeInBytes=128m \
        -XX:+UseFastAccessorMethods \
        -XX:+UseCMSInitiatingOccupancyOnly \
        -XX:CMSInitiatingOccupancyFraction=70 "
    echo "${vm_params} "
}

load_params(){
    if [ -z "${JDK_FILE_PATH}" ]; then
        JDK_FILE_PATH=`default_jdk_file_path`
    fi
    if [ -z "${ACTIVE_PROFILES}" ] && [ ! -z ${SPRING_BOOT_ACTIVE_ENV} ]; then
        ACTIVE_PROFILES=${SPRING_BOOT_ACTIVE_ENV}
    fi
    if [ -z "${ACTIVE_PROFILES}" ]; then
        ACTIVE_PROFILES=`default_active_profiles`
    fi
    if [ "${ACTIVE_PROFILES}" = "no" ]; then
        NO_ACTIVE="true"
    fi
    if [ -z "${PID_FILE_PATH}" ]; then
        PID_FILE_PATH=`default_pid_file_path`
    fi
    if [ -z "${VM_OPTIONS}" ]; then
        VM_OPTIONS=`default_vm_options`
    fi
    if [ -z "${JAR_FILE_PATH}" ]; then
        JAR_FILE_PATH=`default_jar_file_path`
    fi
}

load_run_command(){
    if [ "${NO_ACTIVE}" = "true" ]; then
        echo "nohup ${JDK_FILE_PATH}/java -jar ${JAR_FILE_PATH} ${VM_OPTIONS}  >/dev/null 2>nohup.error.log & echo \$! > ${PID_FILE_PATH}"
    else 
        echo "nohup ${JDK_FILE_PATH}/java -jar ${JAR_FILE_PATH} ${VM_OPTIONS}  --spring.profiles.active=${ACTIVE_PROFILES} >/dev/null 2>nohup.error.log & echo \$! > ${PID_FILE_PATH}"
    fi
}

load_stop_command(){
    echo "kill `cat ${PID_FILE_PATH}`"
}

check_application_running(){
    if [ -e ${PID_FILE_PATH} ]; then
        pid=`cat ${PID_FILE_PATH}`
        if [ ${pid} ]; then
            if [ -d /proc/${pid} ]; then
                echo -e "application is running,pid is ${pid}"
                ${JDK_FILE_PATH}/jps -l | grep ${pid}
                ps -ef | grep ${pid}
                return 0
            else
                echo -e "application is not running!"
                return 1
            fi
        else 
            echo -e "application is not running!"
            echo -e "application pid is not find!"
            return 1
        fi
    else
        echo -e "application is not running!"
        echo -e "application pid is not find!"
        return 1
    fi
}

start(){
    echo -e "start time:`date '+%Y-%m-%d %H:%M:%S'`"
    load_params
    
    # check jdk
    check_jdk
    is_find_jdk=$?
    if [ ${is_find_jdk} -eq 1 ]; then
        exit 1
    fi
    
    # check applicaiton running
    check_application_running
    is_running=$?
    if [ ${is_running} -eq 0 ]; then
        exit 1
    fi

    # check first jar file
    if [ ! -e ${JAR_FILE_PATH} ]; then
        echo "not find application jar!"
        exit 1
    fi

    echo -e ""
    echo -e "starting application..."
    echo -e ""
    echo -e "JDK_FILE_PATH:${JDK_FILE_PATH}"
    echo -e "VM_OPTIONS:${VM_OPTIONS}"
    echo -e "PID_FILE_PATH:${PID_FILE_PATH}"
    echo -e "JAR_FILE_PATH:${JAR_FILE_PATH}"
    echo -e "ACTIVE_PROFILES:${ACTIVE_PROFILES}"
    echo -e ""
    echo -e "run command: "`load_run_command`
    echo -e ""
    echo `load_run_command` | bash
    sleep 1
    if test -s nohup.error.log; then
        echo -e "start application error:=>>>>>>"
        echo "nohup error:=>>>>>> "`cat nohup.error.log`
        echo -e "start application error:<<<<<<="
        exit 1
    fi
    echo -e ""
    echo -e "end start application..."
    echo -e ""
    sleep 1
    echo -e "start check application status..."
    check_application_running
    echo -e "end check application status..."
    echo -e ""
    echo -e "end time:`date '+%Y-%m-%d %H:%M:%S'`"
}

stop(){
    echo -e "start time:`date '+%Y-%m-%d %H:%M:%S'`"
    load_params
    check_application_running
    is_running=$?
    if [ ${is_running} -eq 1 ]; then
        exit 1
    fi
    echo -e ""
    echo -e "stopping application..."
    echo -e ""
    echo -e "run command: "`load_stop_command`
    echo -e ""
    echo `load_stop_command` | bash
    echo -e "end stop application..."
    sleep 1
    echo -e ""
    echo -e "start check application status..."
    check_application_running
    echo -e "end check application status..."
    echo -e ""
    echo -e "end time:`date '+%Y-%m-%d %H:%M:%S'`"
}

status(){
    load_params
    check_application_running
}

check_jdk(){
    if type -p ${JDK_FILE_PATH}/java; then
        echo -e "find jdk in:${JDK_FILE_PATH}"
        return 0
    else
        echo -e "not find jdk in:${JDK_FILE_PATH}"
        return 1
    fi
}

show_start_log(){
    cat run.sh.start.log
}

show_stop_log(){
    cat run.sh.stop.log
}

show_nohup_error_log(){
    cat nohup.error.log
}

help_info(){
    echo
    echo -e "Usage: bash ./run.sh [start|stop|restart|status|help|...] [--active=\"dev\"]..."
    echo -e "help                       :print this help info"
    echo -e "start                      :start application"
    echo -e "stop                       :stop application"
    echo -e "restart                    :restart application"
    echo -e "status                     :application status"
    echo -e "show-start-log             :application start log"
    echo -e "show-stop-log              :application stop log"
    echo -e "show-start-error-log       :application start error log"
    echo -e "   -arg:[--jdk]            :jdk file path,default:"`default_jdk_file_path`   
    echo -e "   -arg:[--active]         :spring boot active profiles,default:"`default_active_profiles`  
    echo -e "   -arg:[--active=\"no\"]    :spring boot start for no active profiles"   
    echo -e "   -arg:[--pid]            :application pid file path,default:"`default_pid_file_path`   
    echo -e "   -arg:[--vm]             :java vm options,default:"`default_vm_options`   
    echo -e "   -arg:[--jar]            :application jar file path,default:"`default_jar_file_path`
    echo
}

# main
action=$1
shift

while [ "$1" != "${1##[-+]}" ]; do
  case $1 in
    '')    help_info
           return 1;;
    --jdk)
           JDK_FILE_PATH=$2
           shift 2
           ;;
    --jdk=?*)
           JDK_FILE_PATH=${1#--jdk=}
           shift
           ;;
    --active)
           ACTIVE_PROFILES=$2
           shift 2
           ;;
    --active=?*)
           ACTIVE_PROFILES=${1#--active=}
           shift
           ;;
    --pid)
           PID_FILE_PATH=$2
           shift 2
           ;;
    --pid=?*)
           PID_FILE_PATH=${1#--pid=}
           shift
           ;;
    --vm)
           VM_OPTIONS=$2
           shift 2
           ;;
    --vm=?*)
           VM_OPTIONS=${1#--vm=}
           shift
           ;;
    --jar)
           JAR_FILE_PATH=$2
           shift 2
           ;;
    --jar=?*)
           JAR_FILE_PATH=${1#--jar=}
           shift
           ;;
    *)     help_info
           return 1;;
  esac
done

case ${action} in
'start')
    start | tee -a run.sh.start.log
    ;;
'stop')
    stop | tee -a run.sh.stop.log
    ;;
'restart')
    stop | tee -a run.sh.restart.log
    start | tee -a run.sh.restart.log
    ;;
'status')
    status
    ;;
'show-start-log')
    show_start_log
    ;;
'show-stop-log')
    show_stop_log
    ;;
'show-start-error-log')
    show_nohup_error_log
    ;;
*|help)
    help_info
    ;;
esac
