public class isSameTree1 {
    void main(){
        TreeNode t1 = new TreeNode(1);
        TreeNode t2 = new TreeNode(2);
        TreeNode t3 = new TreeNode(3);
        t1.left = t2;
        t1.right = t3;
        System.out.println(isSameTree(t1, t1));
    }

    public boolean isSameTree(TreeNode p, TreeNode q) {
        if(p == null && q == null){ return true;}
        if(p == null || q == null){return false;}
        if(p.val != q.val){return false;}
        return isSameTree(p.left,q.left) && isSameTree(p.right,q.right);
    }
}
