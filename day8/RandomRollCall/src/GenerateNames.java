import java.io.*;
import java.util.Random;

public class GenerateNames {
    static Random rand = new Random();

    static String[] surnames = {
        "张", "李", "王", "刘", "陈", "杨", "赵", "黄", "周", "吴"
    };

    static String[] maleNames = {
        "伟", "强", "磊", "军", "勇", "杰", "涛", "明", "超", "飞",
        "鹏", "浩", "宇", "博", "文", "龙", "刚", "辉", "斌", "峰"
    };

    static String[] femaleNames = {
        "芳", "敏", "静", "丽", "婷", "雪", "玲", "萍", "红", "娜",
        "霞", "梅", "艳", "琳", "琴", "洁", "慧", "怡", "月", "燕"
    };

    public static void main(String[] args) {
        String filePath = "C:\\Users\\ASUS\\Desktop\\java\\day8\\RandomRollCall\\students.txt";

        try (BufferedWriter bw = new BufferedWriter(new FileWriter(filePath))) {
            // 第1位：固定周浩龙
            bw.write("周浩龙-男-22"); bw.newLine();
            System.out.println("1. 周浩龙-男-22");

            // 第2-10位：随机生成（约 7 男 2 女，保持男生多数）
            for (int i = 1; i < 10; i++) {
                // 前 7 个随机生成的人给男生偏高概率
                String gender = rand.nextInt(100) < 70 ? "男" : "女";
                String surname = surnames[rand.nextInt(surnames.length)];
                String name;
                if (gender.equals("男")) {
                    name = maleNames[rand.nextInt(maleNames.length)];
                } else {
                    name = femaleNames[rand.nextInt(femaleNames.length)];
                }
                if (rand.nextBoolean()) {
                    if (gender.equals("男")) {
                        name += maleNames[rand.nextInt(maleNames.length)];
                    } else {
                        name += femaleNames[rand.nextInt(femaleNames.length)];
                    }
                }
                int age = 20 + rand.nextInt(5);
                bw.write(surname + name + "-" + gender + "-" + age);
                bw.newLine();
                System.out.println((i + 1) + ". " + surname + name + "-" + gender + "-" + age);
            }

            System.out.println("\n✅ 已生成 10 名学生：" + filePath);
        } catch (IOException e) {
            e.printStackTrace();
        }
    }
}
