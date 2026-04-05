#!/usr/bin/env bash
set -euo pipefail

source ~/.bashrc || true

PROJECT_DIR="/mnt/c/Users/vinay/OneDrive/Desktop/ubuntu/hadoop/Exp8_Hive"
HIVE_HOME="/home/vinayak/hive"
HIVE_VERSION="3.1.3"
HIVE_ARCHIVE="apache-hive-${HIVE_VERSION}-bin.tar.gz"
HIVE_URL="https://archive.apache.org/dist/hive/hive-${HIVE_VERSION}/${HIVE_ARCHIVE}"
HIVE_TMP_DIR="/home/vinayak/apache-hive-${HIVE_VERSION}-bin"
HADOOP_HOME="/home/vinayak/hadoop"
HADOOP_CONF_DIR="$PROJECT_DIR/hadoop_conf"

cd "$PROJECT_DIR"
mkdir -p verification conf warehouse logs
rm -f verification/hive_version.txt verification/hive_run_output.txt verification/schema_init.txt

if [ ! -x "$HIVE_HOME/bin/hive" ]; then
  echo "Hive not found. Installing Hive ${HIVE_VERSION}..."
  cd /home/vinayak
  rm -rf "$HIVE_TMP_DIR"
  rm -f "$HIVE_ARCHIVE"
  wget -q "$HIVE_URL"
  tar -xzf "$HIVE_ARCHIVE"
  rm -rf "$HIVE_HOME"
  mv "$HIVE_TMP_DIR" "$HIVE_HOME"
  rm -f "$HIVE_ARCHIVE"
fi

cd "$PROJECT_DIR"

export HIVE_HOME
export JAVA_HOME="/usr/lib/jvm/java-8-openjdk-amd64"
export HADOOP_HOME
export PATH="$JAVA_HOME/bin:$HIVE_HOME/bin:$HADOOP_HOME/bin:$PATH"
export HIVE_CONF_DIR="$PROJECT_DIR/conf"
export HADOOP_CONF_DIR
unset HIVE_AUX_JARS_PATH

mkdir -p "$HADOOP_CONF_DIR"

cat > "$HADOOP_CONF_DIR/hadoop-env.sh" <<EOF
export JAVA_HOME=${JAVA_HOME}
EOF

cat > "$HADOOP_CONF_DIR/core-site.xml" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<configuration>
  <property>
    <name>fs.defaultFS</name>
    <value>file:///</value>
  </property>
</configuration>
EOF

cat > "$HADOOP_CONF_DIR/mapred-site.xml" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<configuration>
  <property>
    <name>mapreduce.framework.name</name>
    <value>local</value>
  </property>
</configuration>
EOF

cat > "$HIVE_CONF_DIR/hive-site.xml" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<configuration>
  <property>
    <name>javax.jdo.option.ConnectionURL</name>
    <value>jdbc:derby:;databaseName=${PROJECT_DIR}/metastore_db;create=true</value>
  </property>
  <property>
    <name>hive.metastore.warehouse.dir</name>
    <value>${PROJECT_DIR}/warehouse</value>
  </property>
  <property>
    <name>hive.exec.scratchdir</name>
    <value>${PROJECT_DIR}/scratch</value>
  </property>
  <property>
    <name>hive.server2.logging.operation.enabled</name>
    <value>false</value>
  </property>
</configuration>
EOF

mkdir -p "$PROJECT_DIR/scratch"

rm -rf "$PROJECT_DIR/metastore_db"

echo "=== Initialize Hive Metastore Schema ==="
schematool -dbType derby -initSchema > verification/schema_init.txt 2>&1

echo "=== Hive Version ==="
{
  echo "JAVA_HOME=$JAVA_HOME"
  java -version 2>&1
  hive --version
} | tee verification/hive_version.txt

echo "=== Run Exp8 Hive Queries ==="
hive --hiveconf PROJECT_DIR="$PROJECT_DIR" -f "$PROJECT_DIR/exp8_queries.hql" 2>&1 | tee verification/hive_run_output.txt

echo "Exp8 complete. Verified outputs saved in verification/."
