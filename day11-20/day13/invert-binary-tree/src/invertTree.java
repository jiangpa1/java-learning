public class invertTree {
    public void main(){
        TreeNode tn = new TreeNode(1);
        TreeNode tn1 = new TreeNode(2);
        tn.left = null;
        tn.right = tn1;
        tn1.left = null;
        tn1.right = null;

        TreeNode result = invertTree(tn);
        printTree(result);
    }

    public TreeNode invertTree(TreeNode root) {
        TreeNode temp;
        if(root == null) return null;
        temp = root.left;
        root.left = root.right;
        root.right = temp;
        if(root.left != null)  invertTree(root.left);
        if(root.right != null) invertTree(root.right);



        return root;
    }

    public void printTree(TreeNode root){
        System.out.println(root.val);
        if(root.left != null) printTree(root.left);
        if(root.right != null) printTree(root.right);

    }

}
