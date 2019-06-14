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

# crate run.sh log file path
if [ ! -d logs_run_sh ]; then
    mkdir logs_run_sh
fi

# JDK
JDK_FILE_PATH=""
# spring boot active profiles setting
ACTIVE_PROFILES=""
# not active profiles setting
NO_ACTIVE=""
# PID
PID_FILE_PATH=""
# JVM
VM_OPTIONS=""
# JAR
JAR_FILE_PATH=""

# sysvinit 
SYSVINIT_NAME=""
SYSVINIT_RUN_LEVEL=""
SYSVINIT_RUN_USER=""

# systemd
SYSTEMDINIT_NAME=""
SYSTEMDINIT_RUN_USER=""

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
        echo "nohup ${JDK_FILE_PATH}/java -jar ${JAR_FILE_PATH} ${VM_OPTIONS}  >/dev/null 2>logs_run_sh/nohup.error.log & echo \$! > logs_run_sh/${PID_FILE_PATH}"
    else 
        echo "nohup ${JDK_FILE_PATH}/java -jar ${JAR_FILE_PATH} ${VM_OPTIONS}  --spring.profiles.active=${ACTIVE_PROFILES} >/dev/null 2>logs_run_sh/nohup.error.log & echo \$! > logs_run_sh/${PID_FILE_PATH}"
    fi
}

load_stop_command(){
    echo "kill `cat logs_run_sh/${PID_FILE_PATH}`"
}

check_application_running(){
    if [ -e logs_run_sh/${PID_FILE_PATH} ]; then
        pid=`cat logs_run_sh/${PID_FILE_PATH}`
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
    if test -s logs_run_sh/nohup.error.log; then
        echo -e "start application error:=>>>>>>"
        echo "nohup error:=>>>>>> "`cat logs_run_sh/nohup.error.log`
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
    cat logs_run_sh/run.sh.start.log
}

show_stop_log(){
    cat logs_run_sh/run.sh.stop.log
}

show_nohup_error_log(){
    cat logs_run_sh/nohup.error.log
}

check_chkconfig(){
    if type -p chkconfig; then
        return 0
    else
        echo -e "your system not install chkconfig tools! please check!"
        return 1
    fi
}

check_systemctl(){
    if type -p systemctl; then
        return 0
    else
        echo -e "your system not install systemd tools!please check!"
        return 1
    fi
}

load_run_sh_command_params_str(){
    run_sh_command=""
    if [ ! -z "${JDK_FILE_PATH}" ]; then
        run_sh_command=${run_sh_command}" --jdk=\"${JDK_FILE_PATH}\""
    fi
    if [ ! -z "${ACTIVE_PROFILES}" ]; then 
        run_sh_command=${run_sh_command}" --active=\"${ACTIVE_PROFILES}\""
    elif [ ! -z ${SPRING_BOOT_ACTIVE_ENV} ]; then
        run_sh_command=${run_sh_command}" --active=\"${SPRING_BOOT_ACTIVE_ENV}\""
    elif [ "${ACTIVE_PROFILES}" = "no" ]; then
        run_sh_command=${run_sh_command}" --active=\"no\""
    fi
    if [ ! -z "${PID_FILE_PATH}" ]; then
        run_sh_command=${run_sh_command}" --pid=\"${PID_FILE_PATH}\""        
    fi
    if [ ! -z "${VM_OPTIONS}" ]; then
        run_sh_command=${run_sh_command}" --vm=\"${VM_OPTIONS}\""        
    fi
    if [ ! -z "${JAR_FILE_PATH}" ]; then
        run_sh_command=${run_sh_command}" --jar=\"${JAR_FILE_PATH}\""
    fi
    echo ${run_sh_command}
}

