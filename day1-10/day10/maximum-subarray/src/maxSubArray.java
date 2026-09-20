public int maxSubArray (int[] nums){
    int j = 0;
    int temp = 0;
    int result = nums[0];
    while(j< nums.length){
        temp += nums[j];
        result = Math.max(temp , result);
        if(temp < 0){
            temp = 0;
        }
        j++;
    }
    return result;
}


void main() {
    int[] nums = {-2,1,-3,4,-1,2,1,-5,4};
    System.out.println(maxSubArray(nums));
    System.out.println(maxSubArrays(nums));
}


//分治法

public int maxSubArrays(int[] nums) {
    return divideAndConquer(nums, 0, nums.length - 1);
}

private int divideAndConquer(int[] nums, int left, int right) {
    // 递归终止条件：子数组只有一个元素
    if (left == right) {
        return nums[left];
    }

    int mid = left + (right - left) / 2;

    // 1. 递归求左半部分最大和
    int leftSum = divideAndConquer(nums, left, mid);
    // 2. 递归求右半部分最大和
    int rightSum = divideAndConquer(nums, mid + 1, right);
    // 3. 求跨越中间的最大和
    int crossSum = maxCrossingSum(nums, left, mid, right);

    // 返回三者中的最大值
    return Math.max(Math.max(leftSum, rightSum), crossSum);
}

private int maxCrossingSum(int[] nums, int left, int mid, int right) {
    // 从中间往左扫描，寻找包含 nums[mid] 的最大和
    int sum = 0;
    int leftMax = Integer.MIN_VALUE;
    for (int i = mid; i >= left; i--) {
        sum += nums[i];
        if (sum > leftMax) {
            leftMax = sum;
        }
    }

    // 从中间往右扫描，寻找包含 nums[mid + 1] 的最大和
    sum = 0;
    int rightMax = Integer.MIN_VALUE;
    for (int i = mid + 1; i <= right; i++) {
        sum += nums[i];
        if (sum > rightMax) {
            rightMax = sum;
        }
    }

    // 跨越中间的最大值 = 左侧扫描最大值 + 右侧扫描最大值
    return leftMax + rightMax;
}
