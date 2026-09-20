public class singleNumber {
    public int singleNumber(int[] nums) {
        for (int i = 0; i < nums.length - 1; i++) {
            nums[i+1] = nums[i] ^ nums[i + 1];
        }
        return nums[nums.length-1];
    }

    public void main(){
        int[] nums = {4,1,2,1,2};
        int result = singleNumber(nums);
        System.out.println(result);
    }
}
