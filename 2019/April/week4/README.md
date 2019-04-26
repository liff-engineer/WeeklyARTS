# Weekly ARTS

## Algorithm [561. Array Partition I](https://leetcode.com/problems/array-partition-i/)

随机轻松一下,题目给定了`2n`个整数,要求将这些整数分成两个一组,取其中最小值然后求和,求最大和大小为多少.

题目有个很简单直接的思路:排序,然后从最小的开始取,隔一取一.

```C++
int arrayPairSum(vector<int>& nums) {
    std::sort(nums.begin(),nums.end());
    int result = nums[0];
    for(auto i = 2ul;i < nums.size();i+=2)
    {
        result+=nums[i];
    }
    return result;
}
```

提交之后确实通过了.但是内存表现很好,而运行耗时却属于最差的那种.

这个题目你可以在时间和空间之间选择.因为题目告诉你整数范围是[-10000,10000].你可以声明个 20001 大小的`vector`来记录每个数出现的次数,然后从小到大遍历,根据出现的次数添加到结果中.

我原本想找个时间和空间的平衡选项,使用`map`来记录,却发现其运行性能与`vector`的版本相比相差甚远:

```c++
int arrayPairSum(vector<int>& nums) {
    std::map<int, std::size_t> counts;
    for (auto num : nums)
    {
        counts[num]++;
    }

    int result = 0;
    bool flag = true; //是否要取当前值
    for (auto pair : counts)
    {
        //根据flag判定是否要取当前值
        result += flag ? pair.first : 0;
        //一旦超过1,就可能需要多取一次
        if (flag)
        {
            result += pair.first * ((pair.second - 1) / 2);
        }
        else
        {
            result += pair.first * (pair.second / 2);
        }
        //根据标志及发生次数取
        flag = flag ? (pair.second % 2 != 1) : (pair.second % 2 == 1);
    }
    return result;
}
```

学艺不精.果然`vector`是追求性能的首选.

## Review [Top 25 C++ API design mistakes and how to avoid them](https://www.acodersjourney.com/top-25-cplusplus-api-design-mistakes-and-how-to-avoid-them/)

## Technique

- [The SoA Vector – Part 1: Optimizing the Traversal of a Collection](https://www.fluentcpp.com/2018/12/18/the-soa-vector-part-1-optimizing-the-traversal-of-a-collection/)
- [The SoA Vector – Part 2: Implementation in C++](https://www.fluentcpp.com/2018/12/21/an-soa-vector-with-an-stl-container-interface-in-cpp/)

## Share

## TODO

- [Understanding data-oriented design for entity component systems - Unity at GDC 2019](https://www.youtube.com/watch?v=0_Byw9UMn9g)
- [Unity at GDC - A Data Oriented Approach to Using Component Systems](https://www.youtube.com/watch?v=p65Yt20pw0g)
- [Data Driven Entity Component System in C++17 - lecture by K.Kisielewicz - Code Europe Autumn 2017](https://www.youtube.com/watch?v=tONOW7Luln8)

- [How do components in a component based entity system](https://gamedev.stackexchange.com/questions/152080/how-do-components-in-a-component-based-entity-system)

- [Entity Systems in C++](https://stackoverflow.com/questions/21221992/entity-systems-in-c)
- [Is my understanding of AoS vs SoA advantages/disadvantages correct?](https://stackoverflow.com/questions/40163722/is-my-understanding-of-aos-vs-soa-advantages-disadvantages-correct)

- [Nomad Game Engine: Part 4.3 — AoS vs SoA](https://medium.com/@savas/nomad-game-engine-part-4-3-aos-vs-soa-storage-5bec879aa38c)
