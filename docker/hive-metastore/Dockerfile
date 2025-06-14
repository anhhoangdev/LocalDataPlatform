FROM apache/hive:3.1.3

ARG HADOOP_VERSION=3.3.4

ENV HIVE_HOME=/opt/hive \
    SERVICE_NAME=hive-metastore \
    HIVE_METASTORE_PORT=9083 \
    HADOOP_VERSION=${HADOOP_VERSION}

USER root

# 📥 Install curl, wget, default-mysql-client, and gettext-base (for envsubst)
RUN apt-get update && apt-get install -y \
    curl \
    wget \
    default-mysql-client \
    gettext-base

# 📥 Download specific Hadoop JARs to fix NoSuchMethodError and missing classes
RUN rm -f /opt/hive/lib/hadoop-*.jar && \
    # Core Hadoop JARs
    curl -L https://repo1.maven.org/maven2/org/apache/hadoop/hadoop-common/${HADOOP_VERSION}/hadoop-common-${HADOOP_VERSION}.jar -o /opt/hive/lib/hadoop-common-${HADOOP_VERSION}.jar && \
    curl -L https://repo1.maven.org/maven2/org/apache/hadoop/hadoop-hdfs-client/${HADOOP_VERSION}/hadoop-hdfs-client-${HADOOP_VERSION}.jar -o /opt/hive/lib/hadoop-hdfs-client-${HADOOP_VERSION}.jar && \
    curl -L https://repo1.maven.org/maven2/org/apache/hadoop/hadoop-hdfs/${HADOOP_VERSION}/hadoop-hdfs-${HADOOP_VERSION}.jar -o /opt/hive/lib/hadoop-hdfs-${HADOOP_VERSION}.jar && \
    curl -L https://repo1.maven.org/maven2/org/apache/hadoop/hadoop-auth/${HADOOP_VERSION}/hadoop-auth-${HADOOP_VERSION}.jar -o /opt/hive/lib/hadoop-auth-${HADOOP_VERSION}.jar
    
# 📥 Download the correct hadoop-shaded-guava from hadoop-thirdparty
RUN curl -L https://repo1.maven.org/maven2/org/apache/hadoop/thirdparty/hadoop-shaded-guava/1.3.0/hadoop-shaded-guava-1.3.0.jar \
-o /opt/hive/lib/hadoop-shaded-guava-1.3.0.jar

# 🧹 Remove SLF4J duplicate bindings to avoid logging conflicts
RUN rm -f /opt/hive/lib/slf4j-log4j12-*.jar && \
    rm -f /opt/hadoop/share/hadoop/common/lib/slf4j-log4j12-*.jar

# 📥 Download MySQL JDBC driver
RUN curl -L -A "Mozilla/5.0" https://repo1.maven.org/maven2/com/mysql/mysql-connector-j/8.0.33/mysql-connector-j-8.0.33.jar -o /opt/hive/lib/mysql-connector-j-8.0.33.jar

# 📥 Download S3A libraries for MinIO (compatible with Hadoop 3.3.4)
RUN curl -L https://repo1.maven.org/maven2/org/apache/hadoop/hadoop-aws/${HADOOP_VERSION}/hadoop-aws-${HADOOP_VERSION}.jar -o /opt/hive/lib/hadoop-aws-${HADOOP_VERSION}.jar && \
    curl -L https://repo1.maven.org/maven2/com/amazonaws/aws-java-sdk-bundle/1.12.262/aws-java-sdk-bundle-1.12.262.jar -o /opt/hive/lib/aws-java-sdk-bundle-1.12.262.jar

# 📄 Copy Hive configuration and entrypoint script
COPY configs/hive-site.xml ${HIVE_HOME}/conf/hive-site.xml.template
COPY entrypoint.sh /opt/entrypoint.sh

RUN chmod +x /opt/entrypoint.sh

EXPOSE 9083

ENTRYPOINT ["/opt/entrypoint.sh"]
