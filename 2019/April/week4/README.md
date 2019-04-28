# Weekly ARTS

- C++中数据按类型访问接口的一种实现
- 你是否被 OO 蒙蔽了双眼

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

## Technique [C++中数据按类型访问接口的一种实现](db_like_api.md)

- [The SoA Vector – Part 1: Optimizing the Traversal of a Collection](https://www.fluentcpp.com/2018/12/18/the-soa-vector-part-1-optimizing-the-traversal-of-a-collection/)
- [The SoA Vector – Part 2: Implementation in C++](https://www.fluentcpp.com/2018/12/21/an-soa-vector-with-an-stl-container-interface-in-cpp/)

## Share 你是否被 OO 蒙蔽了双眼

最近了解到`Data Oriented Design`以及`Entity Component System`架构,感觉一部分认知被打开了.`Data Oriented Design`经常与`Object Oriented Design`进行对比,据我所了解,这种方法在游戏业界应用比较广泛.

每种设计都有其应用场景,这我知道,不过这是我分析完现在产品的业务场景,结合历史经验得到的结论.目前的产品形态更适合从`DOD`及`ECS`中获取灵感,而不是沉迷于 OO,研究各种`Clean Architecture`,领域驱动设计等等. 我们的双眼被自己的经验,周围环境所蒙蔽.却迟迟没有跳出这个环境.即使是我们很努力很用心地分析业务,所作的也只是在现有基础上进行改进,而不是改变.

目前我只是初步了解了`ECS`,已经能够在产品中找到大量应用场景,以前很多很痛苦的实现,一些无法做到的事情用这种思路变得简单直接了.想到之前在泥潭中挣扎,真是有点悔不当初的感觉.

编程范式要好好学习,也要多了解外部世界,各种各样的思路和想法,这样才不至于被 OO 这种最常用的技术蒙蔽了双眼,无法看到更好的实践.

## TODO

- [Understanding data-oriented design for entity component systems - Unity at GDC 2019](https://www.youtube.com/watch?v=0_Byw9UMn9g)
- [Unity at GDC - A Data Oriented Approach to Using Component Systems](https://www.youtube.com/watch?v=p65Yt20pw0g)
- [Data Driven Entity Component System in C++17 - lecture by K.Kisielewicz - Code Europe Autumn 2017](https://www.youtube.com/watch?v=tONOW7Luln8)

- [How do components in a component based entity system](https://gamedev.stackexchange.com/questions/152080/how-do-components-in-a-component-based-entity-system)

- [Entity Systems in C++](https://stackoverflow.com/questions/21221992/entity-systems-in-c)
- [Is my understanding of AoS vs SoA advantages/disadvantages correct?](https://stackoverflow.com/questions/40163722/is-my-understanding-of-aos-vs-soa-advantages-disadvantages-correct)

- [Nomad Game Engine: Part 4.3 — AoS vs SoA](https://medium.com/@savas/nomad-game-engine-part-4-3-aos-vs-soa-storage-5bec879aa38c)
