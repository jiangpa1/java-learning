import java.util.HashSet;
import java.util.Set;

public class findTarget1 {
    public void main(){
        TreeNode t1 = new TreeNode(5);
        TreeNode t2 = new TreeNode(3);
        TreeNode t3 = new TreeNode(6);
        TreeNode t4 = new TreeNode(2);
        TreeNode t5 = new TreeNode(4);
        TreeNode t6 = new TreeNode(11);
        t1.left = t2;
        t1.right = t3;
        t2.left = t4;
        t2.right = t5;
        t3.right = t6;
        System.out.println(findTarget(t1, 13));
    }

    public boolean findTarget(TreeNode root, int k) {
        HashSet<Integer> hs = BST(root, new HashSet<>());
        for (Integer h : hs) {
            if(hs.contains(k - h) && h + h != k) return true;
        }

        return false;

    }

    public HashSet<Integer> BST(TreeNode root, HashSet<Integer> hs){
        if(root == null) return null;
        hs.add(root.val);
        BST(root.left, hs);
        BST(root.right, hs);
        return hs;
    }
}
