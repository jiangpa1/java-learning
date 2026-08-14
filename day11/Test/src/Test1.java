public class Test1 extends Thread{
    static int count = 1000;
    @Override
    public void run(){
        while (true){
            synchronized (Test1.class){
                if(count < 0){
                    break;
                }
                System.out.println(this.getName()+"抽取了一张电影票,剩余"+count+"张");
                count--;
            }

        }

    }
}
