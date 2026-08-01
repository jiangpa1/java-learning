
void main() {


}


public class ListNode {
    int val;
    ListNode next;
    ListNode() {}
    ListNode(int val) { this.val = val; }
    ListNode(int val, ListNode next) { this.val = val; this.next = next; }
}

class Solution {
    public ListNode removeNthFromEnd(ListNode head, int n) {
        ListNode ptr = null;
        ListNode result = head;
        if(head.next == null) return null;
        while(true){
            ptr = head;
            for(int i = 0;i<n;i++){
                ptr = ptr.next;
            }
            if(ptr == null){
                return head.next;
            }
            if(ptr.next == null) {
                head.next = head.next.next;
                break;
            }
            head = head.next;
        }
        return result;
    }
}