import java.util.Arrays;

public class sortedSquares1 {
    void main() {
        int[] arr = {-4, -1, 0, 3, 10};
        int[] ints = sortedSquares(arr);
        System.out.println(Arrays.toString(ints));
    }

    public int[] sortedSquares(int[] nums) {
        for (int i = 0; i < nums.length; i++) {
            nums[i] = nums[i] * nums[i];
        }
        int[] res = new int[nums.length];
        int left = 0;
        int right = nums.length - 1;
        for (int i = nums.length - 1; i >= 0; i--) {
            if (nums[left] < nums[right]) {
                res[i] = nums[right];
                right--;
            }else  {
                res[i] = nums[left];
                left++;
            }
        }
        return res;
    }
}
