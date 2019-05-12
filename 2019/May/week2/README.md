# Weekly ARTS

- 没有了 OOP,你是否还能写得出代码?

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

## Share 没有了 OOP,你是否还能写得出代码?

自从了解到`Data Oriented Design` 以及 ECS 之后,我就有那么一点着迷,因为我发现目前工作所要解决的一部分业务场景应用 ECS 设计是非常合适的.

在读完陈皓的《编程的本质》那篇文章之后,我对业务进行更进一步的理解、抽象,最终得出了旧有实现面临困境的部分原因.因而我基于对业务的理解,以及 ECS 的设计思想,对现有软件进行了重新设计,并将方案提供给了一部分同事审阅.

最终效果很不理想,收集到的反馈以及我察觉到的,`Data Oriented Design`的理念,以及 ECS 的设计思想,与 OOP 是如此不同,以至于他们无法接受这种方式,或许他们会承认 ECS 有其独到之处,却依然执着于该如何将旧有 OOP 代码转换成 ECS 来书写,而不是看一看问题是什么.

这个自然与他们没有接触过 ECS 有关,但是我也看出了另外一些问题,我们自身的经验、所处的环境、能看到的世界,好像被 OOP 给框起来了,脱离了 OOP,貌似就不知道该如何设计、如何实现.

陈皓《编程的本质》是其《编程范式》系列的一部分,其中展示的编程范式就有多种:面向过程、泛型、函数式编程、面向对象、基于原型、逻辑编程等等,我所使用的工作语言 C++自身就是多范式的,能够采用面向过程、面向对象、泛型编程、支持较弱的函数式编程,来完成我们的工作.堪称 C++精华的 STL 即是泛型编程的体现. 那是什么蒙蔽了我们的双眼? 以至于泛型编程对于 C++程序员来讲是相对高阶的内容,团队都不太敢采用这种范式.

这个世界不止 OOP 这种方式,我们可以以各种方式解决问题,退一步讲,每种方式都有其适用场景,没有银弹.不要给自己设限,多了解一下广阔的世界.

## TODO

《技术的本质》

- [The repeated deaths of OOP](http://loup-vaillant.fr/articles/deaths-of-oop)
- [Why OO Sucks](http://www.cs.otago.ac.nz/staffpriv/ok/Joe-Hates-OO.htm)
- [OOP is the Root of All Evil](https://www.youtube.com/watch?v=748TEIIlg14)
