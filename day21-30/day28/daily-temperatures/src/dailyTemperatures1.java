import java.util.ArrayDeque;
import java.util.Deque;
import java.util.Stack;

public class dailyTemperatures1 {
    void main(){
        int[] temperatures = {77,77,77,77,77,41,77,41,41,77};
        for (int i : dailyTemperatures(temperatures)) {
            System.out.print(i + " ");
        }
    }

    public int[] dailyTemperatures(int[] temperatures) {
        Deque<Integer> index = new ArrayDeque<>();
        int[] result = new int[temperatures.length];
        for(int i = 0; i < temperatures.length; i++){
            while (!index.isEmpty() && temperatures[index.peek()] < temperatures[i]){
                Integer pop = index.pop();
                result[pop] = i - pop;
            }

            index.push(i);

        }
        return result;
    }
}
