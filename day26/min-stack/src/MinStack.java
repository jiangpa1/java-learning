import java.util.Objects;
import java.util.Stack;

class MinStack {
    private final Stack<Integer> stack;
    private final Stack<Integer> minStack;

    public MinStack() {
        stack = new Stack<>();
        minStack = new Stack<>();
    }

    public void push(int value) {
        if(minStack.isEmpty() || value <= minStack.peek()){
            minStack.push(value);
        }

        stack.push(value);
    }

    public void pop() {
        int temp = stack.pop();
        if(temp == minStack.peek()){
            minStack.pop();
        }
    }

    public int top() {
        return stack.peek();
    }

    public int getMin() {
        return minStack.peek();
    }
}