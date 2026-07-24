public class Cat extends Animal{
    public Cat(){
    }
    public Cat(String name,int age, String color){
        super(name, age, color);
    }

    @Override
    public void eat(String something){
        System.out.print("眯着眼睛侧着头吃"+something);
    }
    public void catchMouse(){
        System.out.println("正在抓老鼠");
    }
}
