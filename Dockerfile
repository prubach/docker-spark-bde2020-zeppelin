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
      && apt install -y tzdata wget curl bash openjdk-8-jdk python2 python3 python3-dev python3-pip python3-setuptools python-setuptools python-pip-whl python-dev libnss3 \
      && ln -s /lib64/ld-linux-x86-64.so.2 /lib/ld-linux-x86-64.so.2 \
      && curl https://bootstrap.pypa.io/pip/2.7/get-pip.py --output get-pip.py \
      && python2 get-pip.py \
      && chmod +x *.sh \
      && wget https://archive.apache.org/dist/spark/spark-${SPARK_VERSION}/spark-${SPARK_VERSION}-bin-hadoop${HADOOP_VERSION}.tgz \
      && tar -xvzf spark-${SPARK_VERSION}-bin-hadoop${HADOOP_VERSION}.tgz \
      && mv spark-${SPARK_VERSION}-bin-hadoop${HADOOP_VERSION} spark \
      && rm spark-${SPARK_VERSION}-bin-hadoop${HADOOP_VERSION}.tgz \
      #&& cd /css \
      #&& jar uf /spark/jars/spark-core_2.11-${SPARK_VERSION}.jar org/apache/spark/ui/static/timeline-view.css \
      && cd /

RUN dpkg-reconfigure --frontend noninteractive tzdata
#Give permission to execute scripts
RUN chmod +x /wait-for-step.sh && chmod +x /execute-step.sh && chmod +x /finish-step.sh

# Fix the value of PYTHONHASHSEED
# Note: this is needed when you use Python 3.3 or greater
ENV PYTHONHASHSEED 1

#from spark-worker
ENV SPARK_WORKER_WEBUI_PORT 8081
ENV SPARK_WORKER_LOG /spark/logs
COPY spark-worker/worker.sh /

#### ---- Host Arguments variables----
ARG APACHE_SPARK_VERSION=3.1.1
ARG APACHE_HADOOP_VERSION=3.2.2
ARG SPARK_MASTER="spark://spark-master:7077" 
#ARG ZEPPELIN_DOWNLOAD_URL=http://apache.cs.utah.edu/zeppelin
ARG ZEPPELIN_DOWNLOAD_URL=http://www-us.apache.org/dist/zeppelin
ARG ZEPPELIN_INSTALL_DIR=/usr/lib 
ARG ZEPPELIN_HOME=${ZEPPELIN_INSTALL_DIR}/zeppelin 
ARG ZEPPELIN_VERSION=${ZEPPELIN_VERSION:-0.9.0}
ARG ZEPPELIN_PKG_NAME=zeppelin-${ZEPPELIN_VERSION}-bin-all 
ARG ZEPPELIN_PORT=8080 

#### ---- Host Environment variables ----
ENV APACHE_SPARK_VERSION=${APACHE_SPARK_VERSION} 
ENV APACHE_HADOOP_VERSION=${APACHE_HADOOP_VERSION} 
ENV SPARK_MASTER=${SPARK_MASTER} 
ENV ZEPPELIN_HOME=${ZEPPELIN_HOME} 
ENV ZEPPELIN_CONF_DIR=${ZEPPELIN_HOME}/conf 
ENV ZEPPELIN_DATA_DIR=${ZEPPELIN_HOME}/data 
ENV ZEPPELIN_NOTEBOOK_DIR=${ZEPPELIN_HOME}/notebook 
ENV ZEPPELIN_DOWNLOAD_URL=${ZEPPELIN_DOWNLOAD_URL}
ENV ZEPPELIN_INSTALL_DIR=${ZEPPELIN_INSTALL_DIR}
ENV ZEPPELIN_VERSION=${ZEPPELIN_VERSION} 
ENV ZEPPELIN_PKG_NAME=zeppelin-${ZEPPELIN_VERSION}-bin-all 
ENV ZEPPELIN_PORT=${ZEPPELIN_PORT} 
ENV SPARK_HOME=/spark

