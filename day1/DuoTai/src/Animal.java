abstract class Animal {
    private String name;
    private int age;
    private String color;

    public Animal(){
    }
    public Animal(String name,int age,String color){
        this.name = name;
        this.age = age;
        this.color = color;
    }

    public String getName(){
        return this.name;
    }
    public int getAge(){
        return this.age;
    }
    public String getColor(){
        return this.color;
    }

    public void setName(Animal animal,String name){
        this.name = name;
    }
    public void setAge(Animal animal,int age){
        this.age = age;
    }
    public void setColor(Animal animal,String color){
        this.color = color;
    }

    public abstract void eat(String something);
}
