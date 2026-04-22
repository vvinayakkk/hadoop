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

print_success() {
       printf "${BOLD}${GREEN}[DONE]${RESET} %s\n" "$1"
}

source ~/.bashrc
export PATH="$PATH:/home/vinayak/hadoop/bin:/home/vinayak/hadoop/sbin"

# Resolve project directory from this script location so it works on any machine/path.
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$SCRIPT_DIR"
INPUT_FILE="$PROJECT_DIR/data/StudentsPerformance.csv"
LOG_DIR="$PROJECT_DIR/logs"
RUN_TS="$(date +"%Y%m%d_%H%M%S")"
LOG_FILE="$LOG_DIR/exp5_run_${RUN_TS}.txt"

mkdir -p "$LOG_DIR"
exec > >(tee -a "$LOG_FILE") 2>&1
print_step "Saving full terminal log to: $LOG_FILE"

cd "$PROJECT_DIR"
mkdir -p classes output
rm -rf classes/* output/* hadoop_experiment.jar

print_section "Compiling Exp5 Java Files"
javac -classpath "$(/home/vinayak/hadoop/bin/hadoop classpath --glob)" -d classes src/*.java

jar -cvf hadoop_experiment.jar -C classes/ .

print_section "Running Exp5 MapReduce Jobs"

run_job() {
       local class_name="$1"
       local output_folder="$2"
       print_step "Running ${class_name} -> output/${output_folder}"
       /home/vinayak/hadoop/bin/hadoop jar hadoop_experiment.jar "$class_name" "$INPUT_FILE" "$PROJECT_DIR/output/$output_folder"
}

run_job "WordFrequency" "word_frequency"
run_job "HighestFrequencyWord" "highest_word"
run_job "LargestInteger" "largest_integer"
run_job "AverageInteger" "average_integer"
run_job "DistinctIntegerCount" "distinct_integer_count"
run_job "OddEvenSet" "odd_even_set"

print_section "Verification Output Preview"
printf "${BOLD}${CYAN}-------------------- Word Frequency (Top 10) --------------------${RESET}\n"
echo "Top words by frequency (parental level of education column):"
sort -k2,2nr "$PROJECT_DIR/output/word_frequency/part-r-00000" | head -n 10
printf "${CYAN}---------------------------------------------------------------${RESET}\n\n"

printf "${BOLD}${CYAN}-------------------- Highest Frequency Word --------------------${RESET}\n"
echo "Highest frequency word:"
cat "$PROJECT_DIR/output/highest_word/part-r-00000"
printf "${CYAN}---------------------------------------------------------------${RESET}\n\n"

printf "${BOLD}${CYAN}-------------------- Largest Integer ---------------------------${RESET}\n"
echo "Largest integer (math score column):"
cat "$PROJECT_DIR/output/largest_integer/part-r-00000"
printf "${CYAN}---------------------------------------------------------------${RESET}\n\n"

printf "${BOLD}${CYAN}-------------------- Average Integer ---------------------------${RESET}\n"
echo "Average integer (math score column):"
cat "$PROJECT_DIR/output/average_integer/part-r-00000"
printf "${CYAN}---------------------------------------------------------------${RESET}\n\n"

printf "${BOLD}${CYAN}-------------------- Distinct Integer Count --------------------${RESET}\n"
echo "Distinct integer count (math score column):"
cat "$PROJECT_DIR/output/distinct_integer_count/part-r-00000"
printf "${CYAN}---------------------------------------------------------------${RESET}\n\n"

printf "${BOLD}${CYAN}-------------------- Odd / Even Sets ---------------------------${RESET}\n"
echo "Odd and even sets (math score column):"
cat "$PROJECT_DIR/output/odd_even_set/part-r-00000"
printf "${CYAN}---------------------------------------------------------------${RESET}\n\n"

print_section "Cleanup Raw Output Folders"
rm -rf "$PROJECT_DIR/output/word_frequency" \
       "$PROJECT_DIR/output/highest_word" \
       "$PROJECT_DIR/output/largest_integer" \
       "$PROJECT_DIR/output/average_integer" \
       "$PROJECT_DIR/output/distinct_integer_count" \
       "$PROJECT_DIR/output/odd_even_set"

print_success "Cleanup complete. You can run jobs again without output-path conflicts."
print_success "Saved terminal log: $LOG_FILE"
