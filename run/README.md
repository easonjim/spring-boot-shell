# spring boot run shell
fast run spring boot application  
### tips
1. don't use root run this script.
2. recommond to use have sudo permission user run this script.
3. sysvinit and systemdint use for when system startup and auto start application, not neccessary!
4. so, without sysvinit and systemdinit, normal user can run this script.
## use help
```shell
Usage: bash ./run.sh [start|stop|restart|status|help|...] [--active="dev"]...
help                              :print this help info
start                             :start application
stop                              :stop application
restart                           :restart application
status                            :application status
show-start-log                    :application start log
show-stop-log                     :application stop log
show-start-error-log              :application start error log
   -arg:[--jdk]                   :jdk file path,default: /data/service/java/bin
   -arg:[--active]                :spring boot active profiles, default: dev
   -arg:[--active="no"]           :spring boot start for no active profiles
   -arg:[--pid]                   :application pid file path, default: test.jar.pid
   -arg:[--vm]                    :java vm options, default:  -server -Xmx1g -Xms1g -Xmn512m -XX:PermSize=128m -Xss256k -XX:+DisableExplicitGC -XX:+UseConcMarkSweepGC -XX:+CMSParallelRemarkEnabled -XX:+UseCMSCompactAtFullCollection -XX:LargePageSizeInBytes=128m -XX:+UseFastAccessorMethods -XX:+UseCMSInitiatingOccupancyOnly -XX:CMSInitiatingOccupancyFraction=70
   -arg:[--jar]                   :application jar file path, default: test.jar
sysvinit-create                   :create sysvinit script for application fast start, run this script user must have sudo permission!
sysvinit-update                   :update sysvinit script for application fast start, run this script user must have sudo permission!
sysvinit-delete                   :delete sysvinit script for application fast start, run this script user must have sudo permission!
sysvinit-show                     :show sysvinit service name
   -arg:[--sysvinit-name]         :sysvinit service name, default: test.jar.dev
   -arg:[--sysvinit-run-level]    :sysvinit script chkconfig run level, default: 345 70 30
   -arg:[--sysvinit-run-user]     :sysvinit script application run user, default: www-data
systemdinit-create                :create systemdinit script for application fast start, run this script user must have sudo permission!
systemdinit-update                :update systemdinit script for application fast start, run this script user must have sudo permission!
systemdinit-delete                :delete systemdinit script for application fast start, run this script user must have sudo permission!
systemdinit-show                  :show systemdinit service name
   -arg:[--systemdinit-name]      :systemdinit service name, default: test.jar.dev
   -arg:[--systemdinit-run-user]  :systemdinit script application run user, default: www-data
```
#### the jvm default args, so you can use command args --vm="" set this to change default
```shell
-server \
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
-XX:CMSInitiatingOccupancyFraction=70 
```
#### the jdk default path
```shell
/data/service/java/bin/
```
## start application
```shell
bash ./run.sh start --active="test"
```
## stop application
```shell
bash ./run.sh stop --active="test"
```
## set devault env to run spring boot without active arg
```shell
cat > /etc/profile.d/spring-boot-active-env.sh <<EOF
export SPRING_BOOT_ACTIVE_ENV=dev
EOF
source /etc/profile
```
and use bash ./run.sh start application,the active is ${SPRING_BOOT_ACTIVE_ENV}.
## (SysV) register sysvinit script in system when system startup after auto start this application
tips: register this script user must have sudo permission! The system first time startup use root run this service, but run user is your setting like this www-data. So, if use www-data user run this service you must use sudo!
```shell
# run this script use is www-data
# create 
bash ./run.sh sysvinit-create --active="test" --sysvinit-run-user="www-data"
# chkconfig service, like this demo then service is: application.jar.test
chkconfig --list application.jar.test
# start 
sudo service application.jar.test start 
# status
sudo service application.jar.test status
# stop
sudo service stop application.jar.test
# restart
sudo service restart application.jar.test
```
## (Systemd) register systemd script in system when system startup after auto start this application
tips: register this script user must have sudo permission! The system first time startup use root run this service, but run user is your setting like this www-data. So, if use www-data user run this service you must use sudo!
```shell
# run this script use is www-data
# create 
bash ./run.sh systemdinit-create --active="test" --systemdinit-run-user="www-data"
# systemctl service, like this demo then service is: application.jar.test
systemctl list-unit-files | grep application.jar.test
# start 
sudo systemctl start application.jar.test
# status
sudo systemctl status application.jar.test
# stop
sudo systemctl stop application.jar.test
# restart
sudo systemctl restart application.jar.test
```