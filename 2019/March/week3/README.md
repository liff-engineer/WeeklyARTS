# Weekly ARTS

- Thanks for the memory (allocator)
- Python"原生"包构建实现解析
- 工欲善其事必先利其器

## Algorithm [209. Minimum Size Subarray Sum](https://leetcode.com/problems/minimum-size-subarray-sum/)

题目要求,给定正整数数组`nums`,以及正整数`s`,找出最短的连续子数组,使得子数组之和大于等于`s`.如果不存在的范围`0`.

因为要查找子数组,那么只需要记住子数组的开头即可,在查找过程中一直计算之前的子数组之和,如果和超过`s`,则记录下当前子数组,然后把子数组的开头向后推,从而创建新的子数组.

解决思路如下：

1. 建立子数组
2. 求和直到满足条件

基本上就是步骤`1`和`2`循环操作.

```C++
int minSubArrayLen(int s, vector<int>& nums) {
    if (nums.size() < 1)
        return 0;
    std::size_t last_idx = 0;
    int last = 0;
    int result = nums.size() + 1; //初始化为个数+1
    for (auto i = 0ul; i < nums.size(); i++)
    {
        last += nums.at(i);
        if (last < s)
            continue;
        result = std::min(result, static_cast<int>(i - last_idx));
        while (last >= s) //移动last_idx保证last >= s
        {
            last -= nums.at(last_idx++);
        }
        result = std::min(result, static_cast<int>(i - last_idx + 1));
    }
    return (result == nums.size() + 1) ? 0 : (result + 1);
}
```

这个题目需要注意几个点:

1. 单个数值就满足条件的场景处理
2. 连续时返回的个数是索引之差加`1`

## Review [Thanks for the memory (allocator)](allocator.md)

## Technique [Python"原生"包构建实现解析](python_native_pacakge_impl.md)

## Share 工欲善其事必先利其器

连续两个周末终于把买的一部分家具安装完了,趁着博世搞活动买了手电钻和冲击钻.发现工具与工具之间差距也能这么大.想到最近在项目中推行`Modern CMake`,用起来也是很畅快,真的是感慨万千.

从之前搞嵌入式开始到现在,使用过形形色色的`IDE`.譬如 UltraEdit,Source Insight,Eclipse,Visual Studio 等等,在某些时期甚至是这些工具的忠实拥趸.现在回想起来,无疑是有点浪费生命.听人提起过做事情的必然复杂度和偶然复杂度.从这个视角看,使用合适的工具就是降低偶然复杂度,使得我们更聚焦于有价值的工作,而不是浪费时间到无意义的事情上.

这个`器`不仅仅是工具,还有方法,譬如波利亚的《怎样解题》,我工作之后才看到有这样的书籍,来讲述解决问题的方法.而会想起应该读这本书的中学时代,真的是凭天分和努力,老师并没有教给我们这些方法,全凭题海战术硬生生熬过 8 年的中学时光. 如果那时候能够碰见更好的老师、或者有幸能读到这样的书籍,或许会变得不一样吧.

而工作中呢,我们的`器`是不是也很糟糕? 公司内部开发的平台/库,没有文档,全凭各种问别人和自己摸索;而自己做得甚至更糟糕,耗费了大量精力在不必要的事情上,内耗严重.新的工具用不上,9102 年了还在用十几年前的 C++标准等等,一声叹息......

"种一棵树最好的时间是十年前,其次是现在".
