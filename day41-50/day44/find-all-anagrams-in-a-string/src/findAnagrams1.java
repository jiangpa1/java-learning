import java.util.ArrayList;
import java.util.Arrays;
import java.util.Collections;
import java.util.HashSet;
import java.util.List;
import java.util.Set;
import java.util.stream.Collectors;

public class findAnagrams1 {
    void main(){
        List<Integer> anagrams = findAnagrams("abacbabc", "abc");
        anagrams.forEach(System.out::println);
    }

    public List<Integer> findAnagrams(String s, String p) {
        List<Integer> ans = new ArrayList<>();
        int sLen = s.length(), pLen = p.length();

        // 剪枝：如果 s 的长度小于 p，不可能包含异位词
        if (sLen < pLen) {
            return ans;
        }

        // 用大小为 26 的数组统计字符频次（题目通常只包含小写英文字母）
        int[] pCount = new int[26];
        int[] sCount = new int[26];

        // 1. 初始化第一个窗口（长度为 pLen）
        for (int i = 0; i < pLen; i++) {
            pCount[p.charAt(i) - 'a']++;
            sCount[s.charAt(i) - 'a']++;
        }

        // 检查初始窗口是否匹配
        if (Arrays.equals(pCount, sCount)) {
            ans.add(0);
        }

        // 2. 滑动窗口：每次向右移动一格
        for (int i = pLen; i < sLen; i++) {
            // 右边新字符进入窗口
            sCount[s.charAt(i) - 'a']++;
            // 左边旧字符移出窗口
            sCount[s.charAt(i - pLen) - 'a']--;

            // 如果频次数组完全相同，说明是异位词
            // Arrays.equals 比较固定长度为 26 的数组，耗时为 O(1)
            if (Arrays.equals(pCount, sCount)) {
                // 当前异位词的起始索引是 i - pLen + 1
                ans.add(i - pLen + 1);
            }
        }

        return ans;
    }
}
