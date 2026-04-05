#!/usr/bin/env bash
set -euo pipefail

source ~/.bashrc

PROJECT_DIR="/mnt/c/Users/vinay/OneDrive/Desktop/ubuntu/hadoop/Exp7_HBase"
HBASE_HOME="/home/vinayak/hbase"
export PATH="$PATH:$HBASE_HOME/bin"
HBASE_SITE="$HBASE_HOME/conf/hbase-site.xml"
HBASE_SITE_BACKUP="$HBASE_HOME/conf/hbase-site.xml.exp7.bak"

cleanup() {
	cp -f "$HBASE_SITE_BACKUP" "$HBASE_SITE" >/dev/null 2>&1 || true
	stop-hbase.sh >/dev/null 2>&1 || true
}

trap cleanup EXIT

cd "$PROJECT_DIR"
mkdir -p verification
rm -f verification/hbase_version.txt verification/hbase_status.txt verification/hbase_crud_output.txt

cp -f "$HBASE_SITE" "$HBASE_SITE_BACKUP"
cat > "$HBASE_SITE" <<'EOF'
<?xml version="1.0"?>
<configuration>
	<property>
		<name>hbase.cluster.distributed</name>
		<value>false</value>
	</property>
	<property>
		<name>hbase.tmp.dir</name>
		<value>/home/vinayak/hbase/tmp</value>
	</property>
	<property>
		<name>hbase.unsafe.stream.capability.enforce</name>
		<value>false</value>
	</property>
	<property>
		<name>hbase.rootdir</name>
		<value>file:///home/vinayak/hbase_data_exp7</value>
	</property>
	<property>
		<name>hbase.zookeeper.property.dataDir</name>
		<value>/home/vinayak/zookeeper_exp7</value>
	</property>
	<property>
		<name>hbase.zookeeper.quorum</name>
		<value>localhost</value>
	</property>
</configuration>
EOF

mkdir -p /home/vinayak/hbase/tmp /home/vinayak/hbase_data_exp7 /home/vinayak/zookeeper_exp7

echo "=== HBase Version ==="
hbase version | tee verification/hbase_version.txt

echo "=== Start HBase ==="
start-hbase.sh

echo "=== Check HBase Shell Status ==="
for i in {1..20}; do
	if echo "status 'simple'" | hbase shell -n > verification/hbase_status.txt 2>&1; then
		break
	fi
	sleep 1
done
cat verification/hbase_status.txt

echo "=== Run CRUD Script ==="
hbase shell -n "$PROJECT_DIR/exp7_crud.hbase" | tee verification/hbase_crud_output.txt

echo "=== Stop HBase ==="
stop-hbase.sh

echo "Exp7 complete. Verified outputs saved in verification/."