create_sysvinit_script(){
    sudo touch /etc/init.d/$1
    sudo chmod 777 /etc/init.d/$1
    # $1--sysvinit name
    # $2--run user
    # $3--chkconfig run level
    # $4--run.sh command params
    run_sh_script_dir="`pwd`"
cat > /etc/init.d/$1 << EOF
#!/bin/bash
#
# $1
#
# chkconfig: $3
# description: $1 is a Java Spring Boot Application Fast Start Script

# Source function library.
. /etc/init.d/functions

# Declare variables for this script
RETVAL=0
prog=$1

# Declare variables for Spring Boot

start() {
        su - $2 -c 'bash ${run_sh_script_dir}/run.sh start $4'
        return \$RETVAL
}

stop() {
        su - $2 -c 'bash ${run_sh_script_dir}/run.sh stop'
        return \$RETVAL
}

status() {
        su - $2 -c 'bash ${run_sh_script_dir}/run.sh status'
        return \$RETVAL
}

restart() {
        su - $2 -c 'bash ${run_sh_script_dir}/run.sh restart $4'
        return \$RETVAL
}

case "\$1" in
    start)
        # be careful, sysv check application is running, the first time can call stop and start!
        start
        ;;
    stop)
        stop
        ;;
    status)
        status
        ;;
    restart)
        restart
        ;;
    *)
        echo "Usage: \$prog {start|stop|status|restart}"
        exit 1
        ;;
esac
exit \$RETVAL
EOF
}

create_sysvinit(){
    # check
    check_chkconfig
    is_find_chkconfig=$?
    if [ ${is_find_chkconfig} -eq 1 ]; then
        exit 1
    fi

    echo -e "start create sysvinit script..."
    echo -e ""
    if [ -e logs_run_sh/sysvinit_service_name.log ]; then
        sysvinit_service_name=`cat logs_run_sh/sysvinit_service_name.log`
        if [ ${sysvinit_service_name} ]; then
            echo -e "sysvinit service is install! you have to delete it before you can use it!"
            exit 1
        fi
    fi
    if [ -z "${SYSVINIT_NAME}" ]; then
        s_profiles="${ACTIVE_PROFILES}"
        s_jarfile="${JAR_FILE_PATH}"
        if [ -z "${ACTIVE_PROFILES}" ] && [ ! -z ${SPRING_BOOT_ACTIVE_ENV} ]; then
            s_profiles=${SPRING_BOOT_ACTIVE_ENV}
        fi
        if [ -z "${ACTIVE_PROFILES}" ]; then
            s_profiles=`default_active_profiles`
        fi
        if [ -z "${JAR_FILE_PATH}" ]; then
            s_jarfile=`default_jar_file_path`
        fi
        echo -e "sysvinit service name not set! you can set args: --sysvinit-name=\"demo-name\", now use default:${s_jarfile}.${s_profiles}"
        SYSVINIT_NAME="${s_jarfile}.${s_profiles}"
    fi
    if [ -z "${SYSVINIT_RUN_LEVEL}" ]; then
        echo -e "sysvinit run level not set! you can set args: --sysvinit-run-level=\"345 70 30\", now use default: 2345 70 30"
        SYSVINIT_RUN_LEVEL="345 70 30"
    fi
    if [ -z "${SYSVINIT_RUN_USER}" ]; then
        echo -e "sysvinit service run user not set! you can set args: --sysvinit-run-user=\"demo-user\", now use default:www-data"
        SYSVINIT_RUN_USER="www-data"
    fi
    echo -e "SYSVINIT_NAME: "${SYSVINIT_NAME}
    echo -e "SYSVINIT_RUN_USER: "${SYSVINIT_RUN_USER}
    echo -e "SYSVINIT_RUN_LEVEL: "${SYSVINIT_RUN_LEVEL}
    echo -e "run_sh_command_script: `load_run_sh_command_params_str`"
    create_sysvinit_script "${SYSVINIT_NAME}" "${SYSVINIT_RUN_USER}" "${SYSVINIT_RUN_LEVEL}" "`load_run_sh_command_params_str`"
    echo -e ""
    echo -e "end create sysvinit script...."
    
    echo ${SYSVINIT_NAME} > logs_run_sh/sysvinit_service_name.log

    sudo chkconfig --add ${SYSVINIT_NAME}
    echo -e ""
}

