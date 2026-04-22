#!/usr/bin/env bash
# ============================================================
# Exp10_Kafka — run_all.sh (FINAL, Docker-only, stable)
# ============================================================
set -euo pipefail
PROJECT_DIR="/mnt/c/Users/vinay/OneDrive/Desktop/ubuntu/hadoop/Exp10_Kafka/Exp10_Kafka"
cd "$PROJECT_DIR"

mkdir -p verification logs
LOG_FILE="logs/exp10_run_$(date +%Y%m%d_%H%M%S).txt"
exec > >(tee "$LOG_FILE") 2>&1

echo "============================================================"
echo " Exp10 — Working with Distributed Messaging using Apache Kafka"
echo " $(date)"
echo "============================================================"

# ── 1. Preflight ─────────────────────────────────────────────
if ! command -v docker &>/dev/null; then
  echo "[ERROR] Docker not found."
  exit 1
fi

if ! docker info &>/dev/null; then
  echo "[ERROR] Docker daemon not running."
  exit 1
fi

echo "[Preflight] Docker OK"

# ── 2. Start services ────────────────────────────────────────
echo ""
echo "=== Step 1 & 2: Starting ZooKeeper and Kafka ==="
docker compose up -d

# Get Kafka container ID
KAFKA_CONTAINER=$(docker compose ps -q kafka)

if [ -z "$KAFKA_CONTAINER" ]; then
  echo "[ERROR] Kafka container not found."
  docker compose down
  exit 1
fi

echo "[Info] Kafka container: $KAFKA_CONTAINER"

# ── 3. Wait for Kafka ───────────────────────────────────────
echo "[Wait] Waiting for Kafka to be ready..."

RETRIES=12
for i in $(seq 1 $RETRIES); do
  if docker exec "$KAFKA_CONTAINER" kafka-topics --bootstrap-server localhost:9092 --list &>/dev/null; then
    echo "[Health] Kafka broker is ready."
    break
  fi

  echo "[Health] Attempt $i/$RETRIES — waiting 5 s..."
  sleep 5

  if [ "$i" -eq "$RETRIES" ]; then
    echo "[ERROR] Kafka did not start in time."
    docker compose logs kafka
    docker compose down
    exit 1
  fi
done

# ── 4. Create topic ─────────────────────────────────────────
echo ""
echo "=== Step 3: Create Topic 'test-topic' ==="

docker exec "$KAFKA_CONTAINER" kafka-topics \
  --bootstrap-server localhost:9092 \
  --create \
  --topic test-topic \
  --partitions 1 \
  --replication-factor 1 \
  --if-not-exists

echo "[Topics]"
docker exec "$KAFKA_CONTAINER" kafka-topics \
  --bootstrap-server localhost:9092 --list

# ── 5. Run Python demo ──────────────────────────────────────
echo ""
echo "=== Steps 4–7: Producer / Consumer / Groups ==="

docker compose run --rm python-runner bash -c "
pip install kafka-python > /dev/null &&
python src/run_demo.py kafka:29092
"

# ── 6. Kafka version ────────────────────────────────────────
echo ""
echo "=== Kafka Broker Version ==="

docker exec "$KAFKA_CONTAINER" kafka-broker-api-versions \
  --bootstrap-server localhost:9092 2>&1 | head -5 \
  | tee verification/kafka_broker_version.txt

# ── 7. Stop services ────────────────────────────────────────
echo ""
echo "=== Step 8: Stopping Kafka and ZooKeeper ==="
docker compose down

echo ""
echo "============================================================"
echo " Exp10 complete. Verification files:"
ls -1 verification/
echo "============================================================"