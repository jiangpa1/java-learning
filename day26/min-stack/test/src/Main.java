void main() {
    MinStack minStack = new MinStack();
    minStack.push(-2);
    minStack.push(-3);
    minStack.push(0);
    System.out.println(minStack.getMin());
    minStack.pop();
    minStack.pop();
    System.out.println(minStack.getMin());
}