delete_sysvinit(){
    # check
    check_chkconfig
    is_find_chkconfig=$?
    if [ ${is_find_chkconfig} -eq 1 ]; then
        exit 1
    fi

    echo -e "start delete sysvinit script..."
    echo -e ""
    if [ -z "${SYSVINIT_NAME}"]; then
        if [ -e logs_run_sh/sysvinit_service_name.log ]; then
            SYSVINIT_NAME=`cat logs_run_sh/sysvinit_service_name.log`
        else
            echo -e "sysvinit service name is not find!"
            exit 1
        fi
    fi
    sudo chkconfig --del ${SYSVINIT_NAME}
    sudo mv /etc/init.d/${SYSVINIT_NAME} /tmp/${SYSVINIT_NAME}'_'`date +%Y%m%d_%H%M%S`
    echo ""> logs_run_sh/sysvinit_service_name.log
    echo -e "end delete sysvinit script..."
    echo -e ""
}

show_sysvinit(){
    # check
    check_chkconfig
    is_find_chkconfig=$?
    if [ ${is_find_chkconfig} -eq 1 ]; then
        exit 1
    fi
    if [ -z "${SYSVINIT_NAME}"]; then
        if [ -e logs_run_sh/sysvinit_service_name.log ]; then
            SYSVINIT_NAME=`cat logs_run_sh/sysvinit_service_name.log`
            if [ ! ${SYSVINIT_NAME} ]; then
                echo -e "sysvinit service is not installed! please check it!"
                exit 1
            fi
        else
            echo -e "sysvinit service name is not find!"
            exit 1
        fi
    fi
    chkconfig --list ${SYSVINIT_NAME}
}

create_systemdinit_script(){
    sudo touch /etc/systemd/system/$1.service
    sudo chmod 777 /etc/systemd/system/$1.service
    # $1--sysvinit name
    # $2--run user
    # $3--run.sh command params
    run_sh_script_dir="`pwd`"
cat > /etc/systemd/system/$1.service << EOF
[Unit]
Description=$1

[Service]
User=$2
Type=oneshot
ExecStart=/bin/bash ${run_sh_script_dir}/run.sh start $3
ExecStop=/bin/bash ${run_sh_script_dir}/run.sh stop
Restart=/bin/bash ${run_sh_script_dir}/run.sh restart $3
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
EOF
}

create_systemdinit(){
    # check
    check_systemctl
    is_find_systemctl=$?
    if [ ${is_find_systemctl} -eq 1 ]; then
        exit 1
    fi

    echo -e "start create systemdinit script..."
    echo -e ""
    if [ -e logs_run_sh/systemdinit_service_name.log ]; then
        systemdinit_service_name=`cat logs_run_sh/systemdinit_service_name.log`
        if [ ${systemdinit_service_name} ]; then
            echo -e "systemdinit service is install! you have to delete it before you can use it!"
            exit 1
        fi
    fi
    if [ -z "${SYSTEMDINIT_NAME}" ]; then
        s_profiles="${ACTIVE_PROFILES}"
        s_jarfile="${JAR_FILE_PATH}"
        if [ -z "${ACTIVE_PROFILES}" ] && [ ! -z ${SPRING_BOOT_ACTIVE_ENV} ]; then
            s_profiles=${SPRING_BOOT_ACTIVE_ENV}
        fi
        if [ -z "${ACTIVE_PROFILES}" ]; then
            s_profiles=`default_active_profiles`
        fi
        if [ -z "${JAR_FILE_PATH}" ]; then
            s_jarfile=`default_jar_file_path`
        fi
        echo -e "systemdinti service name not set! you can set args: --systemdinit-name=\"demo-name\", now use default: ${s_jarfile}.${s_profiles}"
        SYSTEMDINIT_NAME="${s_jarfile}.${s_profiles}"
    fi
    if [ -z "${SYSTEMDINIT_RUN_USER}" ]; then
        echo -e "systemdinit service run user not set! you can set args: --systemdinit-run-user=\"demo-user\", now use default: www-data"
        SYSTEMDINIT_RUN_USER="www-data"
    fi
    echo -e "SYSTEMDINIT_NAME: "${SYSTEMDINIT_NAME}
    echo -e "SYSTEMDINIT_RUN_USER: "${SYSTEMDINIT_RUN_USER}
    echo -e "run_sh_command_script: `load_run_sh_command_params_str`"
    create_systemdinit_script "${SYSTEMDINIT_NAME}" "${SYSTEMDINIT_RUN_USER}" "`load_run_sh_command_params_str`"
    echo -e ""
    echo -e "end create systemdinit script...."
    
    echo ${SYSTEMDINIT_NAME} > logs_run_sh/systemdinit_service_name.log

    sudo systemctl enable ${SYSTEMDINIT_NAME}
    echo -e ""
}

