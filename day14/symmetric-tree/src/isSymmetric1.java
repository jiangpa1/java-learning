public class isSymmetric1 {
    public void main(){
        TreeNode tn = new TreeNode(1);
        TreeNode tn1 = new TreeNode(2);
        TreeNode tn2 = new TreeNode(2);
        TreeNode tn3 = new TreeNode(3);
        TreeNode tn4 = new TreeNode(3);
        tn.left = tn1;
        tn.right = tn2;
        tn1.left = tn3;
        tn2.left= tn4;

        System.out.println(isSymmetric(tn, tn));
    }


    public boolean isSymmetric(TreeNode x, TreeNode y) {
        if(x == null && y == null){
            return true;
        }else if (x == null || y == null) return false;
        if(x.val != y.val) return false;
        return isSymmetric(x.left, y.right) && isSymmetric(x.right , y.left);
    }
}
