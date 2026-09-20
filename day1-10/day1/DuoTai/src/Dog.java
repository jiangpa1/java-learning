public class Dog extends Animal{
    public Dog(){
    }
    public Dog(String name,int age, String color){
        super(name, age, color);
    }

    @Override
    public void eat(String something){
        System.out.print("两只前腿死死的抱住"+something+"猛吃");
    }

    public void lookHome(){
        System.out.println("正在看家");
    }
}
