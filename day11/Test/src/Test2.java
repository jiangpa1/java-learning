public class Test2 extends Thread{
    static int count = 100;

    @Override
    public void run(){
        while(true){
            synchronized (Test2.class){
                if(count <10){
                    break;
                }
                System.out.println(this.getName()+"送出1份礼物，还剩下"+count+"份");
                count--;
            }
        }
    }


}
