//TIP 要<b>运行</b>代码，请按 <shortcut actionId="Run"/> 或
// 点击装订区域中的 <icon src="AllIcons.Actions.Execute"/> 图标。
void main() {
    ListNode head = new ListNode(5);
    ListNode head2 = new ListNode(3);
    ListNode head3 = new ListNode(2);
    ListNode head4 = new ListNode(3);
    head.next = head2;
    head2.next = head3;
    head3.next = head4;
    head4.next = head2;
    System.out.println(hasCycle1(head).val);
    System.out.println(hasCycle2(head).val);

}



class ListNode {
    int val;
    ListNode next;
    ListNode(int x) {
        val = x;
        next = null;
    }
}



public ListNode hasCycle1(ListNode head) {
    ListNode p = head;
    Set<ListNode> visited = new HashSet<>();
    while(p!=null){
        if(visited.contains(p)){
            return p;
        }
        visited.add(p);
        p = p.next;
    }
    return null;

}

public ListNode hasCycle2(ListNode head) {
    if( head == null || head.next == null) return null;
    ListNode slow = head.next;
    ListNode fast = head.next.next;
    while (slow != fast) {
        if(fast == null || fast.next == null) return null;
        slow = slow.next;
        fast = fast.next.next;
    }
    ListNode ptr = head;
    while (ptr != slow){
        ptr = ptr.next;
        slow = slow.next;
    }
    return ptr;
}