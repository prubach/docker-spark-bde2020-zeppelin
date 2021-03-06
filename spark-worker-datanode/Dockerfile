#FROM bde2020/spark-worker:2.4.5-hadoop2.7
#FROM bde2020/spark-worker:2.2.0-hadoop2.8-hive-java8
FROM ubuntu:focal

MAINTAINER Pawel Rubach <pawel.rubach@gmail.com>

# omit tzdata asking for timezone
ENV DEBIAN_FRONTEND=noninteractive
RUN ln -fs /usr/share/zoneinfo/America/New_York /etc/localtime
#from spark-base

ENV ENABLE_INIT_DAEMON true
ENV INIT_DAEMON_BASE_URI http://identifier/init-daemon
ENV INIT_DAEMON_STEP spark_master_init

ENV SPARK_VERSION=3.1.1
ENV HADOOP_VERSION=3.2

COPY spark-base/wait-for-step.sh /
COPY spark-base/execute-step.sh /
COPY spark-base/finish-step.sh /

RUN apt update -y \
      && apt install -y net-tools curl netcat wget curl bash openjdk-8-jdk python3 python3-pip python3-dev python3-setuptools python-setuptools python-pip-whl python-dev libnss3 \
      && ln -s /lib64/ld-linux-x86-64.so.2 /lib/ld-linux-x86-64.so.2 \
      && chmod +x *.sh \
      && wget https://archive.apache.org/dist/spark/spark-${SPARK_VERSION}/spark-${SPARK_VERSION}-bin-hadoop${HADOOP_VERSION}.tgz \
      && tar -xvzf spark-${SPARK_VERSION}-bin-hadoop${HADOOP_VERSION}.tgz \
      && mv spark-${SPARK_VERSION}-bin-hadoop${HADOOP_VERSION} spark \
      && rm spark-${SPARK_VERSION}-bin-hadoop${HADOOP_VERSION}.tgz \
      #&& cd /css \
      #&& jar uf /spark/jars/spark-core_2.11-${SPARK_VERSION}.jar org/apache/spark/ui/static/timeline-view.css \
      && cd /

#Give permission to execute scripts
RUN chmod +x /wait-for-step.sh && chmod +x /execute-step.sh && chmod +x /finish-step.sh

# Fix the value of PYTHONHASHSEED
# Note: this is needed when you use Python 3.3 or greater
ENV PYTHONHASHSEED 1

# from docker-hadoop/base

ENV JAVA_HOME=/usr/lib/jvm/java-8-openjdk-amd64/

#RUN gpg --keyserver pool.sks-keyservers.net --recv-keys \
#    07617D4968B34D8F13D56E20BE5AAA0BA210C095 \
#    2CAC83124870D88586166115220F69801F27E622 \
#    4B96409A098DBD511DF2BC18DBAF69BEA7239D59 \
#    9DD955653083EFED6171256408458C39E964B5FF \
#    B6B3F7EDA5BA7D1E827DE5180DFF492D8EE2F25C \
#    6A67379BEFC1AE4D5595770A34005598B8F47547 \
#    47660BC98BC433F01E5C90581209E7F13D0C92B9 \
#    CE83449FDC6DACF9D24174DCD1F99F6EE3CD2163 \
#    A11DF05DEA40DA19CE4B43C01214CF3F852ADB85 \
#    686E5EDF04A4830554160910DF0F5BBC30CD0996 \
#    5BAE7CB144D05AD1BB1C47C75C6CC6EFABE49180 \
#    AF7610D2E378B33AB026D7574FB955854318F669 \
#    6AE70A2A38F466A5D683F939255ADF56C36C5F0F \
#    70F7AB3B62257ABFBD0618D79FDB12767CC7352A \
#    842AAB2D0BC5415B4E19D429A342433A56D8D31A \
#    1B5D384B734F368052862EB55E43CAB9AEC77EAF \
#    785436A782586B71829C67A04169AA27ECB31663 \
#    5E49DA09E2EC9950733A4FF48F1895E97869A2FB \
#    A13B3869454536F1852C17D0477E02D33DD51430 \
#    A6220FFCC86FE81CE5AAC880E3814B59E4E11856 \
#    EFE2E7C571309FE00BEBA78D5E314EEF7340E1CB \
#    EB34498A9261F343F09F60E0A9510905F0B000F0 \
#    3442A6594268AC7B88F5C1D25104A731B021B57F \
#    6E83C32562C909D289E6C3D98B25B9B71EFF7770 \
#    E9216532BF11728C86A11E3132CF4BF4E72E74D3 \
#    E8966520DA24E9642E119A5F13971DA39475BD5D \
#    1D369094D4CFAC140E0EF05E992230B1EB8C6EFA \
#    A312CE6A1FA98892CB2C44EBA79AB712DE5868E6 \
#    0445B7BFC4515847C157ECD16BA72FF1C99785DE \
#    B74F188889D159F3D7E64A7F348C6D7A0DCED714 \
#    4A6AC5C675B6155682729C9E08D51A0A7501105C \
#    8B44A05C308955D191956559A5CEE20A90348D47
#
#RUN gpg --keyserver pool.sks-keyservers.net --recv-key C36C5F0F
#
ENV HADOOP_VERSION 3.2.2
ENV HADOOP_URL https://www.apache.org/dist/hadoop/common/hadoop-$HADOOP_VERSION/hadoop-$HADOOP_VERSION.tar.gz
RUN set -x \
    && curl -fSL "$HADOOP_URL" -o /tmp/hadoop.tar.gz \
    && curl -fSL "$HADOOP_URL.asc" -o /tmp/hadoop.tar.gz.asc \
#    && gpg --verify /tmp/hadoop.tar.gz.asc \
    && tar -xvf /tmp/hadoop.tar.gz -C /opt/ \
    && rm /tmp/hadoop.tar.gz*

RUN ln -s /opt/hadoop-$HADOOP_VERSION/etc/hadoop /etc/hadoop
#RUN cp /etc/hadoop/mapred-site.xml.template /etc/hadoop/mapred-site.xml
RUN mkdir /opt/hadoop-$HADOOP_VERSION/logs

RUN mkdir /hadoop-data

ENV HADOOP_PREFIX=/opt/hadoop-$HADOOP_VERSION
ENV HADOOP_CONF_DIR=/etc/hadoop
ENV MULTIHOMED_NETWORK=1

ENV USER=root
ENV PATH $HADOOP_PREFIX/bin/:$PATH

ADD entrypoint.sh /entrypoint.sh
RUN chmod a+x /entrypoint.sh

# from docker-hadoop/dotanode
HEALTHCHECK CMD curl -f http://localhost:9864/ || exit 1

ENV HDFS_CONF_dfs_datanode_data_dir=file:///hadoop/dfs/data
RUN mkdir -p /hadoop/dfs/data
VOLUME /hadoop/dfs/data

ADD datanode.sh /datanode.sh
RUN chmod a+x /datanode.sh

EXPOSE 9864

ENV HADOOP_LOG=/hadoop/logs

#from spark-worker
COPY spark-worker/worker.sh /

ENV SPARK_WORKER_WEBUI_PORT 8081
ENV SPARK_WORKER_LOG /spark/logs
ENV SPARK_MASTER "spark://spark-master:7077"

EXPOSE 8081

COPY start_wrapper.sh /
RUN chmod a+x /start_wrapper.sh

#CMD ["/datanode.sh"]
#ENTRYPOINT ["/entrypoint.sh"]

#CMD ["/bin/bash", "/worker.sh"]
CMD ["/entrypoint.sh", "/start_wrapper.sh"]
