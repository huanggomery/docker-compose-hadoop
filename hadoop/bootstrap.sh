#!/usr/bin/env sh
# 文件是在容器中执行的脚本
# 在镜像中已经包含
# 请勿在宿主机中运行

wait_for() {
    echo Waiting for $1 to listen on $2...
    while ! nc -z $1 $2; do echo waiting...; sleep 1s; done
}

start_hdfs_namenode() {
    if [ ! -f /tmp/namenode-formatted ]; then
        ${HADOOP_HOME}/bin/hdfs namenode -format > /tmp/namenode-formatted
    fi

    ${HADOOP_HOME}/bin/hdfs --loglevel INFO --daemon start namenode
}

start_hdfs_datanode() {
    wait_for $1 $2

    ${HADOOP_HOME}/bin/hdfs --loglevel INFO --daemon start datanode
}

start_yarn_resourcemanager() {
    ${HADOOP_HOME}/bin/yarn --loglevel INFO --daemon start resourcemanager

    ${HADOOP_HOME}/bin/mapred --loglevel INFO  --daemon  start historyserver
}

start_yarn_nodemanager() {
    wait_for $1 $2

    ${HADOOP_HOME}/bin/yarn --loglevel INFO --daemon start nodemanager
}

case $1 in
    hadoop-master)
        start_hdfs_namenode
        start_yarn_resourcemanager
        tail -f ${HADOOP_HOME}/logs/*namenode*.log
        ;;
    hadoop-slave)
        start_hdfs_datanode $2 $3
        start_yarn_nodemanager $2 $3
        tail -f ${HADOOP_HOME}/logs/*datanode*.log
        ;;
    *)
        echo "Input Error!"
    ;;
esac
