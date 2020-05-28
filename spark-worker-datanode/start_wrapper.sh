#!/bin/bash

# Start the first process
mkdir -p $HADOOP_LOG

datadir=`echo $HDFS_CONF_dfs_datanode_data_dir | perl -pe 's#file://##'`
if [ ! -d $datadir ]; then
  echo "Datanode data directory not found: $datadir"
  exit 2
fi
#>> $HADOOP_LOG/datanode.out
$HADOOP_PREFIX/bin/hdfs --config $HADOOP_CONF_DIR datanode &
status=$?
if [ $status -ne 0 ]; then
  echo "Failed to start datanode: $status"
  exit $status
fi

# Start the second process
. "/spark/sbin/spark-config.sh"
. "/spark/bin/load-spark-env.sh"

mkdir -p $SPARK_WORKER_LOG
export SPARK_HOME=/spark

ln -sf /dev/stdout $SPARK_WORKER_LOG/spark-worker.out

/spark/sbin/../bin/spark-class org.apache.spark.deploy.worker.Worker \
    --webui-port $SPARK_WORKER_WEBUI_PORT $SPARK_MASTER >> $SPARK_WORKER_LOG/spark-worker.out &
#./my_second_process -D
status=$?
if [ $status -ne 0 ]; then
  echo "Failed to start spark-worker: $status"
  exit $status
fi

# Naive check runs checks once a minute to see if either of the processes exited.
# This illustrates part of the heavy lifting you need to do if you want to run
# more than one service in a container. The container exits with an error
# if it detects that either of the processes has exited.
# Otherwise it loops forever, waking up every 60 seconds

while sleep 60; do
  ps aux |grep datanode |grep -q -v grep
  PROCESS_1_STATUS=$?
  ps aux |grep spark |grep -q -v grep
  PROCESS_2_STATUS=$?
  # If the greps above find anything, they exit with 0 status
  # If they are not both 0, then something is wrong
  if [ $PROCESS_1_STATUS -ne 0 ]; then
    echo "Datanode has already exited."
    exit 1
  fi
  if [ $PROCESS_2_STATUS -ne 0 ]; then
    echo "Spark worker has already exited."
    exit 1
  fi
done

