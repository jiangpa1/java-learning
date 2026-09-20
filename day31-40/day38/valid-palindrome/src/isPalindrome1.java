public class isPalindrome1 {
    void main(){
        String s = ".,";
        System.out.println(isPalindrome(s));
    }

    public boolean isPalindrome(String s) {
        int start = 0;
        int end = s.length()-1;
        while(start<end) {
            char temp1 = 0;
            while (true) {
                if(start > end) return false;
                boolean isSmall1 = s.charAt(start) >= 'a' && s.charAt(start) <= 'z';
                boolean isBig1 = s.charAt(start) >= 'A' && s.charAt(start) <= 'Z';
                boolean isNumber1 = s.charAt(start) >= '0' && s.charAt(start) <= '9';
                if (!isSmall1 && !isNumber1) {
                    if (isBig1) {
                        temp1 = (char) (s.charAt(start) + 32);
                        break;
                    } else {
                        start++;
                    }
                }else break;
            }

            char temp2 = 1;
            while (true) {
                boolean isSmall2 = s.charAt(end) >= 'a' && s.charAt(end) <= 'z';
                boolean isBig2 = s.charAt(end) >= 'A' && s.charAt(end) <= 'Z';
                boolean isNumber2 = s.charAt(end) >= '0' && s.charAt(end) <= '9';
                if (!isSmall2 && !isNumber2) {
                    if (isBig2) {
                        temp2 = (char) (s.charAt(end) + 32);
                        break;
                    } else {
                        end--;
                    }
                }else break;
            }

            if (s.charAt(start) == s.charAt(end) || temp1 == temp2 || s.charAt(end) == temp1 || s.charAt(start) == temp2) {
                start++;
                end--;
            }else return false;
        }
        return true;
    }
}
