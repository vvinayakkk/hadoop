#!/usr/bin/env python3
import re
import sys
from pyspark.sql import SparkSession


def main() -> int:
    if len(sys.argv) != 3:
        print("Usage: wordcount.py <input_file> <output_file>")
        return 1

    input_file = sys.argv[1]
    output_file = sys.argv[2]

    spark = (
        SparkSession.builder
        .appName("Exp9PySparkWordCount")
        .master("local[*]")
        .getOrCreate()
    )

    sc = spark.sparkContext
    lines = sc.textFile(input_file)

    words = lines.flatMap(lambda line: re.findall(r"[A-Za-z0-9']+", line.lower()))
    counts = words.map(lambda word: (word, 1)).reduceByKey(lambda a, b: a + b)
    sorted_counts = counts.sortBy(lambda x: (-x[1], x[0]))

    with open(output_file, "w", encoding="utf-8") as f:
        for word, count in sorted_counts.collect():
            f.write(f"{word}\t{count}\n")

    spark.stop()
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
