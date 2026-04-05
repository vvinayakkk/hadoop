import java.io.IOException;

import org.apache.hadoop.conf.Configuration;
import org.apache.hadoop.fs.Path;
import org.apache.hadoop.io.IntWritable;
import org.apache.hadoop.io.LongWritable;
import org.apache.hadoop.io.Text;
import org.apache.hadoop.io.WritableComparable;
import org.apache.hadoop.io.WritableComparator;
import org.apache.hadoop.mapreduce.Job;
import org.apache.hadoop.mapreduce.Mapper;
import org.apache.hadoop.mapreduce.Reducer;
import org.apache.hadoop.mapreduce.lib.input.FileInputFormat;
import org.apache.hadoop.mapreduce.lib.output.FileOutputFormat;

public class TopNStudentsByTotalScore {

    public static class DescIntComparator extends WritableComparator {
        protected DescIntComparator() {
            super(IntWritable.class, true);
        }

        @Override
        public int compare(WritableComparable a, WritableComparable b) {
            IntWritable x = (IntWritable) a;
            IntWritable y = (IntWritable) b;
            return -1 * x.compareTo(y);
        }
    }

    public static class Map extends Mapper<LongWritable, Text, IntWritable, Text> {
        private final IntWritable outKey = new IntWritable();
        private final Text outValue = new Text();

        @Override
        public void map(LongWritable key, Text value, Context context) throws IOException, InterruptedException {
            String[] cols = CsvUtils.parseCsv(value.toString());
            if (cols.length < 8 || CsvUtils.isHeader(cols)) {
                return;
            }

            int math = Integer.parseInt(cols[5]);
            int reading = Integer.parseInt(cols[6]);
            int writing = Integer.parseInt(cols[7]);
            int total = math + reading + writing;

            String details = "gender=" + cols[0] + ", race=" + cols[1] + ", parent_education=" + cols[2]
                    + ", lunch=" + cols[3] + ", prep=" + cols[4] + ", scores=" + math + "/" + reading + "/"
                    + writing;

            outKey.set(total);
            outValue.set(details);
            context.write(outKey, outValue);
        }
    }

    public static class Reduce extends Reducer<IntWritable, Text, Text, Text> {
        private int emitted;
        private int topN;

        @Override
        protected void setup(Context context) {
            emitted = 0;
            topN = context.getConfiguration().getInt("top.n", 5);
        }

        @Override
        public void reduce(IntWritable key, Iterable<Text> values, Context context)
                throws IOException, InterruptedException {
            for (Text v : values) {
                if (emitted >= topN) {
                    return;
                }
                emitted++;
                context.write(new Text("rank_" + emitted + " total=" + key.get()), v);
            }
        }
    }

    public static void main(String[] args) throws Exception {
        if (args.length != 2) {
            System.err.println("Usage: TopNStudentsByTotalScore <input> <output>");
            System.exit(2);
        }

        Configuration conf = new Configuration();
        conf.set("mapreduce.framework.name", "local");
        conf.set("fs.defaultFS", "file:///");
        conf.setInt("top.n", 5);

        Job job = Job.getInstance(conf, "top n students by total score");
        job.setJarByClass(TopNStudentsByTotalScore.class);
        job.setMapperClass(Map.class);
        job.setSortComparatorClass(DescIntComparator.class);
        job.setReducerClass(Reduce.class);
        job.setNumReduceTasks(1);
        job.setMapOutputKeyClass(IntWritable.class);
        job.setMapOutputValueClass(Text.class);
        job.setOutputKeyClass(Text.class);
        job.setOutputValueClass(Text.class);

        FileInputFormat.addInputPath(job, new Path(args[0]));
        FileOutputFormat.setOutputPath(job, new Path(args[1]));

        System.exit(job.waitForCompletion(true) ? 0 : 1);
    }
}
