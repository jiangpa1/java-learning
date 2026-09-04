import java.util.HashMap;
import java.util.Map;
import java.util.Objects;
import java.util.PriorityQueue;

public class topKFrequent1 {
    void main(){

        int[] arr = {1,1,1,2,2,3};
        int[] arr1 = {1};
        int[] arr2 = {1,2,1,2,1,2,3,1,3,2};

        for (int i : topKFrequent(arr, 2)) {
            System.out.println(i);
        }
    }

    public int[] topKFrequent(int[] nums, int k) {
        PriorityQueue<Integer> pq = new PriorityQueue<>();
        Map<Integer, Integer> map = new HashMap<>();
        for (int num : nums) {
            map.put(num, map.getOrDefault(num, 0) + 1);
        }
        for (int value : map.values()) {
            pq.add(value);
            if (pq.size() > k) {

                pq.poll();
            }
        }
        int[] res = new int[k];
        int index = 0;
        while (!pq.isEmpty()) {
            for (Map.Entry<Integer, Integer> entry : map.entrySet()) {
                if(Objects.equals(entry.getValue(), pq.peek())){
                    res[index] = entry.getKey();
                    index++;
                    pq.poll();
                }
            }
        }

        return res;
    }
}
