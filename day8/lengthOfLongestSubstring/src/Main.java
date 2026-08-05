
void main() {

    String s = "pwwkkew";
    char[] ch = new char[s.length()];
    for(int i = 0;i<s.length();i++){
        ch[i] = s.charAt(i);
    }
    int j = 0;
    int result = 0;
    Set<Character> hs = new HashSet<>();
    for (int i = j; i < ch.length; i++) {
        boolean bl = hs.add(ch[i]);
        if(!bl){
            j++;
            i = j;
            if(result < hs.size()){
                result = hs.size();
            }
            hs.removeAll(hs);
            hs.add(ch[i]);
        }
    }
    if(result < hs.size()){
        result = hs.size();
    }
    System.out.println(result);
}


class Solution {
    public int lengthOfLongestSubstring(String s) {
        int len = 0;
        int maxLen = 0;
        int n = s.length();
        if(n == 0) return 0;
        int[] arr = new int[128];
        int start = 0;
        for(int i = 0; i < n; i++){
            char c = s.charAt(i);
            if(arr[c] != 0){
                start = Math.max(arr[c], start);
            }
            arr[c] = i + 1;
            len = i - start + 1;
            maxLen = Math.max(len, maxLen);

        }
        return maxLen;
    }
}