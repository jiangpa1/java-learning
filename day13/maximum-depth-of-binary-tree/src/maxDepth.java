public class maxDepth {

    public void main(){
        TreeNode tn = new TreeNode(1);
        TreeNode tn1 = new TreeNode(2);
        tn.left = null;
        tn.right = tn1;
        tn1.left = null;
        tn1.right = null;
        System.out.println(maxDepth(tn));
    }

    public int maxDepth(TreeNode root) {
        int result;
        if(root == null) return 0;
        if(root.left != null){
            if(root.right != null){
                result = Math.max(maxDepth(root.right), maxDepth(root.left))+1;
            }else result = maxDepth(root.left)+1;
        }else {
            if(root.right != null){
                result = maxDepth(root.right)+1;
            }else return 1;
        }
        return result;
    }


}
