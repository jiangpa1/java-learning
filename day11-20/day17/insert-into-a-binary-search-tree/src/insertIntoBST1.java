public class insertIntoBST1 {
    void main(){
        TreeNode t1 = new TreeNode(5);
        TreeNode t2 = new TreeNode(3);
        TreeNode t3 = new TreeNode(6);
        TreeNode t4 = new TreeNode(2);
        TreeNode t5 = new TreeNode(4);
        TreeNode t6 = new TreeNode(11);
        t1.left = t2;
        t1.right = t3;
        t2.left = t4;
        t2.right = t5;
        t3.right = t6;
        printTree(insertIntoBST(t1 , 7));
    }

    public TreeNode insertIntoBST(TreeNode root, int val) {
        TreeNode temp = root;
        if(root == null) return new TreeNode(val);
        while(true){
            if(val > root.val){
                if(root.right != null) {
                    root = root.right;
                }else {
                    root.right = new TreeNode(val);
                    return temp;
                }

            } else if (val < root.val) {
                if(root.left != null) {
                    root = root.left;
                }else {
                    root.left = new TreeNode(val);
                    return temp;
                }
            }
        }

    }

    public void printTree(TreeNode root){
        System.out.println(root.val);
        if(root.left != null) printTree(root.left);
        if(root.right != null) printTree(root.right);

    }
}
