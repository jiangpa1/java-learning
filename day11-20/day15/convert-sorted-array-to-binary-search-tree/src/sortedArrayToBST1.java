import java.util.Arrays;

public class sortedArrayToBST1 {
    public void main(){
        int[] nums = {0,1,2};

        printTree(sortedArrayToBST(nums));
    }

    public TreeNode sortedArrayToBST(int[] nums) {
        if(nums == null) return null;

        if(nums.length == 1){
            return new TreeNode(nums[0]);
        } else if (nums.length == 2) {
            TreeNode temp = new TreeNode(nums[1]);
            temp.left = new TreeNode(nums[0]);
            return temp;
        }

        TreeNode root = new TreeNode(nums[nums.length/2]);
        root.left = sortedArrayToBST(Arrays.copyOfRange(nums,0,nums.length/2));
        root.right = sortedArrayToBST(Arrays.copyOfRange(nums,nums.length/2 + 1,nums.length));
        return root;
    }

    public void printTree(TreeNode root){
        System.out.println(root.val);
        if(root.left != null) printTree(root.left);
        if(root.right != null) printTree(root.right);

    }
}
