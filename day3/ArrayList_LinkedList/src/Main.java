//TIP 要<b>运行</b>代码，请按 <shortcut actionId="Run"/> 或
// 点击装订区域中的 <icon src="AllIcons.Actions.Execute"/> 图标。
void main() {
    List<Integer> al = new ArrayList<>();
    List<Integer> ll = new LinkedList<>();
    for (int i = 0; i < 100000; i++) {
        al.add(0,i);
    }
    for (int i = 0; i < 100000; i++) {
        ll.add(0,i);
    }
    long startTime = System.nanoTime();
    al.get(50000);
    long endTime = System.nanoTime();
    System.out.println(endTime - startTime);
    startTime = System.nanoTime();

    ll.get(50000);
    endTime = System.nanoTime();
    System.out.println(endTime - startTime);
}
