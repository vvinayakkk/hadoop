import java.io.DataInput;
import java.io.DataOutput;
import java.io.IOException;

import org.apache.hadoop.io.Writable;

public class ScoreStatsWritable implements Writable {
    private long mathSum;
    private long readingSum;
    private long writingSum;
    private long count;

    public ScoreStatsWritable() {
    }

    public ScoreStatsWritable(long mathSum, long readingSum, long writingSum, long count) {
        this.mathSum = mathSum;
        this.readingSum = readingSum;
        this.writingSum = writingSum;
        this.count = count;
    }

    public long getMathSum() {
        return mathSum;
    }

    public long getReadingSum() {
        return readingSum;
    }

    public long getWritingSum() {
        return writingSum;
    }

    public long getCount() {
        return count;
    }

    @Override
    public void write(DataOutput out) throws IOException {
        out.writeLong(mathSum);
        out.writeLong(readingSum);
        out.writeLong(writingSum);
        out.writeLong(count);
    }

    @Override
    public void readFields(DataInput in) throws IOException {
        mathSum = in.readLong();
        readingSum = in.readLong();
        writingSum = in.readLong();
        count = in.readLong();
    }
}
