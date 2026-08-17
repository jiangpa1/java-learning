public class mergeTrees1 {
    public void main(){
        TreeNode tn = new TreeNode(1);
        TreeNode tn1 = new TreeNode(2);
        tn.left = null;
        tn.right = tn1;
        tn1.left = null;
        tn1.right = null;


        TreeNode t = new TreeNode(8);
        TreeNode t1 = new TreeNode(5);
        t.left = null;
        t.right = t1;
        t1.left = null;
        t1.right = null;


        TreeNode result = mergeTrees(tn,t);
        printTree(result);
    }

    public TreeNode mergeTrees(TreeNode root1, TreeNode root2) {
        TreeNode result = new TreeNode();
        if(root1 == null || root2 == null){
            result = root1 == null?root2:root1;
        }else {
            result.val = root1.val + root2.val;
            result.left = mergeTrees(root1.left, root2.left);
            result.right = mergeTrees(root1.right, root2.right);
        }
        return result;
    }


    public void printTree(TreeNode root){
        System.out.println(root.val);
        if(root.left != null) printTree(root.left);
        if(root.right != null) printTree(root.right);

    }
}
