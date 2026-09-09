import java.util.ArrayList;
import java.util.List;

public class intersection1 {
    void main(){

    }

    public int[] intersection(int[] nums1, int[] nums2) {
        List<Integer> list = new ArrayList<>();
        for (int i : nums1) {
            for (int j : nums2) {
                if (i == j && !list.contains(i)) {
                    list.add(i);
                }
            }
        }
        return list.stream().mapToInt(Integer::intValue).toArray();
    }
}
