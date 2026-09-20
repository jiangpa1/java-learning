import java.util.Arrays;

public class search1 {
    void main(){

        int[] arr = {12};
        System.out.println(search(arr, 12));
    }

    public int search(int[] nums, int target) {
        return bio(nums, target, 0, nums.length-1);
    }

    public int bio(int[] nums, int target, int start, int end){
        if(start > end){return -1;}
        int mid =  start + (end-start)/2;
        if(target>nums[mid]){
            start = mid+1;
            return  bio(nums, target, start, end);
        }else if(target<nums[mid]){
            end = mid-1;
            return  bio(nums, target, start, end);
        }else return mid;
    }
}
