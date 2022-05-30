#!/bin/bash

source $BK_HOME/ci/scripts/bkenv.properties

MS_NAME=assembly
cd $BK_HOME/ci/$MS_NAME/

tee start.env <<EOF
MEM_OPTS="-Xms512m -Xmx2048m"
DEVOPS_GATEWAY=bk-ci.service.consul
SPRING_CONFIG_LOCATION=file://$BK_HOME/ci/$MS_NAME/application.yml,file://$BK_HOME/etc/ci/common.yml,file://$BK_HOME/etc/ci/application-$MS_NAME.yml
MS_USER=blueking
DISCOVERY_TAG=devops
API_PORT=$BK_CI_ASSEMBLY_API_PORT
EOF

#java -server -Dfatjar=/$MS_NAME/boot-$MS_NAME.jar -Ddevops_gateway=bk-ci.service.consul -Dserver.port=$API_PORT -Dbksvc=bk-ci-$MS_NAME "$MAIN_CLASS"

ci_ms_log="$BK_CI_LOGS_DIR/$MS_NAME"
ci_ms_data="$BK_CI_DATA_DIR/$MS_NAME"
mkdir -p "$ci_ms_log" "$ci_ms_data"
chown blueking:blueking -R "$ci_ms_log" "$ci_ms_data"
ln -srfT "$ci_ms_log" logs
ln -srfT "$ci_ms_data" data

echo "source env files..."
source ./service.env
source ./start.env

java_env=() java_argv=() java_run="" JAVA_OPTS=${JAVA_OPTS:-}
java_env+=("CLASSPATH=$CLASSPATH")
java_argv+=("-Dfatjar=/$MS_NAME/boot-$MS_NAME.jar")  # 兼容fatjar文件名匹配进程.
java_run="$MAIN_CLASS"
for k in LANG USER HOME SHELL LOGNAME PATH HOSTNAME LD_LIBRARY_PATH ${!JAVA_*} ${!SPRING_*}; do
  if [ -n "${!k-}" ]; then java_env+=("$k=${!k}"); fi  # 如果定义, 则传递.
done
java_argv+=(
  "-Ddevops_gateway=$DEVOPS_GATEWAY"
  "-Dserver.port=$API_PORT"  # 强制覆盖配置文件里的端口.
  "-Dbksvc=bk-ci-$MS_NAME"
)
# 指定环境变量及参数, 启动PATH里的java.
echo "run java"
sed -i 's/service_name = ""/service_name = "bk-ci"/' $BK_HOME/ci/gateway/core/lua/init.lua
grep service_name "$BK_HOME/ci/gateway/core/lua/init.lua"

echo "runuser -u blueking -g blueking -- env -i "${java_env[@]}" java -server "${java_argv[@]}" $MEM_OPTS $JAVA_OPTS $java_run &>./logs/bootstrap.log &"

runuser -u root -g root -- env -i "${java_env[@]}" java -server "${java_argv[@]}" \
$MEM_OPTS $JAVA_OPTS $java_run &>./logs/bootstrap.log &

ln -srfT logs/bk-ci-${BK_CI_CONSUL_DISCOVERY_TAG:-devops}.log logs/assembly.log