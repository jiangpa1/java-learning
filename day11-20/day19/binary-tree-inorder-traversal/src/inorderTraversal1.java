import java.util.ArrayList;
import java.util.List;

public class inorderTraversal1 {
    List<Integer> list = new ArrayList<>();
    void main() {
        TreeNode root = new TreeNode(6);
        TreeNode node2 = new TreeNode(2);
        TreeNode node8 = new TreeNode(8);
        TreeNode node0 = new TreeNode(0);
        TreeNode node4 = new TreeNode(4);
        TreeNode node7 = new TreeNode(7);
        TreeNode node9 = new TreeNode(9);
        TreeNode node3 = new TreeNode(3);
        TreeNode node5 = new TreeNode(5);
        root.left = node2;
        root.right = node8;

        node2.left = node0;
        node2.right = node4;

        node8.left = node7;
        node8.right = node9;

        node4.left = node3;
        node4.right = node5;
        inorderTraversal(root).forEach(System.out::println);
    }

    public List<Integer> inorderTraversal(TreeNode root) {
        if (root == null) return new ArrayList<>();
        inorderTraversal(root.left);
        list.add(root.val);
        inorderTraversal(root.right);
        return list;
    }
}
