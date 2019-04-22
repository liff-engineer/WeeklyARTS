# Weekly ARTS

- 坚持何其难

## Algorithm [376. Wiggle Subsequence](https://leetcode.com/problems/wiggle-subsequence/)

如果一组数据相邻数之差正负交替,则被称为摆动序列.第一个相邻数之差可能为正数或者负数.小于两个数的序列也被认为是摆动序列.

给定整数序列,返回是摆动序列的最长子序列长度.可以移除序列中的一些数来构成子序列,单相对顺序要保持一致.

这是一个动态规划问题,针对每个相邻位置,有以下三种情况:

- 增大
- 减小
- 持平

这里我们定义两个数组`up`和`down`,来记录每次增大/缩小时的子序列长度,这样针对这三种情况,变化如下:

- 增大: `up[i]=down[i-1]+1;down[i]=down[i-1]`
- 减小: `down[i]=up[i-1]+1;up[i]=up[i-1]`
- 持平: `down[i]=down[i-1];up[i]=up[i-1]`

最终解决方案如下:

```cpp
int wiggleMaxLength(vector<int>& nums) {
    if(nums.size()<=1) return nums.size();

    std::vector<int> up(nums.size(), 0);
    std::vector<int> down(nums.size(), 0);
    up[0] = 1;
    down[0] = 1;
    for (auto i = 1; i < nums.size(); i++)
    {
        auto diff = nums[i] - nums[i - 1];
        if (diff > 0)
        {
            up[i] = down[i - 1] + 1;
            down[i] = down[i - 1];
        }
        else if (diff < 0)
        {
            down[i] = up[i - 1] + 1;
            up[i] = up[i - 1];
        }
        else
        {
            down[i] = down[i - 1];
            up[i] = up[i - 1];
        }
    }
    return std::max(up.back(), down.back());
}
```

而考虑到每次都是使用的上一次数据,实际上不需要将`up`和`down`以数组形式保存,更节省空间的实现如下:

```c++
int wiggleMaxLength(vector<int>& nums) {
    if(nums.size()<=1) return nums.size();

    auto last_up = 1;
    auto last_down = 1;
    for (auto i = 1; i < nums.size(); i++)
    {
        auto diff = nums[i] - nums[i - 1];
        if (diff > 0)
        {
            last_up = last_down + 1;
        }
        else if (diff < 0)
        {
            last_down = last_up + 1;
        }
    }
    return std::max(last_up, last_down);
}
```

## Review

## Technique

## Share 坚持何其难

周末同事问我,陈皓的那个专栏活动还在坚持么,我说是,只不过现在拖延得厉害,经常是拖了快一周才完成.

从去年 6 月份开始到现在,大部分 ARTS 都是拖到下周完成,只不过人的惰性实在是厉害,从以前只拖延到下周一,到现在能直接拖整整一周.一直在跟自己做斗争......

反省一下,为什么拖延越来越严重?

- 没有足够的"奖励"

  之前拖延多多少少还是因为有事情耽搁了,到后来纯粹是傻坐着也不愿意把它完成;学习是逆人性的,如果没有对应的"奖励系统",为了坚持而坚持,最终自己都会怀疑这么做是为什么.

- 没有整体的规划

  部分内容的选择犹豫不决,一拖再拖;即使有命题也出于个人兴趣原因,还是按照自己的想法去做.

应该如何去做,去克服自己的惰性?

- 首先是确定目标,ARTS 是一种学习的方式,不是目的,不要舍本逐末;
- 然后是指定计划,将目标分解为小目标,逐步完成;
- 之后是将目标拆解到对应的 A、R、T、S;
- 需要将这些和自己的工作结合起来;
- 多多交流和分享.

## TODO

- [Value categories, and references to them](https://docs.microsoft.com/en-us/windows/uwp/cpp-and-winrt-apis/cpp-value-categories)
- [EntityX - A fast, type-safe C++ Entity-Component system](https://github.com/alecthomas/entityx)
- [Refactoring Game Entities with Components](http://cowboyprogramming.com/2007/01/05/evolve-your-heirachy/)
- [Data Oriented Design Resources](https://github.com/dbartolini/data-oriented-design)

- [ECS Game Engine Design](https://pdfs.semanticscholar.org/829b/9107c32bb20965400d22a6dad14f56b9b7b5.pdf)
- [Game Programming Patterns](http://gameprogrammingpatterns.com/contents.html)
