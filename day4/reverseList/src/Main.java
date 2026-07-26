//TIP 要<b>运行</b>代码，请按 <shortcut actionId="Run"/> 或
// 点击装订区域中的 <icon src="AllIcons.Actions.Execute"/> 图标。
void main() {
    ListNode head = new ListNode(1);
    ListNode h2 = new ListNode(2);
    ListNode h3 = new ListNode(3);
    ListNode h4 = new ListNode(4);
    ListNode h5 = new ListNode(5);
    head.next = h2;
    h2.next = h3;
    h3.next = h4;
    h4.next = h5;
    ListNode result = reverseList(head);
    while(result != null){
        System.out.println(result.val);
        result = result.next;
    }
}


public class ListNode {
     int val;
     ListNode next;
     ListNode() {}
     ListNode(int val) { this.val = val; }
     ListNode(int val, ListNode next) { this.val = val; this.next = next; }
}

//迭代1
public ListNode reverseList(ListNode head) {
    ListNode ptr = head;
    if(head == null || head.next == null) return head;
    ListNode index = ptr.next.next;
    ptr.next.next = ptr;
    ListNode index2 = ptr.next;
    ptr.next = index;
    while (ptr.next != null){
        index = ptr.next.next;
        ptr.next.next = index2;
        index2 = ptr.next;
        ptr.next = index;
    }
    return index2;
}

//迭代2
public ListNode reverseList2(ListNode head) {
    ListNode prev = null;
    ListNode curr = head;

    while (curr != null) {
        // 1. Temporarily store the next node
        ListNode nextTemp = curr.next;

        // 2. Reverse the current node's pointer
        curr.next = prev;

        // 3. Move the pointers one step forward
        prev = curr;
        curr = nextTemp;
    }

    // At the end, prev will be the new head of the reversed list
    return prev;
}
//递归3
public ListNode reverseList3(ListNode head) {
    // 第一步：边界条件（终止条件）
    // 如果链表为空，或者已经走到了最后一个节点，就直接返回
    if (head == null || head.next == null) {
        return head;
    }

    // 第二步：递归“递”进去
    // 我们假设后面的节点都已经翻转好了，newHead 就是原链表的最后一个节点
    ListNode newHead = reverseList(head.next);

    // 第三步：核心逻辑——翻转指针（“归”出来的时候执行）
    // 让当前节点的【下一个节点】指向【自己】
    head.next.next = head;
    // 断开当前节点原本指向下一个节点的指针（防止形成环）
    head.next = null;

    // 返回新的头节点
    return newHead;
}