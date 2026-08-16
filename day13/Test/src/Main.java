void main() {
    List<Object> list = new ArrayList<>();
    try {
        while(true){
            list.add(new heap[1024 * 1024]);
            System.out.println("当前已分配内存大约: " + list.size() + " MB");
        }
    } catch (OutOfMemoryError e) {
        System.err.println("！！！爆堆了！！！");
        e.printStackTrace();
    }
}

public int method(int n){
    return method(n);
}