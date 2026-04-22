#!/usr/bin/env bash
set -euo pipefail

# Color and formatting helpers for readable terminal output.
if [ -t 1 ]; then
  BOLD="\033[1m"
  RED="\033[31m"
  GREEN="\033[32m"
  YELLOW="\033[33m"
  BLUE="\033[34m"
  CYAN="\033[36m"
  RESET="\033[0m"
else
  BOLD=""
  RED=""
  GREEN=""
  YELLOW=""
  BLUE=""
  CYAN=""
  RESET=""
fi

print_section() {
  printf "\n${BOLD}${BLUE}============================================================${RESET}\n"
  printf "${BOLD}${BLUE}%s${RESET}\n" "$1"
  printf "${BOLD}${BLUE}============================================================${RESET}\n"
}

print_step() {
  printf "${BOLD}${GREEN}[STEP]${RESET} %s\n" "$1"
}

print_warn() {
  printf "${BOLD}${YELLOW}[WARN]${RESET} %s\n" "$1"
}

print_success() {
  printf "${BOLD}${GREEN}[DONE]${RESET} %s\n" "$1"
}

source ~/.bashrc
export PATH="$PATH:/home/vinayak/hadoop/bin:/home/vinayak/hadoop/sbin"

# Resolve project directory from this script location so it works on any machine/path.
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$SCRIPT_DIR"
INPUT_FILE="$PROJECT_DIR/data/StudentsPerformance.csv"
JAR_FILE="$PROJECT_DIR/exp6_hadoop.jar"
LOG_DIR="$PROJECT_DIR/logs"
RUN_TS="$(date +"%Y%m%d_%H%M%S")"
LOG_FILE="$LOG_DIR/exp6_run_${RUN_TS}.txt"

mkdir -p "$LOG_DIR"
exec > >(tee -a "$LOG_FILE") 2>&1
print_step "Saving full terminal log to: $LOG_FILE"

cd "$PROJECT_DIR"
mkdir -p classes data output verification
rm -rf classes/* output/* verification/* "$JAR_FILE"

if [ ! -f "$INPUT_FILE" ]; then
  print_warn "Input CSV not found. Downloading dataset from Kaggle..."
  cd "$PROJECT_DIR/data"
  kaggle datasets download -d spscientist/students-performance-in-exams --unzip
  cd "$PROJECT_DIR"
fi

print_section "Compiling Exp6 Java Files"
javac -classpath "$(/home/vinayak/hadoop/bin/hadoop classpath --glob)" -d classes src/*.java
jar -cvf "$JAR_FILE" -C classes/ .

print_section "Running Exp6 MapReduce Jobs"

run_job() {
  local class_name="$1"
  local output_folder="$2"
  print_step "Running ${class_name} -> output/${output_folder}"
  /home/vinayak/hadoop/bin/hadoop jar "$JAR_FILE" "$class_name" "$INPUT_FILE" "$PROJECT_DIR/output/$output_folder"
}

run_job "GenderCount" "gender_count"
run_job "LunchTypeCount" "lunch_type_count"
run_job "AvgScoresByGender" "avg_scores_by_gender"
run_job "AvgTotalByParentalEducation" "avg_total_by_parent_edu"
run_job "PerformanceBandDistribution" "performance_bands"
run_job "TopNStudentsByTotalScore" "top5_students_total"
run_job "TestPrepImpact" "test_prep_impact"
run_job "HighestMathByRace" "highest_math_by_race"
run_job "ScoreGapBucketCount" "score_gap_buckets"
run_job "DistinctScoreTriplesCount" "distinct_score_triples"
run_job "CorrelationBtwTopper" "topper_math_correlation"

print_section "Capturing Verification Outputs"
cat "$PROJECT_DIR/output/gender_count/part-r-00000" > "$PROJECT_DIR/verification/01_gender_count.txt"
cat "$PROJECT_DIR/output/lunch_type_count/part-r-00000" > "$PROJECT_DIR/verification/02_lunch_type_count.txt"
cat "$PROJECT_DIR/output/avg_scores_by_gender/part-r-00000" > "$PROJECT_DIR/verification/03_avg_scores_by_gender.txt"
cat "$PROJECT_DIR/output/avg_total_by_parent_edu/part-r-00000" > "$PROJECT_DIR/verification/04_avg_total_by_parent_edu.txt"
cat "$PROJECT_DIR/output/performance_bands/part-r-00000" > "$PROJECT_DIR/verification/05_performance_bands.txt"
cat "$PROJECT_DIR/output/top5_students_total/part-r-00000" > "$PROJECT_DIR/verification/06_top5_students_total.txt"
cat "$PROJECT_DIR/output/test_prep_impact/part-r-00000" > "$PROJECT_DIR/verification/07_test_prep_impact.txt"
cat "$PROJECT_DIR/output/highest_math_by_race/part-r-00000" > "$PROJECT_DIR/verification/08_highest_math_by_race.txt"
cat "$PROJECT_DIR/output/score_gap_buckets/part-r-00000" > "$PROJECT_DIR/verification/09_score_gap_buckets.txt"
cat "$PROJECT_DIR/output/distinct_score_triples/part-r-00000" > "$PROJECT_DIR/verification/10_distinct_score_triples.txt"
cat "$PROJECT_DIR/output/topper_math_correlation/part-r-00000" > "$PROJECT_DIR/verification/11_topper_math_correlation.txt"

print_section "Verification Output Preview"
for f in "$PROJECT_DIR"/verification/*.txt; do
  printf "${BOLD}${CYAN}-------------------- %s --------------------${RESET}\n" "$(basename "$f")"
  cat "$f"
  printf "${CYAN}--------------------------------------------------------${RESET}\n\n"
done

print_section "Cleanup Raw Output Folders"
rm -rf "$PROJECT_DIR/output/gender_count" \
       "$PROJECT_DIR/output/lunch_type_count" \
       "$PROJECT_DIR/output/avg_scores_by_gender" \
       "$PROJECT_DIR/output/avg_total_by_parent_edu" \
       "$PROJECT_DIR/output/performance_bands" \
       "$PROJECT_DIR/output/top5_students_total" \
       "$PROJECT_DIR/output/test_prep_impact" \
       "$PROJECT_DIR/output/highest_math_by_race" \
       "$PROJECT_DIR/output/score_gap_buckets" \
      "$PROJECT_DIR/output/distinct_score_triples" \
      "$PROJECT_DIR/output/topper_math_correlation"

print_success "Exp6 complete: outputs verified and raw job outputs cleaned."
print_success "Saved terminal log: $LOG_FILE"
