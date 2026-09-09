import java.util.Stack;

public class longestCommonPrefix1 {
    void main(){
        String[] strings = new String[]{"dog","racecar","car"};
        System.out.println(longestCommonPrefix(strings));
    }

    public String longestCommonPrefix(String[] strs) {
        if(strs[0].isEmpty()) return strs[0];

        Stack<Character> stack = new Stack<>();
        for(int i=0;;i++){
            if(strs[0].length()==i){
                return strs[0];
            }
            stack.push(strs[0].charAt(i));
            for (String s : strs) {
                if(s.length()==i){
                    return s;
                }
                char c = s.charAt(i);
                if(stack.peek()!=c){
                    stack.pop();
                    return stack.toString().replaceAll("[\\[\\] ,]", "");
                }
            }
        }
    }
}