delete_systemdinit(){
    # check
    check_systemctl
    is_find_systemctl=$?
    if [ ${is_find_systemctl} -eq 1 ]; then
        exit 1
    fi

    echo -e "start delete systemdinit script..."
    echo -e ""
    if [ -z "${SYSTEMDINIT_NAME}"]; then
        if [ -e logs_run_sh/systemdinit_service_name.log ]; then
            SYSTEMDINIT_NAME=`cat logs_run_sh/systemdinit_service_name.log`
        else
            echo -e "systemdinit service name is not find!"
            exit 1
        fi
    fi
    sudo systemctl disable ${SYSTEMDINIT_NAME}
    sudo mv /etc/systemd/system/${SYSTEMDINIT_NAME}.service /tmp/${SYSTEMDINIT_NAME}.service'_'`date +%Y%m%d_%H%M%S`
    echo ""> logs_run_sh/systemdinit_service_name.log
    echo -e "end delete systemdinit script..."
    echo -e ""
}

show_systemdinit(){
    # check
    check_systemctl
    is_find_systemctl=$?
    if [ ${is_find_systemctl} -eq 1 ]; then
        exit 1
    fi
    if [ -z "${SYSTEMDINIT_NAME}"]; then
        if [ -e logs_run_sh/systemdinit_service_name.log ]; then
            SYSTEMDINIT_NAME=`cat logs_run_sh/systemdinit_service_name.log`
            if [ ! ${SYSTEMDINIT_NAME} ]; then
                echo -e "systemdinit service is not installed! please check it!"
                exit 1
            fi
        else
            echo -e "systemdinit service name is not find!"
            exit 1
        fi
    fi
    systemctl list-unit-files | grep ${SYSTEMDINIT_NAME}
}

