import java.io.IOException;

import org.apache.hadoop.conf.Configuration;
import org.apache.hadoop.fs.Path;
import org.apache.hadoop.io.LongWritable;
import org.apache.hadoop.io.NullWritable;
import org.apache.hadoop.io.Text;
import org.apache.hadoop.mapreduce.Job;
import org.apache.hadoop.mapreduce.Mapper;
import org.apache.hadoop.mapreduce.Reducer;
import org.apache.hadoop.mapreduce.lib.input.FileInputFormat;
import org.apache.hadoop.mapreduce.lib.output.FileOutputFormat;

public class DistinctScoreTriplesCount {

    public static class Map extends Mapper<LongWritable, Text, Text, NullWritable> {
        private final Text outKey = new Text();

        @Override
        public void map(LongWritable key, Text value, Context context) throws IOException, InterruptedException {
            String[] cols = CsvUtils.parseCsv(value.toString());
            if (cols.length < 8 || CsvUtils.isHeader(cols)) {
                return;
            }
            outKey.set(cols[5] + "," + cols[6] + "," + cols[7]);
            context.write(outKey, NullWritable.get());
        }
    }

    public static class Reduce extends Reducer<Text, NullWritable, Text, LongWritable> {
        private long uniqueCount;

        @Override
        protected void setup(Context context) {
            uniqueCount = 0;
        }

        @Override
        public void reduce(Text key, Iterable<NullWritable> values, Context context) {
            uniqueCount++;
        }

        @Override
        protected void cleanup(Context context) throws IOException, InterruptedException {
            context.write(new Text("distinct_score_triples"), new LongWritable(uniqueCount));
        }
    }

    public static void main(String[] args) throws Exception {
        if (args.length != 2) {
            System.err.println("Usage: DistinctScoreTriplesCount <input> <output>");
            System.exit(2);
        }

        Configuration conf = new Configuration();
        conf.set("mapreduce.framework.name", "local");
        conf.set("fs.defaultFS", "file:///");

        Job job = Job.getInstance(conf, "distinct score triples count");
        job.setJarByClass(DistinctScoreTriplesCount.class);
        job.setMapperClass(Map.class);
        job.setReducerClass(Reduce.class);
        job.setNumReduceTasks(1);
        job.setMapOutputKeyClass(Text.class);
        job.setMapOutputValueClass(NullWritable.class);
        job.setOutputKeyClass(Text.class);
        job.setOutputValueClass(LongWritable.class);

        FileInputFormat.addInputPath(job, new Path(args[0]));
        FileOutputFormat.setOutputPath(job, new Path(args[1]));

        System.exit(job.waitForCompletion(true) ? 0 : 1);
    }
}
