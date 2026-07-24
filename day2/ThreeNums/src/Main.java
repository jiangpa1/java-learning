//TIP 要<b>运行</b>代码，请按 <shortcut actionId="Run"/> 或
// 点击装订区域中的 <icon src="AllIcons.Actions.Execute"/> 图标。
void main() {
    int[] nums = new int[]{-3,3,2,-1,0,2,-1};
    List<List<Integer>> matrix = threeSum(nums);
    System.out.println(matrix);
}

public List<List<Integer>> threeSum(int[] nums) {
    for(int i = 0;i<nums.length;i++){
        for(int j = i+1;j<nums.length;j++){
            int temp = nums[i];
            int k = i;
            if(temp>nums[j]){
                temp = nums[j];
                k = j;
            }
            nums[k] = nums[i];
            nums[i] = temp;
        }
    }
    List<List<Integer>> matrix = new ArrayList<>();
    for(int i = 0;i<nums.length;i++){
        if(i>0 && nums[i] == nums[i-1]){
            continue;
        }
        if(nums[i]<=0){
            int j = i+1;
            int k = nums.length - 1;
            while(j<k){
                int sum = nums[i] + nums[j] + nums[k];
                if(sum == 0){
                    List<Integer> l = new ArrayList<>();
                    l.add(nums[i]);
                    l.add(nums[j]);
                    l.add(nums[k]);
                    matrix.add(l);
                    while (j < k && nums[j] == nums[j+1]) j++;
                    while (j < k && nums[k] == nums[k-1]) k--;
                    j++;
                    k--;
                }else if(sum < 0){
                    j++;
                }else{
                    k--;
                }
            }

        }else{
            break;
        }
    }
    return matrix;
}