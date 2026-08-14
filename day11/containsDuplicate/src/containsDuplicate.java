import java.util.HashSet;

public class containsDuplicate {
    public void main(){
        int[] nums = {1,2,3,4};
        System.out.println(contains_Duplicate(nums));
    }

    public boolean contains_Duplicate(int[] nums) {
        HashSet<Integer> hs = new HashSet<>();
        for (int i = 0; i < nums.length; i++) {
            if(!hs.add(nums[i])) return true;
        }
        return false;
    }
}
