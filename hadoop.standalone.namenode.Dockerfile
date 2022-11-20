FROM ubuntu
LABEL MAINTAINER="emmanguekam  <emmanguekam@gmail.com>"

RUN apt-get update -y
RUN apt-get install -y apt-utils
RUN apt-get install -y openjdk-8-jdk
RUN apt-get install -y wget
RUN apt-get install -y openssh-server
RUN apt-get install -y net-tools
RUN apt-get install -y vim

RUN  ssh-keygen -t rsa -P '' -f ~/.ssh/id_rsa && \
     cat ~/.ssh/id_rsa.pub >> ~/.ssh/authorized_keys && \
     chmod 0600 ~/.ssh/authorized_keys

WORKDIR /root
COPY ./data/hadoop/hadoop-3.3.4.tar.gz .
RUN tar -xzvf hadoop-3.3.4.tar.gz && \
    mv hadoop-3.3.4 /usr/local/hadoop && \
    rm hadoop-3.3.4.tar.gz

ENV JAVA_HOME=/usr/lib/jvm/java-8-openjdk-amd64
ENV HADOOP_HOME=/usr/local/hadoop
ENV PATH=$PATH:/usr/local/hadoop/bin:/usr/local/hadoop/sbin

COPY config/hadoop/hdfs-users.txt .
COPY config/hadoop/yarn-users.txt .
RUN echo "ToFix ERRORs & WARNs" && \
    \
    #ToFix ERROR: sd
    sed -i '1r ./hdfs-users.txt' $HADOOP_HOME/sbin/start-dfs.sh && \
    sed -i '1r ./hdfs-users.txt' $HADOOP_HOME/sbin/stop-dfs.sh && \
    sed -i '1r ./yarn-users.txt' $HADOOP_HOME/sbin/start-yarn.sh && \
    sed -i '1r ./yarn-users.txt' $HADOOP_HOME/sbin/stop-yarn.sh && \
    rm -f ~/*-users.txt && \
    \
    # tofix ERROR:
    sed -i -E '/JAVA_HOME+/a JAVA_HOME=/usr/lib/jvm/java-8-openjdk-amd64' $HADOOP_HOME/etc/hadoop/hadoop-env.sh && \
    \
    # tofix ERROR: Cannot set priority of datanode process  \
    # https://blog.titanwolf.in/a?ID=01000-5b05054c-3e55-4d7e-81ff-d4d67ea5ed9b)
    sed -i -E '/HADOOP_SHELL_EXECNAME+/a HADOOP_SHELL_EXECNAME="root"' $HADOOP_HOME/bin/hdfs && \
    \
    #tofix WARN util.NativeCodeLoader: Unable to load native-hadoop library for your platform... using builtin-java classes where applicable
    sed -i -E '/export HADOOP_OPTS+/a export HADOOP_OPTS="\$HADOOP_OPTS -Djava.net.preferIPv4Stack=true -Djava.security.krb5.realm= -Djava.security.krb5.kdc="' $HADOOP_HOME/etc/hadoop/hadoop-env.sh

COPY config/hadoop/ssh_config .ssh/config
COPY config/hadoop/start-hadoop.sh start-hadoop.sh

RUN chmod +x $HADOOP_HOME/etc/hadoop/*.sh && \
    chmod +x ~/start-hadoop.sh