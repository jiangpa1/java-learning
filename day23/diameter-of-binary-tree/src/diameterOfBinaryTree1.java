public class diameterOfBinaryTree1 {
    int res = Integer.MIN_VALUE;

    void main(){
        TreeNode root = new TreeNode(1);
        root.left = new TreeNode(2);
        root.right = new TreeNode(3);
        root.left.left = new TreeNode(4);
        root.left.right = new TreeNode(5);
        root.left.left.left = new TreeNode(6);
        root.left.right.right = new TreeNode(7);
        root.left.left.left.left = new TreeNode(8);
        root.left.right.right.right = new TreeNode(9);
        System.out.println(diameterOfBinaryTree(root));
        print(root);
    }

    public int diameterOfBinaryTree(TreeNode root) {
        if (root == null) {
            return 0;
        }

        dfs(root);
        return res;
    }

    private int dfs (TreeNode node) {
        if (node == null) {
            return 0;
        }

        int left = dfs(node.left);
        int right = dfs(node.right);

        res = Math.max(res, left + right);
        return 1 + Math.max(left, right);
    }

    public void print(TreeNode root){
        if(root==null){return;}
        print(root.left);
        System.out.print(root.val + " ");
        print(root.right);
    }
}
