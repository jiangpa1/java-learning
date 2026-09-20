import java.util.ArrayList;

public class kthSmallest1 {
    void main(){

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
        System.out.println(kthSmallest(t1, 5));
    }

    public int kthSmallest(TreeNode root, int k) {
        ArrayList<Integer> list = new ArrayList<>();
        getSmallest(root,list);
        return list.get(k - 1);
    }

    public void getSmallest(TreeNode root, ArrayList<Integer> list){
        if(root == null) return;
        getSmallest(root.left, list);
        list.add(root.val);
        getSmallest(root.right, list);
    }
}
