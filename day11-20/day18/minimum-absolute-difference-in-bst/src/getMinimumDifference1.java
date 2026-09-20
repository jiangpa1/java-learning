public class getMinimumDifference1 {
    int min = Integer.MAX_VALUE;
    void main(){
        TreeNode t1 = new TreeNode(236);
        TreeNode t2 = new TreeNode(104);
        TreeNode t3 = new TreeNode(701);
        TreeNode t4 = new TreeNode(0);
        TreeNode t5 = new TreeNode(227);
        TreeNode t6 = new TreeNode(911);
        t1.left = t2;
        t1.right = t3;
        t2.left = t4;
        t2.right = t5;
        t3.right = t6;
        System.out.println(getMinimumDifference(t1));
    }

    public int getMinimumDifference(TreeNode root) {
        TreeNode temp1 = root.left;
        while(temp1 != null && temp1.right != null) temp1 = temp1.right;
        TreeNode temp2 = root.right;
        while(temp2 != null && temp2.left != null) temp2 = temp2.left;
        if (temp1 != null) {
            min = Math.min(min, Math.abs(root.val - temp1.val));
        }
        if (temp2 != null) {
            min = Math.min(min, Math.abs(root.val - temp2.val));
        }
        if (root.left != null) {
            getMinimumDifference(root.left);
        }
        if (root.right != null) {
            getMinimumDifference(root.right);
        }
        return min;
    }
}
