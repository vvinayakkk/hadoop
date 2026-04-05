#!/usr/bin/env bash
set -euo pipefail

source ~/.bashrc || true

PROJECT_DIR="/mnt/c/Users/vinay/OneDrive/Desktop/ubuntu/hadoop/Exp9_PySpark"
cd "$PROJECT_DIR"

mkdir -p verification logs
rm -f verification/wordcount_output.txt verification/pyspark_version.txt

VENV_DIR="$PROJECT_DIR/.venv"

if [ ! -x "$VENV_DIR/bin/python" ]; then
  echo "PySpark not found. Installing from requirements.txt..."
  python3 -m venv "$VENV_DIR"
  "$VENV_DIR/bin/python" -m pip install --upgrade pip
  "$VENV_DIR/bin/python" -m pip install -r requirements.txt
fi

echo "=== PySpark Version ==="
"$VENV_DIR/bin/python" - <<'PY' | tee verification/pyspark_version.txt
import pyspark
print(f"pyspark=={pyspark.__version__}")
PY

echo "=== Run WordCount ==="
"$VENV_DIR/bin/python" src/wordcount.py data/input.txt verification/wordcount_output.txt

echo "Exp9 complete. Verified outputs saved in verification/."