# omit tzdata asking for timezone
#ENV DEBIAN_FRONTEND=noninteractive
#RUN ln -fs /usr/share/zoneinfo/America/New_York /etc/localtime
#### ---- Python 3 ----
COPY requirements.txt ./
RUN apt install -y iputils-ping net-tools build-essential wget vim python-matplotlib-data python-arrow-doc python-numpy python3-numpy python3-scipy python3-matplotlib python3-arrow
RUN pip install -r requirements.txt \
  && pip install pandas_datareader scikit-learn \
  && pip3 install -r requirements.txt \
  && pip3 install pandas_datareader scikit-learn \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/*

  
RUN dpkg-reconfigure --frontend noninteractive tzdata
#alpine && apk add --no-cache wget build-base git unzip freetype-dev libpng-dev openblas-dev vim python2-dev python3-dev py3-numpy py3-scipy \
# matplotlib 
# && pip3 install pandas matplotlib \
#  && apt install -y openjdk-8-jdk curl net-tools build-essential git wget unzip vim python3-pip python3-setuptools python3-dev python3-numpy python3-scipy python3-pandas python3-matplotlib \

#    && apk add -y curl net-tools gcc make git wget unzip vim python3-pip python3-setuptools python3-dev python3-numpy python3-scipy python3-pandas python3-matplotlib \
#RUN apk add --no-cache curl bash openjdk8-jre python3 py-pip nss libc6-compat \

#### ---- Zeppelin Installation -----
WORKDIR ${ZEPPELIN_INSTALL_DIR}

#### ---- (Interim mode) Zeppelin Installation (using local host tar file) ----
#COPY ${ZEPPELIN_PKG_NAME}.tgz /tmp/
#RUN tar -xvf /tmp/${ZEPPELIN_PKG_NAME}.tgz -C /usr/lib/ \
#    && chown -R root ${ZEPPELIN_PKG_NAME} \
#    && ln -s ${ZEPPELIN_PKG_NAME} zeppelin \ 
#    && mkdir -p ${ZEPPELIN_HOME}/logs && mkdir -p ${ZEPPELIN_HOME}/run \
#    && rm /tmp/${ZEPPELIN_PKG_NAME}.tgz

#### ---- For SparkR ----
## To-do: Later    
#RUN echo "deb http://cran.rstudio.com/bin/linux/ubuntu bionic-cran35/" | tee -a /etc/apt/sources.list
#RUN gpg --keyserver keyserver.ubuntu.com --recv-key E084DAB9
#RUN gpg -a --export E084DAB9 | apt-key add 
RUN apt-get update && apt-get install -y libc6 libjpeg8 r-base-core r-recommended r-base-html r-base r-base-dev 


#### ---- (Deployment mode use) Zeppelin Installation (Download from Internet -- Deployment) ----
RUN wget -c ${ZEPPELIN_DOWNLOAD_URL}/zeppelin-${ZEPPELIN_VERSION}/${ZEPPELIN_PKG_NAME}.tgz \
    && tar xvf ${ZEPPELIN_PKG_NAME}.tgz \
    && ln -s ${ZEPPELIN_PKG_NAME} zeppelin \
    && mkdir -p ${ZEPPELIN_HOME}/logs && mkdir -p ${ZEPPELIN_HOME}/run \
    && rm -f ${ZEPPELIN_PKG_NAME}.tgz

#### ---- default config is ok ----
#COPY conf/zeppelin-site.xml ${ZEPPELIN_HOME}/conf/zeppelin-site.xml
#COPY conf/zeppelin-env.sh ${ZEPPELIN_HOME}/conf/zeppelin-env.sh
COPY worker.sh /


## Now install R and littler, and create a link for littler in /usr/local/bin
#RUN echo "..... Installing R base ....." \
#    && echo "deb http://cran.rstudio.com/bin/linux/ubuntu xenial/" | tee -a /etc/apt/sources.list \
#    && gpg --keyserver keyserver.ubuntu.com --recv-key E084DAB9 \
#    && gpg -a --export E084DAB9 | apt-key add - \
#    && apt-get update -y \
#    && apt-get -y install build-essential libc6 libjpeg8 r-cran-mgcv r-base-core r-recommended r-base-html r-base r-base-dev 

## To-do: Later    
#ENV RSTUDIO_DEB_PKG=rstudio-xenial-1.1.383-amd64.deb
#RUN echo ".... Installing R-Studio ...." \    
#    && apt-get install gdebi-core \
#    && wget https://download1.rstudio.org/${RSTUDIO_DEB_PKG} \
#    && gdebi -n ${RSTUDIO_DEB_PKG} \
#    && rm ${RSTUDIO_DEB_PKG}

#### ---- Debug ----
RUN mkdir -p ${ZEPPELIN_HOME}/data \
    && ls -al /usr/lib/zeppelin/bin \
    && ls -al /usr/lib/zeppelin/notebook \
    && ls -al /usr/lib/zeppelin/bin/zeppelin-daemon.sh

VOLUME ${ZEPPELIN_HOME}/notebook
VOLUME ${ZEPPELIN_HOME}/conf
VOLUME ${ZEPPELIN_HOME}/data

EXPOSE ${ZEPPELIN_PORT}

#ENV SPARK_SUBMIT_OPTIONS "--jars /opt/zeppelin/sansa-examples-spark-2016-12.jar"

ENV ZEPPELIN_JAVA_OPTS=${ZEPPELIN_JAVA_OPTS:-"-Dspark.driver.memory=4g -Dspark.executor.memory=8g -Dspark.cores.max=8"}
ENV ZEPPELIN_MEM=${ZEPPELIN_MEM:-"-Xms8g -Xmx28g -XX:MaxPermSize=8g"}
ENV ZEPPELIN_INTP_MEM=${ZEPPELIN_INTP_MEM:-"-Xms4g -Xmx24g"}
#ENV ZEPPELIN_INTP_JAVA_OPTS=${ZEPPELIN_INTP_JAVA_OPTS}

WORKDIR ${ZEPPELIN_HOME}

#HEALTHCHECK NONE
HEALTHCHECK CMD curl --fail http://localhost:${ZEPPELIN_PORT}/ || exit 1

CMD ["/bin/bash","/usr/lib/zeppelin/bin/zeppelin.sh"]

