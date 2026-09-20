public class Person {
    private String name;
    private int age;

    public Person(){

    }
    public Person(String name,int age){
        this.name = name;
        this.age = age;
    }

    public String getName(){
        return this.name;
    }
    public int getAge(){
        return this.age;
    }

    public void setName(String name){
        this.name = name;
    }
    public void setAge(int age){
        this.age = age;
    }

    public void keepPet(Dog dog,String something){
        System.out.print("年龄为"+age+"的"+name+"养了一只"+dog.getAge()+"岁的"+dog.getColor()+"的宠物狗,正在");
        dog.eat(something);
    }
}
