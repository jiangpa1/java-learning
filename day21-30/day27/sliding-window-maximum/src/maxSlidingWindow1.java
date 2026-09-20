import java.util.ArrayDeque;
import java.util.Arrays;
import java.util.Deque;
import java.util.Objects;

public class maxSlidingWindow1 {
    void main(){
        int[] nums = {1,3,-1,-3,5,3,6,7};
        int k=3;
        System.out.println(Arrays.toString(maxSlidingWindow(nums, k)));
    }

    public int[] maxSlidingWindow(int[] nums, int k) {
        Deque<Integer> stack = new ArrayDeque<>();
        int[] res = new int[nums.length - k + 1];
        for(int i=0;i<k;i++){
            stack.push(nums[i]);
        }
        int i1 = stack.stream()
                .max(Integer::compareTo)
                .get();
        res[0] = i1;
        for (int i = 0; k < nums.length; i++, k++) {
            stack.addFirst(nums[k]);
            stack.removeLast();
            if(nums[k] >= i1){
                res[i+1] = nums[k];
                i1 = nums[k];
            } else if (nums[i] == i1) {
                i1 = stack.stream()
                        .max(Integer::compareTo)
                        .get();
                res[i+1] = i1;
            }else res[i+1] = res[i];

        }
        return res;
    }


    public int[] maxSlidingWindow1(int[] nums, int k) {
        int n = nums.length;
        Deque<Integer> deque = new ArrayDeque<Integer>();
        for (int i = 0; i < k; ++i) {
            while (!deque.isEmpty() && nums[i] >= nums[deque.peekLast()]) {
                deque.pollLast();
            }
            deque.offerLast(i);
        }

        int[] ans = new int[n - k + 1];
        ans[0] = nums[deque.peekFirst()];
        for (int i = k; i < n; ++i) {
            while (!deque.isEmpty() && nums[i] >= nums[deque.peekLast()]) {
                deque.pollLast();
            }
            deque.offerLast(i);
            while (deque.peekFirst() <= i - k) {
                deque.pollFirst();
            }
            ans[i - k + 1] = nums[deque.peekFirst()];
        }
        return ans;
    }

//    作者：力扣官方题解
//    链接：https://leetcode.cn/problems/sliding-window-maximum/solutions/543426/hua-dong-chuang-kou-zui-da-zhi-by-leetco-ki6m/
//    来源：力扣（LeetCode）
//    著作权归作者所有。商业转载请联系作者获得授权，非商业转载请注明出处。
}
