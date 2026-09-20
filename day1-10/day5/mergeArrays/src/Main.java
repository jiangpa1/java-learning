//TIP 要<b>运行</b>代码，请按 <shortcut actionId="Run"/> 或
// 点击装订区域中的 <icon src="AllIcons.Actions.Execute"/> 图标。
void main() {
    int[] nums1 = new int[]{1,2,3,0,0,0};
    int[] nums2 = new int[]{4,5,6};
    int m = 3;
    int n = 3;
    merge(nums1,m,nums2,n);
    for (int i = 0; i < nums1.length; i++) {
        System.out.println(nums1[i]);
    }
}


public void merge(int[] nums1, int m, int[] nums2, int n) {
    if(m == 0) {
        for(int i = 0;i < nums2.length;i++){
            nums1[i] = nums2[i];
        }
    }
    int i = m - 1;
    int j = n - 1;

    int ptr = nums1.length - 1;
    while(i > -1 && j > -1){

        if(nums2[j] > nums1[i]){
            nums1[ptr] = nums2[j];
            j--;
        }else{
            nums1[ptr] = nums1[i];
            i--;
        }

        ptr--;

    }
    while(j > -1){
        for(;ptr > -1;ptr --){

            nums1[ptr] = nums2[j];
            j--;
        }

    }
    //     if(m != 0 && n !=0){
    //         if(nums1[0] > nums2[0]) nums1[0] = nums2[0];
    //     }
}