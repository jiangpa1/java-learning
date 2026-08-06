
void main() {
    String s = longestPalindrome("cdddc");
    System.out.println(s);
}

public String longestPalindrome(String s){

    int x;
    int y;
    StringBuilder sb = new StringBuilder();
    sb.append(s.charAt(0));
    ArrayList<Character> result = new ArrayList<>();
    for (int i = 0; i < s.length(); i++) {
        x = i;
        y = i;
        int index1 = 1;
        int index2 = 2;
        while(x>-1 && x+index1 < s.length() && s.charAt(x) == s.charAt(x+index1)){
            x--;
            index1+=2;

        }
        while(y>-1 && y+index2 < s.length() && s.charAt(y) == s.charAt(y+index2)){
            y--;
            index2+=2;
        }
        result.removeAll(result);
        for (int n = x>y?y+1:x+1; n < (Math.min(Math.max(x + index1, y + index2), s.length())); n++) {
            result.add(s.charAt(n));
        }
        if (result.size() > sb.length()){
            sb.delete(0,sb.length());
            for (Character c : result) {
                sb.append(c);
            }
        }

    }

    return sb.toString();
}