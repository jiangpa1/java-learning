//TIP 要<b>运行</b>代码，请按 <shortcut actionId="Run"/> 或
// 点击装订区域中的 <icon src="AllIcons.Actions.Execute"/> 图标。
void main() {
    ListNode n1 = new ListNode(4);
    ListNode n2 = new ListNode(1);
    ListNode n3 = new ListNode(8);
    ListNode n4 = new ListNode(4);
    ListNode n5 = new ListNode(5);
    ListNode b1 = new ListNode(5);
    ListNode b2 = new ListNode(6);
    ListNode b3 = new ListNode(1);
    n1.next = n2;
    n2.next = n3;
    n3.next = n4;
    n4.next = n5;
    b1.next = b2;
    b2.next = b3;
    b3.next = n3;
    ListNode result = getIntersectionNode(n1,b1);
    while(result != null){
        System.out.println(result.val);
        result = result.next;
    }
}

public class ListNode {
    int val;
    ListNode next;
    ListNode(int x) {
    val = x;
    next = null;
    }
}

public ListNode getIntersectionNode(ListNode headA, ListNode headB) {
    if (headA == null || headB == null) return null;

    ListNode pA = headA;
    ListNode pB = headB;

    // 只要 pA 和 pB 不相等，就一直走
    while (pA != pB) {
        // pA 走完 A，就去走 B 链表的头
        pA = (pA == null) ? headB : pA.next;
        // pB 走完 B，就去走 A 链表的头
        pB = (pB == null) ? headA : pB.next;
    }

    // 相遇时，要么是交点，要么都是 null（不相交）
    return pA;
}