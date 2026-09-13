import java.util.Scanner;

public class reverseWords1 {
    void main(){
        String sc = "Let's take LeetCode contest";
        System.out.println(reverseWords(sc));
    }

    public String reverseWords(String s) {
        String[] s1 = s.split(" ");
        StringBuilder sb = new StringBuilder();
        for (int i = 0; i < s1.length; i++) {
            for (int j = s1[i].length() - 1; j >= 0; j--) {
                char ch = s1[i].charAt(j);
                sb.append(ch);
            }
            if(i<s1.length-1){
                sb.append(' ');
            }
        }
        return sb.toString();
    }
}
