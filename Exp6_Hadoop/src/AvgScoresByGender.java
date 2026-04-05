import java.io.IOException;

import org.apache.hadoop.conf.Configuration;
import org.apache.hadoop.fs.Path;
import org.apache.hadoop.io.LongWritable;
import org.apache.hadoop.io.Text;
import org.apache.hadoop.mapreduce.Job;
import org.apache.hadoop.mapreduce.Mapper;
import org.apache.hadoop.mapreduce.Reducer;
import org.apache.hadoop.mapreduce.lib.input.FileInputFormat;
import org.apache.hadoop.mapreduce.lib.output.FileOutputFormat;

public class AvgScoresByGender {

    public static class Map extends Mapper<LongWritable, Text, Text, ScoreStatsWritable> {
        private final Text outKey = new Text();

        @Override
        public void map(LongWritable key, Text value, Context context) throws IOException, InterruptedException {
            String[] cols = CsvUtils.parseCsv(value.toString());
            if (cols.length < 8 || CsvUtils.isHeader(cols)) {
                return;
            }
            long math = Long.parseLong(cols[5]);
            long reading = Long.parseLong(cols[6]);
            long writing = Long.parseLong(cols[7]);

            outKey.set(cols[0]);
            context.write(outKey, new ScoreStatsWritable(math, reading, writing, 1));
        }
    }

    public static class Reduce extends Reducer<Text, ScoreStatsWritable, Text, Text> {
        @Override
        public void reduce(Text key, Iterable<ScoreStatsWritable> values, Context context)
                throws IOException, InterruptedException {
            long mathSum = 0;
            long readingSum = 0;
            long writingSum = 0;
            long count = 0;

            for (ScoreStatsWritable v : values) {
                mathSum += v.getMathSum();
                readingSum += v.getReadingSum();
                writingSum += v.getWritingSum();
                count += v.getCount();
            }

            double avgMath = count == 0 ? 0.0 : (double) mathSum / count;
            double avgReading = count == 0 ? 0.0 : (double) readingSum / count;
            double avgWriting = count == 0 ? 0.0 : (double) writingSum / count;

            String out = String.format("avg_math=%.3f, avg_reading=%.3f, avg_writing=%.3f, students=%d",
                    avgMath, avgReading, avgWriting, count);
            context.write(key, new Text(out));
        }
    }

    public static void main(String[] args) throws Exception {
        if (args.length != 2) {
            System.err.println("Usage: AvgScoresByGender <input> <output>");
            System.exit(2);
        }

        Configuration conf = new Configuration();
        conf.set("mapreduce.framework.name", "local");
        conf.set("fs.defaultFS", "file:///");

        Job job = Job.getInstance(conf, "average scores by gender");
        job.setJarByClass(AvgScoresByGender.class);
        job.setMapperClass(Map.class);
        job.setReducerClass(Reduce.class);
        job.setMapOutputKeyClass(Text.class);
        job.setMapOutputValueClass(ScoreStatsWritable.class);
        job.setOutputKeyClass(Text.class);
        job.setOutputValueClass(Text.class);

        FileInputFormat.addInputPath(job, new Path(args[0]));
        FileOutputFormat.setOutputPath(job, new Path(args[1]));

        System.exit(job.waitForCompletion(true) ? 0 : 1);
    }
}
