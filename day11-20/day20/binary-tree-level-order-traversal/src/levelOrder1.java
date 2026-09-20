import java.util.*;

public class levelOrder1 {
    void main(){
        TreeNode root = new TreeNode(3);
        root.left = new TreeNode(9);
        root.right = new TreeNode(20);

        root.right.left = new TreeNode(15);
        root.right.right = new TreeNode(7);
        List<List<Integer>> lists = levelOrder(root);
        lists.forEach(list -> System.out.println(Arrays.toString(list.toArray())));
    }

    public List<List<Integer>> levelOrder(TreeNode root) {
        Queue<TreeNode> queue = new LinkedList<>();
        List<Integer> list = new ArrayList<>();

        List<List<Integer>> res = new ArrayList<>();
        queue.add(root);
        while (!queue.isEmpty()) {
            int size = queue.size();
            for (int i = 0; i < size ; i++) {
                TreeNode poll = queue.poll();
                if (poll == null) return res;
                list.add(poll.val);
                if (poll.left != null) queue.add(poll.left);
                if (poll.right != null) queue.add(poll.right);
            }
            res.addFirst(list);
            list = new ArrayList<>();
        }

        return res;
    }
}