help_info(){
    echo
    echo -e "Usage: bash ./run.sh [start|stop|restart|status|help|...] [--active=\"dev\"]..."
    echo -e "help                              :print this help info"
    echo -e "start                             :start application"
    echo -e "stop                              :stop application"
    echo -e "restart                           :restart application"
    echo -e "status                            :application status"
    echo -e "show-start-log                    :application start log"
    echo -e "show-stop-log                     :application stop log"
    echo -e "show-start-error-log              :application start error log"
    echo -e "   -arg:[--jdk]                   :jdk file path,default: "`default_jdk_file_path`   
    echo -e "   -arg:[--active]                :spring boot active profiles, default: "`default_active_profiles`  
    echo -e "   -arg:[--active=\"no\"]           :spring boot start for no active profiles"   
    echo -e "   -arg:[--pid]                   :application pid file path, default: "`default_pid_file_path`   
    echo -e "   -arg:[--vm]                    :java vm options, default: "`default_vm_options`   
    echo -e "   -arg:[--jar]                   :application jar file path, default: "`default_jar_file_path`
    echo -e "sysvinit-create                   :create sysvinit script for application fast start, run this script user must have sudo permission!"
    echo -e "sysvinit-update                   :update sysvinit script for application fast start, run this script user must have sudo permission!"
    echo -e "sysvinit-delete                   :delete sysvinit script for application fast start, run this script user must have sudo permission!"
    echo -e "sysvinit-show                     :show sysvinit service name"
    echo -e "   -arg:[--sysvinit-name]         :sysvinit service name, default: "`default_jar_file_path`.`default_active_profiles`
    echo -e "   -arg:[--sysvinit-run-level]    :sysvinit script chkconfig run level, default: 345 70 30"
    echo -e "   -arg:[--sysvinit-run-user]     :sysvinit script application run user, default: www-data"
    echo -e "systemdinit-create                :create systemdinit script for application fast start, run this script user must have sudo permission!"
    echo -e "systemdinit-update                :update systemdinit script for application fast start, run this script user must have sudo permission!"
    echo -e "systemdinit-delete                :delete systemdinit script for application fast start, run this script user must have sudo permission!"
    echo -e "systemdinit-show                  :show systemdinit service name"
    echo -e "   -arg:[--systemdinit-name]      :systemdinit service name, default: "`default_jar_file_path`.`default_active_profiles`
    echo -e "   -arg:[--systemdinit-run-user]  :systemdinit script application run user, default: www-data"
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
    --sysvinit-name)
           SYSVINIT_NAME=$2
           shift 2
           ;;
    --sysvinit-name=?*)
           SYSVINIT_NAME=${1#--sysvinit-name=}
           shift
           ;;
    --sysvinit-run-level)
           SYSVINIT_RUN_LEVEL=$2
           shift 2
           ;;
    --sysvinit-run-level=?*)
           SYSVINIT_RUN_LEVEL=${1#--sysvinit-run-level=}
           shift
           ;;
    --sysvinit-run-user)
           SYSVINIT_RUN_USER=$2
           shift 2
           ;;
    --sysvinit-run-user=?*)
           SYSVINIT_RUN_USER=${1#--sysvinit-run-user=}
           shift
           ;;
    --systemdinit-name)
           SYSTEMDINIT_NAME=$2
           shift 2
           ;;
    --systemdinit-name=?*)
           SYSTEMDINIT_NAME=${1#--systemdinit-name=}
           shift
           ;;
    --systemdinit-run-user)
           SYSTEMDINIT_RUN_USER=$2
           shift 2
           ;;
    --systemdinit-run-user=?*)
           SYSTEMDINIT_RUN_USER=${1#--systemdinit-run-user=}
           shift
           ;;
    *)     help_info
           return 1;;
  esac
done

case ${action} in
'start')
    start | tee -a logs_run_sh/run.sh.start.log
    ;;
'stop')
    stop | tee -a logs_run_sh/run.sh.stop.log
    ;;
'restart')
    stop | tee -a logs_run_sh/run.sh.restart.log
    start | tee -a logs_run_sh/run.sh.restart.log
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
'sysvinit-create')
    create_sysvinit | tee -a logs_run_sh/run.sh.sysvinit.log
    ;;
'sysvinit-update')
    delete_sysvinit | tee -a logs_run_sh/run.sh.sysvinit.log
    create_sysvinit | tee -a logs_run_sh/run.sh.sysvinit.log
    ;;
'sysvinit-delete')
    delete_sysvinit | tee -a logs_run_sh/run.sh.sysvinit.log
    ;;
'sysvinit-show')
    show_sysvinit
    ;;
'systemdinit-create')
    create_systemdinit | tee -a logs_run_sh/run.sh.systemdinit.log
    ;;
'systemdinit-update')
    delete_systemdinit | tee -a logs_run_sh/run.sh.systemdinit.log
    create_systemdinit | tee -a logs_run_sh/run.sh.systemdinit.log
    ;;
'systemdinit-delete')
    delete_systemdinit | tee -a logs_run_sh/run.sh.systemdinit.log
    ;;
'systemdinit-show')
    show_systemdinit
    ;;
*|help)
    help_info
    ;;
esac
