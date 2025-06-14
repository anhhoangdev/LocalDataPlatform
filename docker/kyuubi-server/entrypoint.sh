#!/bin/bash
set -e

echo "🚀 Starting Kyuubi Server..."

# Set default values if not provided
export KYUUBI_HOME=${KYUUBI_HOME:-/opt/kyuubi}
export SPARK_HOME=${SPARK_HOME:-/opt/spark}
export JAVA_HOME=${JAVA_HOME:-/usr/lib/jvm/java-8-openjdk-amd64}

# Create kyuubi-defaults.conf from environment variables
cat > ${KYUUBI_HOME}/conf/kyuubi-defaults.conf << EOF
# Kyuubi Configuration
kyuubi.engine.share.level=${KYUUBI_ENGINE_SHARE_LEVEL:-USER}
kyuubi.session.engine.idle.timeout=${KYUUBI_SESSION_ENGINE_IDLE_TIMEOUT:-PT30S}
kyuubi.engine.user.isolated.spark.session.idle.timeout=${KYUUBI_ENGINE_USER_ISOLATED_SPARK_SESSION_IDLE_TIMEOUT:-PT10M}
kyuubi.ha.enabled=${KYUUBI_HA_ENABLED:-false}

# Frontend bind addresses (for port forwarding)
kyuubi.frontend.thrift.binary.bind.host=0.0.0.0
kyuubi.frontend.rest.bind.host=0.0.0.0

# Spark Configuration
spark.kubernetes.container.image=${SPARK_KUBERNETES_CONTAINER_IMAGE:-spark-engine-iceberg:3.5.0-1.4.2}
spark.kubernetes.authenticate.driver.serviceAccountName=${SPARK_KUBERNETES_AUTHENTICATE_DRIVER_SERVICEACCOUNTNAME:-kyuubi-sa}
spark.kubernetes.file.upload.path=/tmp
spark.kubernetes.namespace=kyuubi

# CRITICAL: Iceberg SQL Extensions (this enables Iceberg data source)
spark.sql.extensions=org.apache.iceberg.spark.extensions.IcebergSparkSessionExtensions
spark.sql.catalog.spark_catalog=org.apache.iceberg.spark.SparkCatalog
spark.sql.catalog.spark_catalog.type=hive
spark.sql.catalog.spark_catalog.uri=thrift://hive-metastore:9083
spark.sql.catalog.spark_catalog.warehouse=s3a://warehouse/
spark.sql.catalog.iceberg=org.apache.iceberg.spark.SparkCatalog
spark.sql.catalog.iceberg.type=hive
spark.sql.catalog.iceberg.uri=thrift://hive-metastore:9083
spark.sql.catalog.iceberg.warehouse=s3a://warehouse/

# S3/MinIO Configuration for Hadoop/Spark
spark.hadoop.fs.s3a.endpoint=http://minio:9000
spark.hadoop.fs.s3a.access.key=${MINIO_ACCESS_KEY:-minioadmin}
spark.hadoop.fs.s3a.secret.key=${MINIO_SECRET_KEY:-minioadmin}
spark.hadoop.fs.s3a.path.style.access=true
spark.hadoop.fs.s3a.impl=org.apache.hadoop.fs.s3a.S3AFileSystem
spark.hadoop.fs.s3a.connection.ssl.enabled=false
spark.hadoop.fs.s3a.attempts.maximum=3
spark.hadoop.fs.s3a.connection.establish.timeout=5000
spark.hadoop.fs.s3a.connection.timeout=10000

spark.executor.memory=${SPARK_EXECUTOR_MEMORY:-4g}
spark.executor.cores=${SPARK_EXECUTOR_CORES:-2}
spark.driver.memory=${SPARK_DRIVER_MEMORY:-2g}
spark.driver.memoryOverhead=${SPARK_DRIVER_MEMORY_OVERHEAD:-1g}
spark.submit.deployMode=${SPARK_SUBMIT_DEPLOYMODE:-cluster}
spark.eventLog.dir=${SPARK_EVENTLOG_DIR:-/tmp/spark-events}
spark.hive.metastore.uris=${SPARK_HIVE_METASTORE_URIS:-thrift://hive-metastore:9083}

# Fix Ivy repository path issue
spark.jars.ivy=/tmp/.ivy2
spark.kubernetes.driver.env.SPARK_USER=spark
spark.kubernetes.executor.env.SPARK_USER=spark

# Tell Kyuubi to use the local JAR file that's already in the Spark image
kyuubi.session.engine.spark.main.resource=local:///opt/kyuubi/externals/engines/spark/kyuubi-spark-sql-engine.jar

# Dynamic Allocation (if enabled)
EOF

if [ "${SPARK_DYNAMICALLOCATION_ENABLED}" = "true" ]; then
cat >> ${KYUUBI_HOME}/conf/kyuubi-defaults.conf << EOF
spark.dynamicAllocation.enabled=true
spark.dynamicAllocation.maxExecutors=${SPARK_DYNAMICALLOCATION_MAXEXECUTORS:-9}
spark.dynamicAllocation.minExecutors=${SPARK_DYNAMICALLOCATION_MINEXECUTORS:-0}
spark.dynamicAllocation.executorIdleTimeout=${SPARK_DYNAMICALLOCATION_EXECUTORIDLETIMEOUT:-60s}
spark.dynamicAllocation.cachedExecutorIdleTimeout=${SPARK_DYNAMICALLOCATION_CACHEDEXECUTORIDLETIMEOUT:-1800s}
EOF
fi

echo "📄 Kyuubi configuration:"
cat ${KYUUBI_HOME}/conf/kyuubi-defaults.conf

# Start Kyuubi server in foreground mode
exec ${KYUUBI_HOME}/bin/kyuubi run --conf spark.master=k8s://https://kubernetes.default.svc:443 