public class isSubtree1 {
    void main(){
        TreeNode t1 = new TreeNode(1);
        TreeNode t2 = new TreeNode(1);
        t1.left = t2;
        System.out.println(isSubtree(t1, t2));
    }

    public boolean isSubtree(TreeNode root, TreeNode subRoot) {
        if(root == null){return false;}
        if(root.val == subRoot.val){return isSameTree(root,subRoot) || isSubtree(root.left, subRoot) || isSubtree(root.right, subRoot);}
        else return isSubtree(root.left, subRoot) || isSubtree(root.right, subRoot);
    }

    public boolean isSameTree(TreeNode p, TreeNode q) {
        if(p == null && q == null){ return true;}
        if(p == null || q == null){return false;}
        if(p.val != q.val){return false;}
        return isSameTree(p.left,q.left) && isSameTree(p.right,q.right);
    }
}
