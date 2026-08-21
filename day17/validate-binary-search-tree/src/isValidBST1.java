import java.util.ArrayList;
import java.util.List;

public class isValidBST1 {
    void main(){
        TreeNode t1 = new TreeNode(5);
        TreeNode t2 = new TreeNode(3);
        TreeNode t3 = new TreeNode(6);
        TreeNode t4 = new TreeNode(2);
        TreeNode t5 = new TreeNode(4);
        TreeNode t6 = new TreeNode(1);
        t1.left = t2;
        t1.right = t3;
        t2.left = t4;
        t2.right = t5;
        t3.right = t6;
        System.out.println(isValidBST(t1));


    }

    public boolean isValidBST(TreeNode root) {
        ArrayList<Integer> list = new ArrayList<>();
        tree(root, list);
        for (int i = 0; i < list.size() - 1; i++) {
            if(list.get(i) > list.get(i + 1)) return false;
        }
        return true;
    }

    public void tree(TreeNode root, ArrayList<Integer> list){
        if(root == null) return ;
        tree(root.left, list);

        list.add(root.val);

        tree(root.right , list);
    }
}
