#!/usr/bin/env bash
set -ex

source ~/.bashrc
export PATH="$PATH:/home/vinayak/hadoop/bin:/home/vinayak/hadoop/sbin"

PROJECT_DIR="/mnt/c/Users/vinay/OneDrive/Desktop/ubuntu/Exp6_Hadoop"
INPUT_FILE="$PROJECT_DIR/data/StudentsPerformance.csv"
JAR_FILE="$PROJECT_DIR/exp6_hadoop.jar"

cd "$PROJECT_DIR"
mkdir -p classes data output verification
rm -rf classes/* output/* verification/* "$JAR_FILE"

if [ ! -f "$INPUT_FILE" ]; then
  cd "$PROJECT_DIR/data"
  kaggle datasets download -d spscientist/students-performance-in-exams --unzip
  cd "$PROJECT_DIR"
fi

echo "=== Compiling Exp6 Java files ==="
javac -classpath "$(/home/vinayak/hadoop/bin/hadoop classpath --glob)" -d classes src/*.java
jar -cvf "$JAR_FILE" -C classes/ .

echo "=== Running Exp6 MapReduce jobs ==="
/home/vinayak/hadoop/bin/hadoop jar "$JAR_FILE" GenderCount "$INPUT_FILE" "$PROJECT_DIR/output/gender_count"
/home/vinayak/hadoop/bin/hadoop jar "$JAR_FILE" LunchTypeCount "$INPUT_FILE" "$PROJECT_DIR/output/lunch_type_count"
/home/vinayak/hadoop/bin/hadoop jar "$JAR_FILE" AvgScoresByGender "$INPUT_FILE" "$PROJECT_DIR/output/avg_scores_by_gender"
/home/vinayak/hadoop/bin/hadoop jar "$JAR_FILE" AvgTotalByParentalEducation "$INPUT_FILE" "$PROJECT_DIR/output/avg_total_by_parent_edu"
/home/vinayak/hadoop/bin/hadoop jar "$JAR_FILE" PerformanceBandDistribution "$INPUT_FILE" "$PROJECT_DIR/output/performance_bands"
/home/vinayak/hadoop/bin/hadoop jar "$JAR_FILE" TopNStudentsByTotalScore "$INPUT_FILE" "$PROJECT_DIR/output/top5_students_total"
/home/vinayak/hadoop/bin/hadoop jar "$JAR_FILE" TestPrepImpact "$INPUT_FILE" "$PROJECT_DIR/output/test_prep_impact"
/home/vinayak/hadoop/bin/hadoop jar "$JAR_FILE" HighestMathByRace "$INPUT_FILE" "$PROJECT_DIR/output/highest_math_by_race"
/home/vinayak/hadoop/bin/hadoop jar "$JAR_FILE" ScoreGapBucketCount "$INPUT_FILE" "$PROJECT_DIR/output/score_gap_buckets"
/home/vinayak/hadoop/bin/hadoop jar "$JAR_FILE" DistinctScoreTriplesCount "$INPUT_FILE" "$PROJECT_DIR/output/distinct_score_triples"

echo "=== Capturing verification outputs ==="
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

echo "=== Printing verification outputs in terminal ==="
for f in "$PROJECT_DIR"/verification/*.txt; do
  echo "--- $(basename "$f") ---"
  cat "$f"
  echo
done

echo "=== Cleanup raw output folders for clash-free rerun ==="
rm -rf "$PROJECT_DIR/output/gender_count" \
       "$PROJECT_DIR/output/lunch_type_count" \
       "$PROJECT_DIR/output/avg_scores_by_gender" \
       "$PROJECT_DIR/output/avg_total_by_parent_edu" \
       "$PROJECT_DIR/output/performance_bands" \
       "$PROJECT_DIR/output/top5_students_total" \
       "$PROJECT_DIR/output/test_prep_impact" \
       "$PROJECT_DIR/output/highest_math_by_race" \
       "$PROJECT_DIR/output/score_gap_buckets" \
       "$PROJECT_DIR/output/distinct_score_triples"

echo "Exp6 complete: outputs verified and raw job outputs cleaned."
