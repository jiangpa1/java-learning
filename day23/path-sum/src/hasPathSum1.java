public class hasPathSum1 {
    void main(){
        TreeNode root = new TreeNode(5);
        TreeNode node4L = new TreeNode(4);
        TreeNode node8R = new TreeNode(8);
        TreeNode node11 = new TreeNode(11);
        TreeNode node13 = new TreeNode(13);
        TreeNode node4R = new TreeNode(4);
        TreeNode node7 = new TreeNode(7);
        TreeNode node2 = new TreeNode(2);
        TreeNode node1 = new TreeNode(1);

        // 3. 按照图片结构连接节点

        // 根节点的左右子节点
        root.left = node4L;
        root.right = node8R;

        // 构建左侧分支 (蓝色部分)
        node4L.left = node11;
        node11.left = node7;
        node11.right = node2;

        // 构建右侧分支
        node8R.left = node13;
        node8R.right = node4R;
        node4R.right = node1;

        System.out.println(hasPathSum(root, 23));

    }

    public boolean hasPathSum(TreeNode root, int targetSum) {
        if(root == null){return false;}
        if(root.val == targetSum && root.left == null && root.right == null){
            return true;
        } else{
            return hasPathSum(root.left, targetSum -  root.val)
                    || hasPathSum(root.right, targetSum - root.val);
        }

    }
}
