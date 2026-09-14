public class reverseWords1 {
    void main(){
        String str1 = "  hello world  ";
        System.out.println(reverseWords(str1));
    }

    public String reverseWords(String s) {
        StringBuilder sb = new StringBuilder();
        String[] s1 = s.trim().split("\\s+");
        for (int i = s1.length - 1; i >= 0; i--) {
            sb.append(s1[i]);
            if(i != 0){
                sb.append(" ");
            }
        }
        return sb.toString();
    }
}
