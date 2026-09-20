public class searchInsert1 {
    void main(){
        int[] arr = {1,3,5,6};
        System.out.println(searchInsert(arr, 7));
    }

    public int searchInsert(int[] nums, int target) {

        return bio(nums, target, 0, nums.length-1);
    }

    public int bio(int[] nums, int target, int low, int high) {
        if(low >= high){
            return nums[low] == target?low : nums[low] > target?low :low+1;
        }
        int mid = (low+high)/2;
        if(nums[mid] < target){
            return bio(nums, target, mid+1, high);
        }else if(nums[mid] > target){
            return bio(nums, target, low, mid-1);
        }else return mid;
    }
}
