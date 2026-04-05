#!/usr/bin/env bash
set -ex

source ~/.bashrc
export PATH="$PATH:/home/vinayak/hadoop/bin:/home/vinayak/hadoop/sbin"

PROJECT_DIR="/mnt/c/Users/vinay/OneDrive/Desktop/ubuntu/Exp5_Hadoop"
INPUT_FILE="$PROJECT_DIR/data/StudentsPerformance.csv"

cd "$PROJECT_DIR"
mkdir -p classes output
rm -rf classes/* output/* hadoop_experiment.jar

echo "=== Compiling Java files ==="
javac -classpath "$(/home/vinayak/hadoop/bin/hadoop classpath --glob)" -d classes src/*.java

jar -cvf hadoop_experiment.jar -C classes/ .

echo "=== Running jobs ==="
/home/vinayak/hadoop/bin/hadoop jar hadoop_experiment.jar WordFrequency "$INPUT_FILE" "$PROJECT_DIR/output/word_frequency"
/home/vinayak/hadoop/bin/hadoop jar hadoop_experiment.jar HighestFrequencyWord "$INPUT_FILE" "$PROJECT_DIR/output/highest_word"
/home/vinayak/hadoop/bin/hadoop jar hadoop_experiment.jar LargestInteger "$INPUT_FILE" "$PROJECT_DIR/output/largest_integer"
/home/vinayak/hadoop/bin/hadoop jar hadoop_experiment.jar AverageInteger "$INPUT_FILE" "$PROJECT_DIR/output/average_integer"
/home/vinayak/hadoop/bin/hadoop jar hadoop_experiment.jar DistinctIntegerCount "$INPUT_FILE" "$PROJECT_DIR/output/distinct_integer_count"
/home/vinayak/hadoop/bin/hadoop jar hadoop_experiment.jar OddEvenSet "$INPUT_FILE" "$PROJECT_DIR/output/odd_even_set"

echo "=== Output verification ==="
echo "Top words by frequency (parental level of education column):"
sort -k2,2nr "$PROJECT_DIR/output/word_frequency/part-r-00000" | head -n 10

echo
echo "Highest frequency word:"
cat "$PROJECT_DIR/output/highest_word/part-r-00000"

echo
echo "Largest integer (math score column):"
cat "$PROJECT_DIR/output/largest_integer/part-r-00000"

echo
echo "Average integer (math score column):"
cat "$PROJECT_DIR/output/average_integer/part-r-00000"

echo
echo "Distinct integer count (math score column):"
cat "$PROJECT_DIR/output/distinct_integer_count/part-r-00000"

echo
echo "Odd and even sets (math score column):"
cat "$PROJECT_DIR/output/odd_even_set/part-r-00000"

echo
echo "=== Cleanup generated output directories for rerun safety ==="
rm -rf "$PROJECT_DIR/output/word_frequency" \
       "$PROJECT_DIR/output/highest_word" \
       "$PROJECT_DIR/output/largest_integer" \
       "$PROJECT_DIR/output/average_integer" \
       "$PROJECT_DIR/output/distinct_integer_count" \
       "$PROJECT_DIR/output/odd_even_set"

echo "Cleanup complete. You can run jobs again without output-path conflicts."
