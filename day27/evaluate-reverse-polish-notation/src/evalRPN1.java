import java.lang.classfile.instruction.SwitchCase;
import java.util.LinkedList;
import java.util.Queue;
import java.util.Stack;

public class evalRPN1 {
    int num1;
    int num2;
    int result;

    void main(){
        String[] s = {"2","1","+","3","*"};
        System.out.println(evalRPN(s));
    }

    public int evalRPN(String[] tokens) {
        Stack<String> stack = new Stack<>();
        for (int i = 0; i < tokens.length; i++) {
            switch (tokens[i]) {
                case "+":
                    num1 = Integer.parseInt(stack.pop());
                    num2 = Integer.parseInt(stack.pop());
                    result = num1 + num2;
                    stack.push(String.valueOf(result));
                    break;
                case "-":
                    num1 = Integer.parseInt(stack.pop());
                    num2 = Integer.parseInt(stack.pop());
                    result = num2 - num1;
                    stack.push(String.valueOf(result));
                    break;
                case "*":
                    num1 = Integer.parseInt(stack.pop());
                    num2 = Integer.parseInt(stack.pop());
                    result = num1 * num2;
                    stack.push(String.valueOf(result));
                    break;
                case "/":
                    num1 = Integer.parseInt(stack.pop());
                    num2 = Integer.parseInt(stack.pop());
                    result = num2 / num1;
                    stack.push(String.valueOf(result));
                    break;
                default:
                    stack.push(tokens[i]);
            }

        }
        return Integer.parseInt(stack.peek());

    }
}
