import java.io.IOException;

import org.apache.hadoop.conf.Configuration;
import org.apache.hadoop.fs.Path;
import org.apache.hadoop.io.DoubleWritable;
import org.apache.hadoop.io.IntWritable;
import org.apache.hadoop.io.LongWritable;
import org.apache.hadoop.io.Text;
import org.apache.hadoop.mapreduce.Job;
import org.apache.hadoop.mapreduce.Mapper;
import org.apache.hadoop.mapreduce.Reducer;
import org.apache.hadoop.mapreduce.lib.input.FileInputFormat;
import org.apache.hadoop.mapreduce.lib.output.FileOutputFormat;

public class AvgTotalByParentalEducation {

    public static class Map extends Mapper<LongWritable, Text, Text, IntWritable> {
        private final Text outKey = new Text();

        @Override
        public void map(LongWritable key, Text value, Context context) throws IOException, InterruptedException {
            String[] cols = CsvUtils.parseCsv(value.toString());
            if (cols.length < 8 || CsvUtils.isHeader(cols)) {
                return;
            }
            int total = Integer.parseInt(cols[5]) + Integer.parseInt(cols[6]) + Integer.parseInt(cols[7]);
            outKey.set(cols[2]);
            context.write(outKey, new IntWritable(total));
        }
    }

    public static class Reduce extends Reducer<Text, IntWritable, Text, DoubleWritable> {
        @Override
        public void reduce(Text key, Iterable<IntWritable> values, Context context)
                throws IOException, InterruptedException {
            long sum = 0;
            long count = 0;
            for (IntWritable v : values) {
                sum += v.get();
                count++;
            }
            double avg = count == 0 ? 0.0 : (double) sum / count;
            context.write(key, new DoubleWritable(avg));
        }
    }

    public static void main(String[] args) throws Exception {
        if (args.length != 2) {
            System.err.println("Usage: AvgTotalByParentalEducation <input> <output>");
            System.exit(2);
        }

        Configuration conf = new Configuration();
        conf.set("mapreduce.framework.name", "local");
        conf.set("fs.defaultFS", "file:///");

        Job job = Job.getInstance(conf, "average total score by parental education");
        job.setJarByClass(AvgTotalByParentalEducation.class);
        job.setMapperClass(Map.class);
        job.setReducerClass(Reduce.class);
        job.setOutputKeyClass(Text.class);
        job.setOutputValueClass(IntWritable.class);
        job.setMapOutputKeyClass(Text.class);
        job.setMapOutputValueClass(IntWritable.class);
        job.setOutputKeyClass(Text.class);
        job.setOutputValueClass(DoubleWritable.class);

        FileInputFormat.addInputPath(job, new Path(args[0]));
        FileOutputFormat.setOutputPath(job, new Path(args[1]));

        System.exit(job.waitForCompletion(true) ? 0 : 1);
    }
}
