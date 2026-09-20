import java.util.HashMap;
import java.util.Map;

public class pathSum1 {

    void main(){
        TreeNode root = new TreeNode(1);

        // 层级 1
        root.right = new TreeNode(2);

        // 层级 2
        root.right.right = new TreeNode(3);

        // 层级 3
        root.right.right.right = new TreeNode(4);

        //层级 4
        root.right.right.right.right = new TreeNode(5);

        System.out.println(pathSum(root, 3));
    }

    public int pathSum(TreeNode root, int targetSum) {
        if(root == null) return 0;
        return (int) hasPathSum(root, targetSum)
                + pathSum(root.left, targetSum)  + pathSum(root.right, targetSum);
    }

    public long hasPathSum(TreeNode root, long targetSum) {
        if(root == null) return 0;
        long res = 0;
        if(root.val == targetSum){
            res += 1;
        }

        res +=  hasPathSum(root.left, targetSum - root.val)
                + hasPathSum(root.right, targetSum -  root.val);
        return res;
    }



    public int pathSum1(TreeNode root, int targetSum) {
        // key: 前缀和, value: 该前缀和出现的次数
        Map<Long, Integer> prefixSumMap = new HashMap<>();

        // 初始化：前缀和为 0 的路径默认有 1 条（用于处理从根节点开始就正好等于 targetSum 的情况）
        prefixSumMap.put(0L, 1);

        // 开始递归遍历
        return recursionPathSum(root, 0L, targetSum, prefixSumMap);
    }

    private int recursionPathSum(TreeNode node, long currSum, int target, Map<Long, Integer> map) {
        if (node == null) {
            return 0;
        }

        // 1. 更新当前前缀和
        currSum += node.val;

        // 2. 在哈希表中查找是否存在 oldSum，满足 currSum - oldSum = target
        // 即 oldSum = currSum - target
        int res = map.getOrDefault(currSum - target, 0);

        // 3. 将当前前缀和存入哈希表，供子节点使用
        map.put(currSum, map.getOrDefault(currSum, 0) + 1);

        // 4. 继续递归左右子树
        res += recursionPathSum(node.left, currSum, target, map);
        res += recursionPathSum(node.right, currSum, target, map);

        // 5. 【关键】回溯：离开当前节点时，必须将其前缀和次数减 1
        // 理由：前缀和必须是在“当前分支”上的，不能跨越到其他无关的分支
        map.put(currSum, map.get(currSum) - 1);

        return res;
    }
}




