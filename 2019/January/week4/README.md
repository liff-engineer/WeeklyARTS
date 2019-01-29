# Weekly ARTS

- C++中观察者模式的一种实现

## Algorithm [189. Rotate Array](https://leetcode.com/problems/rotate-array/)

题目要求给定数组,实现类似位操作的右移效果.

譬如,针对数组`[1,2,3,4,5,6,7]`,右移 3 格,则成为`[5,6,7,1,2,3,4]`.

如果使用 STL 的算法则可以直接实现如下:

```C++
void rotate(vector<int>& nums, int k) {
    std::rotate(nums.rbegin(),nums.rbegin()+k,nums.rend());
}
```

那么自己实现时应当如何处理呢?

1. 取出要移动到数组头部的后`k`个数字
2. 将数组前`n-k`个数字向后移动
3. 将后`k`个数字移动到数组前部

实现如下:

```C++
void rotate(vector<int>& nums, int k) {
    if (nums.empty())
        return;
    auto n = nums.size();
    k = k % n;
    //步骤1
    std::vector<int> v(nums.begin()+(n-k), nums.end());

    //步骤2,注意需要从后向前,否则部分会被覆盖
    for (int i = n - 1; i >= k; i--) {
        nums[i] = nums[i - k];
    }

    //步骤3
    for (int i = 0; i < k; i++)
    {
        nums[i] = v[i];
    }
}
```

注意题目说可以尝试空间复杂度为`O(1)`的算法,实际上 STL 的算法就是空间复杂度`O(1)`:

```C++
template<class ForwardIt>
ForwardIt rotate(ForwardIt first, ForwardIt n_first, ForwardIt last)
{
   if(first == n_first) return last;
   if(n_first == last) return first;

   ForwardIt read      = n_first;
   ForwardIt write     = first;
   ForwardIt next_read = first; // read position for when "read" hits "last"

   while(read != last) {
      if(write == next_read) next_read = read; // track where "first" went
      std::iter_swap(write++, read++);
   }

   // rotate the remaining sequence into place
   (rotate)(write, next_read, last);
   return write;
}
```

在自行实现空间复杂度为`O(1)`的过程中出现了各种边界错误等等,这才能体会到 STL 算法库的精妙.

## Review

## Technique [C++中观察者模式的一种实现](Observer.md)

## Share 什么是好的软件设计/架构

最近跟别的项目组的产品经理、研发经理一起吃饭聊了聊,发现他们对于"架构师"的要求和我理解的有一些不太一样,他们希望软件的架构和设计能够让人快速进入工作状态,产生产出.

我去年做了一些现代 C++方面的学习,也做了几个案例来支撑针对软件设计的调整和重构,和部门的架构师一起探讨时,他建议我在软件设计方面着力,对此我一直在思考. 这次跟产品和管理的人接触后有了一点启示.

如果把软件设计/架构作为一个产品来打造,那么具体的开发人员就是用户,什么样的软件设计/架构是好的? 是不是就有了另外一个维度去审视?

我们设计出来的"产品"是否能够满足用户的需求,提供更好的用户体验,是不是在进行设计或者架构动作时需要进行考虑? 这算不算比较重要的因素?

在进行软件设计时,有没有听过用户的需求,现在的模式是不是设计,架构动作完成,要求用户按照这个,按照那个去操作.软件研发中的痛苦是否有一部分来源于此.

以这个视角来看软件设计/架构,或许会有一些新想法和实践出来.

## TODO

C++中"ORM"的简易实现.
