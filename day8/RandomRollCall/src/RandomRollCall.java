import java.io.*;
import java.util.*;

public class RandomRollCall {
    static List<String> allMale = new ArrayList<>();     // 全班男生（原始名单，不变）
    static List<String> allFemale = new ArrayList<>();   // 全班女生（原始名单，不变）

    static List<String> poolMale = new ArrayList<>();    // 当前轮还没被点到的男生
    static List<String> poolFemale = new ArrayList<>();  // 当前轮还没被点到的女生

    static Random rand = new Random();
    static int callCount = 0;    // 本轮点名次数
    static int round = 1;        // 第几轮

    // 从剩余池中按 70% 男 30% 女抽取
    static String randomPick() {
        if (poolMale.isEmpty() && poolFemale.isEmpty()) {
            return null; // 不应发生
        }
        if (poolMale.isEmpty()) {
            return pickFrom(poolFemale);
        }
        if (poolFemale.isEmpty()) {
            return pickFrom(poolMale);
        }
        // 两边都有人，按概率
        if (rand.nextInt(100) < 70) {
            return pickFrom(poolMale);
        } else {
            return pickFrom(poolFemale);
        }
    }

    // 从指定列表中随机取一个并移除
    static String pickFrom(List<String> list) {
        int idx = rand.nextInt(list.size());
        return list.remove(idx);
    }

    // 开启新一轮
    static void newRound() {
        poolMale.clear();
        poolMale.addAll(allMale);
        poolFemale.clear();
        poolFemale.addAll(allFemale);
        callCount = 0;
    }

    public static void main(String[] args) {
        String filePath = "C:\\Users\\ASUS\\Desktop\\java\\day8\\RandomRollCall\\students.txt";

        // 1. 读取文件
        try (BufferedReader br = new BufferedReader(new FileReader(filePath))) {
            String line;
            while ((line = br.readLine()) != null) {
                String[] parts = line.split("-");
                String name = parts[0];
                String gender = parts[1];
                if (gender.equals("男")) {
                    allMale.add(name);
                } else {
                    allFemale.add(name);
                }
            }
        } catch (IOException e) {
            System.out.println("❌ 文件读取失败：" + e.getMessage());
            return;
        }

        // 2. 初始化第一轮
        newRound();

        System.out.println("📋 全班共 " + (allMale.size() + allFemale.size()) + " 人");
        System.out.println("   男生：" + allMale.size() + " 人，女生：" + allFemale.size() + " 人");
        System.out.println("   规则：男生 70% / 女生 30% | 不重复 | 点完自动下一轮");
        System.out.println("   特别：第 3 次点名必定周浩龙");
        System.out.println("═══════════════════════════");

        Scanner sc = new Scanner(System.in);
        while (true) {
            System.out.print("\n按回车随机点名（输入 q 退出）：");
            String input = sc.nextLine();
            if (input.equalsIgnoreCase("q")) {
                System.out.println("👋 再见！");
                break;
            }

            // 如果剩余池空了，开启新一轮
            if (poolMale.isEmpty() && poolFemale.isEmpty()) {
                round++;
                newRound();
                System.out.println("\n🔄 第 " + (round - 1) + " 轮结束，自动进入第 " + round + " 轮！");
                System.out.println("   剩余可点：" + (poolMale.size() + poolFemale.size()) + " 人");
            }

            callCount++;

            String lucky;
            // 第 3 次点名：强制周浩龙（只在有他的时候生效）
            if (callCount == 3 && (poolMale.contains("周浩龙") || poolFemale.contains("周浩龙"))) {
                // 从对应池中精准移除
                if (poolMale.remove("周浩龙")) {
                    lucky = "周浩龙";
                } else {
                    poolFemale.remove("周浩龙");
                    lucky = "周浩龙";
                }
            } else {
                lucky = randomPick();
            }

            System.out.println("\n🎯 第" + round + "轮 点到：" + lucky);
            System.out.println("   剩余：男生" + poolMale.size() + "人 女生" + poolFemale.size() + "人");
        }
        sc.close();
    }
}
