import java.util.Arrays;

public class searchRange1 {
    void main(){
        int[] arr = {5,7,7,8,8,10};
        System.out.println(Arrays.toString(searchRange(arr, 6)));
    }

    public int[] searchRange(int[] nums, int target) {
        if(nums.length == 0){
            return new int[]{-1,-1};
        }
        int start = bios(nums, target, 0, nums.length-1);
        int end = biob(nums, target, 0, nums.length-1);
        return new int[]{start, end};
    }

    public int biob(int[] nums, int target, int start, int end){
        if(start > end){return -1;}
        int mid = (start+end)/2;
        if(mid == end && nums[mid]==target){return mid;}
        if(nums[mid]==target && nums[mid+1]!=target){
            return mid;
        }
        if(nums[mid]<=target){
            return biob(nums, target, mid+1, end);
        }else if(nums[mid]>target){
            return biob(nums, target, start, mid-1);
        }
        return -1;
    }

    public int bios(int[] nums, int target, int start, int end){
        if(start > end){return -1;}
        int mid = (start+end)/2;
        if(mid == start && nums[mid]==target){return mid;}
        if(nums[mid]==target && nums[mid-1]!=target){
            return mid;
        }
        if(nums[mid]<target){
            return bios(nums, target, mid+1, end);
        }else if(nums[mid]>=target){
            return bios(nums, target, start, mid-1);
        }
        return -1;
    }
}
