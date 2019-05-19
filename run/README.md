# spring boot run shell
fast run spring boot application
## use help
```shell
Usage: bash ./run.sh [start|stop|restart|status|help|...] [--active="dev"]...
help                       :print this help info
start                      :start application
stop                       :stop application
restart                    :restart application
status                     :application status
show-start-log             :application start log
show-stop-log              :application stop log
show-start-error-log       :application start error log
   -arg:[--jdk]            :jdk file path,default:/data/service/jdk/bin
   -arg:[--active]         :spring boot active profiles,default:dev
   -arg:[--active="no"]    :spring boot start for no active profiles
   -arg:[--pid]            :application pid file path,default:application.pid
   -arg:[--vm]             :java vm options,default: -server -Xmx1g -Xms1g -Xmn512m -XX:PermSize=128m -Xss256k -XX:+DisableExplicitGC -XX:+UseConcMarkSweepGC -XX:+CMSParallelRemarkEnabled -XX:+UseCMSCompactAtFullCollection -XX:LargePageSizeInBytes=128m -XX:+UseFastAccessorMethods -XX:+UseCMSInitiatingOccupancyOnly -XX:CMSInitiatingOccupancyFraction=70
   -arg:[--jar]            :application jar file path,default: the dir first jar file!
```
## start application
```shell
bash ./run.sh start
```
## stop application
```shell
bash ./run.sh stop
```
