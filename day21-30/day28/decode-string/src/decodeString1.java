import java.util.*;
import java.util.stream.Collectors;

public class decodeString1 {

    void main(){
        String str = "3[a]2[bc]";
        String str1 = "3[a2[c]]";
        String str2 = "2[abc]3[cd]ef";
        String str3 = "abc3[cd]xyz";
        String str4 = "10[leetcode]";
        String str5 = "2[4[y]]";
        System.out.println(decodeString(str5));
    }

//    public String decodeString(String s) {
//        return decodeString1(s,0);
//
//    }
//
//    public String decodeString1(String s, int num) {
//        StringBuilder result = new StringBuilder();
//        if(s == null || s.isEmpty()){
//            return "";
//        }else if(s.charAt(0) == '['){
//            fig = 1;
//            return decodeString1(s.substring(1),num).repeat(Math.max(1, num));
//        }else if(s.charAt(0) == ']'){
//            fig = 0;
//            return decodeString1(s.substring(1),num);
//        } else if(s.charAt(0) >= '0' && s.charAt(0) <= '9'){
//            if (fig == 0) {
//                return decodeString1(s.substring(1),num * 10 + Integer.parseInt(s.substring(0,1)));
//            }else return decodeString1(s.substring(1),Integer.parseInt(s.substring(0,1)));
//        }else if(s.charAt(0) >= 'a' && s.charAt(0) <= 'z'){
//            int i = 1;
//            fig = 0;
//            while(s.charAt(i) >= 'a' && s.charAt(i) <= 'z'){
//                i++;
//                if(i == s.length()){
//                    return s;
//                }
//            }
//            String substring = s.substring(0, i);
//
//            String s1 = decodeString1(s.substring(i), 0);
//            if (s.charAt(i) == ']') {
//                result.append(substring);
//                return result.toString();
//            }else {
//                result.append(substring).append(s1);
//                return result.toString();
//            }
//        }
//        return "";
//    }
//}
//    String str = "3[a]2[bc]";aaabcbc
//    String str1 = "3[a2[c]]";
//    String str2 = "2[abc]3[cd]ef";
//    String str3 = "abc3[cd]xyz";
//    String str4 = "10[leetcode]";
//    String str5 = "2[4[y]]";

    public String decodeString(String s) {
        Stack<StringBuilder> resStack = new Stack<>();
        Stack<Integer> numStack = new Stack<>();
        StringBuilder str = new StringBuilder();
        int num = 0;
        for (char c : s.toCharArray()) {
            if(Character.isDigit(c)){
                num = num * 10 + c - '0';
            }else if(c == '['){
                numStack.push(num);
                resStack.push(str);
                num = 0;
                str = new StringBuilder();
            }else if(c == ']'){
                StringBuilder temp = resStack.pop();
                int repeat = numStack.pop();
                for(int i = 0; i < repeat; i++){
                    temp.append(str.toString());
                }
                str = temp;
            }else str.append(c);
        }
        return str.toString();
    }
}

