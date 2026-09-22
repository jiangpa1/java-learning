
public class flatten1 {
    void main(){
        TreeNode root = new TreeNode(1);
        root.left = new TreeNode(2);
        root.right = new TreeNode(5);
        root.left.left = new TreeNode(3);
        root.left.right = new TreeNode(4);
        root.right.right = new TreeNode(6);
        flatten(root);
        printRoot(root);

    }

    public void flatten(TreeNode root) {
        if (root == null) return;

        flatten(root.left);
        if (root.left != null) {
            TreeNode temp = root.left;

            while (temp.right != null){
                temp = temp.right;
            }
            flatten(root.right);
            temp.right = root.right;

            root.right = root.left;
            root.left = null;
        }else {
            flatten(root.right);
        }
    }

    public void printRoot(TreeNode root){
        if (root == null) return;
        System.out.println(root.val);
        //printRoot(root.left);
        printRoot(root.right);
    }
}

