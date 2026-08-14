void main() {
    Thread t1 = new Test3();
    Thread t2 = new Test3();
    t1.start();
    t2.start();
}