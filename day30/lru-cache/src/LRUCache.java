import java.util.HashMap;
import java.util.Map;

class LRUCache {



    ListNode tail = new ListNode();
    ListNode head = new ListNode();





    public LRUCache(int capacity) {
        head.next = tail;
        tail.prev = head;
        for (int i = 0; i < capacity; i++) {
            ListNode node = new ListNode();
            node.next = head.next;
            head.next.prev = node;
            head.next = node;
            node.prev = head;
        }



    }


    public int get(int key) {
        ListNode temp = head;
        while (temp.next != null){
            if(temp.next.key == key){
                ListNode tmp = temp.next;

                temp.next = temp.next.next;
                temp.next.prev = temp;

                tmp.next = head.next;
                head.next.prev = tmp;
                head.next = tmp;
                tmp.prev = head;

                return tmp.value;
            }
            temp = temp.next;
        }
        return -1;
    }

    public void put(int key, int value) {
        ListNode tmp = new ListNode(key,value);
        ListNode temp = head;
        while (temp.next != null){
            if(temp.next.key == key){
                temp.next.value = value;
                get(key);
                return;
            }
            temp = temp.next;
        }

        tmp.next = head.next;
        head.next.prev = tmp;
        head.next = tmp;
        tmp.prev = head;

        tail.prev = tail.prev.prev;
        tail.prev.next = tail;
    }
}

class ListNode{
    int key = -200;
    int value = -200;
    ListNode next;
    ListNode prev;
    ListNode(){
        this.prev = null;
        this.next = null;
    }
    ListNode(int key, int value) {
        this.key = key;
        this.value = value;
    }
}
//此方法没有用上Hashmap，从而查询效率极低，下面的方法为Hashmap+Double LinkedList的组合，实现查询，增删改的高效率



class LRUCache1 {
    // 定义双向链表节点
    class ListNode {
        int key;
        int value;
        ListNode prev;
        ListNode next;
        ListNode() {}
        ListNode(int key, int value) {
            this.key = key;
            this.value = value;
        }
    }

    private Map<Integer, ListNode> cache = new HashMap<>();
    private int size;
    private int capacity;
    private ListNode head, tail; // 哨兵节点

    public LRUCache1(int capacity) {
        this.size = 0;
        this.capacity = capacity;
        // 初始化哨兵节点，避免处理 null 指针
        head = new ListNode();
        tail = new ListNode();
        head.next = tail;
        tail.prev = head;
    }

    public int get(int key) {
        ListNode node = cache.get(key);
        if (node == null) {
            return -1;
        }
        // 如果 key 存在，先通过哈希表定位，再移到头部
        moveToHead(node);
        return node.value;
    }

    public void put(int key, int value) {
        ListNode node = cache.get(key);
        if (node == null) {
            // 如果 key 不存在，创建一个新的节点
            ListNode newNode = new ListNode(key, value);
            cache.put(key, newNode);
            addToHead(newNode);
            size++;
            if (size > capacity) {
                // 如果超出容量，删除双向链表的尾部节点
                ListNode tailNode = removeTail();
                cache.remove(tailNode.key);
                size--;
            }
        } else {
            // 如果 key 存在，先修改 value，再移到头部
            node.value = value;
            moveToHead(node);
        }
    }

    // --- 内部辅助方法，确保操作都是 O(1) ---

    // 将节点添加到头部（紧跟在 head 哨兵之后）
    private void addToHead(ListNode node) {
        node.prev = head;
        node.next = head.next;
        head.next.prev = node;
        head.next = node;
    }

    // 从链表中删除一个节点
    private void removeNode(ListNode node) {
        node.prev.next = node.next;
        node.next.prev = node.prev;
    }

    // 移动节点到头部（先删后加）
    private void moveToHead(ListNode node) {
        removeNode(node);
        addToHead(node);
    }

    // 删除尾部节点（tail 哨兵的前一个）
    private ListNode removeTail() {
        ListNode res = tail.prev;
        removeNode(res);
        return res;
    }
}