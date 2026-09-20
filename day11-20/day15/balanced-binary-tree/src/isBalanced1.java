public class isBalanced1 {
    public void main(){
        TreeNode tn = new TreeNode(1);
        TreeNode tn1 = new TreeNode(2);
        TreeNode tn2 = new TreeNode(2);
        tn.right = tn1;
        tn1.right = tn2;
        System.out.println(isBalanced(tn));
    }


    public boolean isBalanced(TreeNode root) {
        return balanced(root) > -1;
    }

    public int balanced(TreeNode root) {
        if (root == null) return 0;

        int left = balanced(root.left);
        if (left == -1) return -1; // 提前退出（剪枝）

        int right = balanced(root.right);
        if (right == -1) return -1; // 提前退出（剪枝）

        // 核心逻辑：在计算高度的同时判断差值
        if (Math.abs(left - right) > 1) return -1;

        return Math.max(left, right) + 1;
    }
}
