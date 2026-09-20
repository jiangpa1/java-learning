public class removeDuplicates1 {
    void main() {
        int[] arr = {0,0,1,1,1,2,2,3,3,4};
        System.out.println(removeDuplicates(arr));
    }

    public int removeDuplicates(int[] nums) {
        int j = 1;
        int temp = nums[0];
        for (int i = 0; i < nums.length; i++) {
            if (nums[i] != temp) {
                nums[j++] = nums[i];
                temp = nums[i];
            }
        }
        return j;
    }
}