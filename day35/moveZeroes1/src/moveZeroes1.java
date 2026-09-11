import java.util.Arrays;

public class moveZeroes1 {
    void main(){
        int[] arr = {0,1,0,3,12};
        moveZeroes3(arr);
        System.out.println(Arrays.toString(arr));
    }

    public void moveZeroes(int[] nums) {
        for (int i = 0; i < nums.length; i++) {
            while (nums[i] == 0) {
                int sum = 0;
                for (int index = i; index < nums.length; index++) {
                    sum += nums[index];
                }
                if (sum == 0) {
                    break;
                }
                int j = i;
                while (j + 1 < nums.length) {
                    nums[j] = nums[j + 1];
                    j++;
                }
                nums[j] = 0;
            }

        }
    }


    public void moveZeroes2(int[] nums) {
        for (int i = 0; i < nums.length; i++) {
            if (nums[i] == 0) {
                for (int j = i+1; j < nums.length; j++) {
                    if (nums[j] != 0) {
                        int temp = nums[j];
                        nums[j] = nums[i];
                        nums[i] = temp;
                        break;
                    }
                }
            }
        }
    }

    
}
