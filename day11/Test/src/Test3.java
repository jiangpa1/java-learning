public class Test3 extends Thread{
    static int num = 100;
    @Override
    public void run(){
        while (true){
            synchronized (Test3.class){
                if (num == 0){
                    break;
                }
                if(num % 2 == 1){
                    System.out.println(this.getName()+"获得了一个奇数"+num);
                }
                num--;

            }
        }


    }


}
