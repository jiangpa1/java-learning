public class searchBST1 {
    public void main(){
        TreeNode t1 = new TreeNode(4);
        TreeNode t2 = new TreeNode(2);
        TreeNode t3 = new TreeNode(7);
        TreeNode t4 = new TreeNode(1);
        TreeNode t5 = new TreeNode(3);
        t1.left = t2;
        t1.right = t3;
        t2.left = t4;
        t2.right = t5;
        printTree(searchBST(t1, 2));
    }

    public TreeNode searchBST(TreeNode root, int val) {
        while (root != null) {
            if (root.val > val){
                root = root.left;
            } else if(root.val < val){
                root = root.right;
            }else break;

        }
        return root;
    }

    public void printTree(TreeNode root){
        System.out.println(root.val);
        if(root.left != null) printTree(root.left);
        if(root.right != null) printTree(root.right);

    }
}
