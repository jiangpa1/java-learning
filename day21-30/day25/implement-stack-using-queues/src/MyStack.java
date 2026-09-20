import java.util.LinkedList;
import java.util.Queue;

class MyStack {
    private Queue<Integer> queueIn;
    private Queue<Integer> queueOut;

    public MyStack() {
        queueIn = new LinkedList<>();
        queueOut = new LinkedList<>();
    }

    public void push(int x) {
        queueOut.add(x);
        while(!queueIn.isEmpty()){
            queueOut.add(queueIn.poll());
        }

        Queue<Integer> tmp = queueOut;
        queueOut = queueIn;
        queueIn = tmp;
    }

    public int pop() {
        return queueOut.poll();
    }

    public int top() {
        return queueOut.peek();
    }

    public boolean empty() {
        return queueIn.isEmpty() && queueOut.isEmpty();
    }
}