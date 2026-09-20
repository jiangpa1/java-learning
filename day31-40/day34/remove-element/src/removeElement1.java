public class removeElement1 {
    void main(){
        int[] arr = {3};
        System.out.println(removeElement(arr, 2));
    }

    public int removeElement(int[] nums, int val) {
        int i = 0;
        int res = nums.length ;
        while(i<nums.length){
            int j = i+1;
            while(nums[i]==val && j<nums.length){

                int temp = nums[i];
                nums[i]=nums[j];
                nums[j]=temp;

                j++;

            }
            if(nums[i]!=val){
                res = i+1;
            }

            i++;
        }

        return res == nums.length?(nums[0] == val?0:res):res;
    }
}
