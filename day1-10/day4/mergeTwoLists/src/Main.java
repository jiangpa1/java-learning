//TIP 要<b>运行</b>代码，请按 <shortcut actionId="Run"/> 或
// 点击装订区域中的 <icon src="AllIcons.Actions.Execute"/> 图标。
void main() {

}


public class ListNode {
    int val;
    ListNode next;

    ListNode() {
    }

    ListNode(int val) {
        this.val = val;
    }

    ListNode(int val, ListNode next) {
        this.val = val;
        this.next = next;
    }
}

public ListNode mergeTwoLists(ListNode list1, ListNode list2) {
    ListNode tempNode = new ListNode();
    ListNode result = list1;
    if (list1 == null) return list2;
    while (list2 != null) {
        //将第一个数小的当做list1
        if (list1.val > list2.val) {
            ListNode tempList = list1;
            list1 = list2;
            list2 = tempList;
            result = list1;
        }
        //找到list1直到list1.next>list2
        while (list1.val <= list2.val && list1.next != null && list1.next.val <= list2.val) {
            list1 = list1.next;
        }
        //把list2插入list1
        tempNode = list2.next;
        list2.next = list1.next;
        list1.next = list2;
        list1 = list1.next;
        list2 = tempNode;
    }
    return result;
}