import java.io.DataInput;
import java.io.DataOutput;
import java.io.IOException;

import org.apache.hadoop.conf.Configuration;
import org.apache.hadoop.fs.Path;
import org.apache.hadoop.io.LongWritable;
import org.apache.hadoop.io.Text;
import org.apache.hadoop.io.Writable;
import org.apache.hadoop.mapreduce.Job;
import org.apache.hadoop.mapreduce.Mapper;
import org.apache.hadoop.mapreduce.Reducer;
import org.apache.hadoop.mapreduce.lib.input.FileInputFormat;
import org.apache.hadoop.mapreduce.lib.output.FileOutputFormat;

public class CorrelationBtwTopper {

	public static class CorrStatsWritable implements Writable {
		private long count;
		private long sumX;
		private long sumY;
		private long sumX2;
		private long sumY2;
		private long sumXY;
		private long topperCount;
		private long nonTopperCount;
		private long topperMathSum;
		private long nonTopperMathSum;

		public CorrStatsWritable() {
		}

		public CorrStatsWritable(long count, long sumX, long sumY, long sumX2, long sumY2, long sumXY,
				long topperCount, long nonTopperCount, long topperMathSum, long nonTopperMathSum) {
			this.count = count;
			this.sumX = sumX;
			this.sumY = sumY;
			this.sumX2 = sumX2;
			this.sumY2 = sumY2;
			this.sumXY = sumXY;
			this.topperCount = topperCount;
			this.nonTopperCount = nonTopperCount;
			this.topperMathSum = topperMathSum;
			this.nonTopperMathSum = nonTopperMathSum;
		}

		public long getCount() {
			return count;
		}

		public long getSumX() {
			return sumX;
		}

		public long getSumY() {
			return sumY;
		}

		public long getSumX2() {
			return sumX2;
		}

		public long getSumY2() {
			return sumY2;
		}

		public long getSumXY() {
			return sumXY;
		}

		public long getTopperCount() {
			return topperCount;
		}

		public long getNonTopperCount() {
			return nonTopperCount;
		}

		public long getTopperMathSum() {
			return topperMathSum;
		}

		public long getNonTopperMathSum() {
			return nonTopperMathSum;
		}

		@Override
		public void write(DataOutput out) throws IOException {
			out.writeLong(count);
			out.writeLong(sumX);
			out.writeLong(sumY);
			out.writeLong(sumX2);
			out.writeLong(sumY2);
			out.writeLong(sumXY);
			out.writeLong(topperCount);
			out.writeLong(nonTopperCount);
			out.writeLong(topperMathSum);
			out.writeLong(nonTopperMathSum);
		}

		@Override
		public void readFields(DataInput in) throws IOException {
			count = in.readLong();
			sumX = in.readLong();
			sumY = in.readLong();
			sumX2 = in.readLong();
			sumY2 = in.readLong();
			sumXY = in.readLong();
			topperCount = in.readLong();
			nonTopperCount = in.readLong();
			topperMathSum = in.readLong();
			nonTopperMathSum = in.readLong();
		}
	}

	public static class Map extends Mapper<LongWritable, Text, Text, CorrStatsWritable> {
		private static final Text OUT_KEY = new Text("topper_math_corr");
		private int topperThreshold;

		@Override
		protected void setup(Context context) {
			topperThreshold = context.getConfiguration().getInt("topper.total.threshold", 250);
		}

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
			int x = total >= topperThreshold ? 1 : 0;

			CorrStatsWritable stats = new CorrStatsWritable(
					1,
					x,
					math,
					x * x,
					(long) math * math,
					(long) x * math,
					x,
					1 - x,
					x == 1 ? math : 0,
					x == 0 ? math : 0);

			context.write(OUT_KEY, stats);
		}
	}

	public static class Reduce extends Reducer<Text, CorrStatsWritable, Text, Text> {
		private int topperThreshold;

		@Override
		protected void setup(Context context) {
			topperThreshold = context.getConfiguration().getInt("topper.total.threshold", 250);
		}

		@Override
		public void reduce(Text key, Iterable<CorrStatsWritable> values, Context context)
				throws IOException, InterruptedException {
			long n = 0;
			long sumX = 0;
			long sumY = 0;
			long sumX2 = 0;
			long sumY2 = 0;
			long sumXY = 0;
			long topperCount = 0;
			long nonTopperCount = 0;
			long topperMathSum = 0;
			long nonTopperMathSum = 0;

			for (CorrStatsWritable v : values) {
				n += v.getCount();
				sumX += v.getSumX();
				sumY += v.getSumY();
				sumX2 += v.getSumX2();
				sumY2 += v.getSumY2();
				sumXY += v.getSumXY();
				topperCount += v.getTopperCount();
				nonTopperCount += v.getNonTopperCount();
				topperMathSum += v.getTopperMathSum();
				nonTopperMathSum += v.getNonTopperMathSum();
			}

			double numerator = (double) n * sumXY - (double) sumX * sumY;
			double left = (double) n * sumX2 - (double) sumX * sumX;
			double right = (double) n * sumY2 - (double) sumY * sumY;
			double correlation = (left <= 0.0 || right <= 0.0) ? 0.0 : numerator / Math.sqrt(left * right);

			double avgMathTopper = topperCount == 0 ? 0.0 : (double) topperMathSum / topperCount;
			double avgMathNonTopper = nonTopperCount == 0 ? 0.0 : (double) nonTopperMathSum / nonTopperCount;

			String out = String.format(
					"topper_threshold_total=%d, pearson_r=%.6f, toppers=%d, non_toppers=%d, avg_math_toppers=%.3f, avg_math_non_toppers=%.3f",
					topperThreshold, correlation, topperCount, nonTopperCount, avgMathTopper, avgMathNonTopper);

			context.write(new Text("topper_math_correlation"), new Text(out));
		}
	}

	public static void main(String[] args) throws Exception {
		if (args.length != 2) {
			System.err.println("Usage: CorrelationBtwTopper <input> <output>");
			System.exit(2);
		}

		Configuration conf = new Configuration();
		conf.set("mapreduce.framework.name", "local");
		conf.set("fs.defaultFS", "file:///");
		conf.setInt("topper.total.threshold", 250);

		Job job = Job.getInstance(conf, "correlation between topper and math score");
		job.setJarByClass(CorrelationBtwTopper.class);
		job.setMapperClass(Map.class);
		job.setReducerClass(Reduce.class);
		job.setNumReduceTasks(1);
		job.setMapOutputKeyClass(Text.class);
		job.setMapOutputValueClass(CorrStatsWritable.class);
		job.setOutputKeyClass(Text.class);
		job.setOutputValueClass(Text.class);

		FileInputFormat.addInputPath(job, new Path(args[0]));
		FileOutputFormat.setOutputPath(job, new Path(args[1]));

		System.exit(job.waitForCompletion(true) ? 0 : 1);
	}
}
