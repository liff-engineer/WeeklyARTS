# Weekly ARTS

## Algorithm [92. Reverse Linked List II](https://leetcode.com/problems/reverse-linked-list-ii/)

题目要求根据范围逆转链表,并且要求一次遍历完成该操作,而范围为`1 ≤ m ≤ n ≤ length of list`.

如果我们把链表作为数组来看,问题可能简单了许多.

假设长度为`N`的数组,那么就需要先记录下`A[m-1]`以及`A[m]`位置,然后找到`A[n]`以及`A[n+1]`位置.

这个问题就可以拆分成两部分:

- 逆转`A[m..n]`
- 重建连接,使得`A[m-1]->A[n]`,并且`A[m]->A[n+1]`

那么首先我们可以尝试实现全部逆转链表:

```C++
ListNode* reverseBetween(ListNode* head, int m, int n) {
    ListNode *last = nullptr;
    ListNode *current = head;

    while (current)
    {
        std::swap(current->next, last);
        std::swap(current, last);
    }
    return last;
}
```

实现该问题的关键在于需要同时记录`A[i-1]`和`A[i]`,然后实现:`A[i]->A[i-1]`,更新`A[i-1]`为`A[i]`,`A[i]`为`A[i+1]`.

注意上述代码实现的两个步骤为:

- `A[i]->A[i-1]`,`A[i-1]=A[i+1]`
- `A[i]=A[i+1]`,`A[i-1]=A[i]`

然后,则需要找到正确的`A[m-1]`、`A[m]`、`A[n]`、`A[n-1]`并建立关联:

```C++
ListNode* reverseBetween(ListNode* head, int m, int n) {
    ListNode *last = nullptr;
    ListNode *current = head;

    //找到头部
    int i = 1;
    for (; i < m; i++)
    {
        last = current;
        current = current->next;
    }

    //A[m-1],A[m]
    auto mark = std::make_pair(last, current);

    //替换
    for (; i <= n; i++)
    {
        std::swap(current->next, last);
        std::swap(current, last);
    }

    //重建连接
    if (mark.first)
    {

        //A[m-1]->A[n]
        mark.first->next = last;
    }

    //A[m]->A[n+1]
    mark.second->next = current;

    //头部切换了
    if (m == 1)
        return last;
    return head;
}
```

## Review

## Technique

C++实现的 ECS 框架如何使用.

## Share

## TODO

《技术的本质》
