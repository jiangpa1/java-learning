public class kthSmallest1 {
    int num = 0;
    int res = 0;
    void main(){
        TreeNode root = new TreeNode(6);
        root.left = new TreeNode(4);
        root.right = new TreeNode(7);
        root.left.left = new TreeNode(2);
        root.left.right = new TreeNode(6);
        root.left.left.left = new TreeNode(1);

        System.out.println(kthSmallest(root, 3));
    }

    public int kthSmallest(TreeNode root, int k) {
        if (num < 0) return -1;
        if(root==null){return -1;}

        kthSmallest(root.left, k);
        if (++num == k) {
            res = root.val;
            num = Integer.MIN_VALUE;
        }
        kthSmallest(root.right, k);

        return res;
    }


}
