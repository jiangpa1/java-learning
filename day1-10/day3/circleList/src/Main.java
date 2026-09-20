
void main() {
    ListNode head = new ListNode(5);
    ListNode head2 = new ListNode(3);
    ListNode head3 = new ListNode(2);
    ListNode head4 = new ListNode(3);
    head.next = head2;
    head2.next = head3;
    head3.next = head4;
    head4.next = head2;
    boolean result = hasCycle2(head);
    System.out.println(result);
}





public boolean hasCycle1(ListNode head) {
    ListNode p = head;
    Set<ListNode> visited = new HashSet<>();
    while(p!=null){
        if(visited.contains(p)){
            return true;
        }
        visited.add(p);
        p = p.next;
    }
    return false;

}

public boolean hasCycle2(ListNode head) {
    if (head == null || head.next == null) return false;

    ListNode slow = head;      // 慢指针走一步
    ListNode fast = head.next; // 快指针走两步

    while (slow != fast) {
        // 如果快指针走到了尽头，说明没环
        if (fast == null || fast.next == null) {
            return false;
        }
        slow = slow.next;
        fast = fast.next.next;
    }

    // 只有相遇了（slow == fast）才会跳出循环
    return true;
}