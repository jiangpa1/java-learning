import java.util.HashSet;

public class lowestCommonAncestor1 {
    HashSet<TreeNode>  set = new HashSet<>();


    void main(){
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
        TreeNode treeNode = lowestCommonAncestor(root, node5, node0);
        System.out.println(treeNode.val);

    }

    public TreeNode lowestCommonAncestor(TreeNode root, TreeNode p, TreeNode q) {


        while (true) {
            if(p.left == q || p.right == q){
                return p;
            }else if(q.left == p || q.right == p){
                return q;
            } else if (q == p) {
                return p;
            }
            q = findFather(root, q);
            p =  findFather(root, p);
            if(set.contains(p)){return p;} else if (set.contains(q)) {
                return q;
            }
        }


    }

    public TreeNode findFather(TreeNode root,  TreeNode p) {

        if(root==p){return root;}
        set.add(p);
        TreeNode curr = root;
        while (curr != null) {

            if (curr.left == p || curr.right == p) {

                return curr;
            }


            if (p.val < curr.val) {
                curr = curr.left;
            } else {
                curr = curr.right;
            }
        }
        return root;
    }
}
