import java.util.ArrayList;
import java.util.Arrays;
import java.util.List;

public class merge1 {
    void main(){
        int[][] intervals = {{1,3},{2,6},{8,10},{15,18}};
        int[][] merge = merge(intervals);
        System.out.println(Arrays.deepToString(merge));
    }

    public int[][] merge(int[][] intervals) {
        int[] start = new int[intervals.length];
        int[] end = new int[intervals.length];
        List<int[]> re = new ArrayList<>();
        for (int i = 0; i < intervals.length; i++) {
            start[i] = intervals[i][0];
            end[i] = intervals[i][1];
        }
        Arrays.sort(start);
        Arrays.sort(end);

        int i = 0;
        while (i < intervals.length) {
            int j = i;
            int[] res = new int[2];
            res[0] = start[i];
            while(j < intervals.length && end[i] >= start[j]){
                res[1] = end[j];
                if(j>i) i++;
                j++;
            }
            re.add(res);
            i = j;
        }
        int size = re.size();
        int[][] result = new int[size][];
        for (int i1 = 0; i1 < size; i1++) {
            result[i1] = re.removeFirst();
        }
        return result;
    }
}
