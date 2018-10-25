# Weekly ARTS

- 动态规划一题
- Qt容器还是STL容器?
- Range-v3入门
- 学了那么多道理,却依然写不好代码

## Algorithm [712. Minimum ASCII Delete Sum for Two Strings](https://leetcode.com/problems/minimum-ascii-delete-sum-for-two-strings)

之前刷题把动态规划easy的刷完了,感觉自己已经摸清楚套路了,万万没想到试了两个中等难度的题目,完全找不出来思路......

譬如这个题目,给定两个字符串`s1`、`s2`,从两个字符串中不断删除字符,最终使得字符串相同,求这种情况下删除字符之和最小的方案。

动态规划核心在于找到子问题,子问题在哪里? 思索良久不得而知,于是看了题目的提示:

> Let dp(i, j) be the answer for inputs s1[i:] and s2[j:].

又看了下上周做的题目,查阅了上周的解决思路,恍然大悟,原来套路在这里！

- 首先假定dp(i,j)为字符串s1(0..i)和s2(0..j)的答案
- 这时就需要找到如何根据s1(0..i)、s2(0..j)、dp(0..i,0..j)求出dp(i,j)的方法
- 最终结果就是dp(s1.size(),s2.size())

那么这个关系是怎样的呢?

- 如果`s1[i-1] == s2[j-1]`,也就是说上一个字符是一样的,那就不需要从字符串中删除掉,也就是说`dp[i][j]`与`dp[i-1][j-1]`一样!
- 如果`s1[i-1] != s2[j-1]`,那么要么删除`s1`的上一个字符,要么删除`s2`的上一个字符,也就是说取代价最小的:
    `std::min(s1[i-1]+dp[i-1][j],s2[j-1]+dp[i][j-1])`

从`i=0`和`j=0`来初始化`dp`,之后就可以按照顺序求出所有的`dp`了.

实现如下:

```C++
int minimumDeleteSum(string s1, string s2) {
    auto m = s1.size();
    auto n = s2.size();

    std::vector<std::vector<int>> dp(m+1, std::vector<int>(n+1, 0));
    //i == 0时,只能不断地删除s2的j-1位置字符
    for (auto j = 1ul; j <= n; j++) {
        dp[0][j] = dp[0][j - 1] + s2[j - 1];
    }

    for (auto i = 1ul; i <= m; i++) {
        //j == 0时,只能不断地删除s1的i-1位置字符串来达成目标
        dp[i][0] = dp[i - 1][0] + s1[i - 1];
        for (auto j = 1ul; j <= n; j++) {
            if (s1[i - 1] == s2[j - 1]) {//相同时,无需删除任何字符
                dp[i][j] = dp[i - 1][j - 1];
            }
            else
            {
                //不相同时删除代价最小的
                dp[i][j] = std::min(dp[i - 1][j] + s1[i - 1], dp[i][j-1] + s2[j - 1]);
            }
        }
    }
    return dp[m][n];
}
```

看来动态规划的套路是这样的,以前easy是因为只有一维,现在中等难度的是二维,不过背后思路还是一样,关键是规律/子问题的界定。

## Review [探索Qt容器](QtContainers.md)

Qt容器还是STL容器?

## Technique [Range-v3 入门](RangeV3.md)

很早之前听说过`Range-v3`的大名,也粗略了解过,最近看到一篇文章,才算入了门,确实相当有吸引力!

## Share 学了那么多道理,却依然写不好代码

最近在为某个业务场景开发一套解决方案,基本上是用到公司和一些第三方库重新开发这套工具,连续两个月高强度编码,这周才完成原型,虽然演示完惊艳了一把,过程中有很多感触.

方案设计和实现过程中不断地权衡、调整,基本上步步坎,通常写了一部分,后面又是大规模调整,有一些实现方案也没有设计好,不足以支持需求,感觉后续还需要大量的调整.

在工作的这些年中,读了很多书,学到了很多内容,大部分是技术上的,还有很多是关于代码品味,方案设计等等,可实际应用时却总是货不对板,不知道是否时必经之路。

举几个简单的例子：

- RAII的应用

为了避免管理内存,现在都开始使用智能指针,或者RAII了,而实际上这个并不是一概而论的,因为涉及到一个析构时机的问题,譬如如下代码:

```C++
class vp_editor_hub:public vp_hub
{
public:
    vp_editor_hub();
    ~vp_editor_hub();

    vp_context* context() override;
    vp_graph<>* graph()  override;
    vp_editor_support* editor_support() override;

    vp_editor_plugin_manager* editor_support_manager();
private:
    //vp_graph<>         m_graph;
    std::unique_ptr<vp_graph<>> m_graph;//注意有一些内容是插件中创建的,所以正确析构要保证插件依然加载中
    std::unique_ptr<vpu_context> m_context;

    //这两个插件加载模块是否要合并
    std::unique_ptr<vp_editor_plugin_manager> m_editor_support;
};
```

看起来岁月静好,不用管析构之类的,但是由于`vp_graph<>`中的内容是动态链接库里构建的,自动释放时如果动态链接库被先卸载,就会在析构时崩溃,导致需要保证`vp_graph<>`等先行析构,因而迫不得已,又把析构函数实现了:

```C++
vp_editor_hub::~vp_editor_hub()
{
    m_graph.reset(nullptr);
    m_context.reset(nullptr);
}
```

- 用Qt实现UI

Qt实现UI时继承自QObject的话,生命周期可以交由Qt自身机制保证,也就是说new了之后不用管,一旦把RAII和QObject混合到一起,鬼知道什么时候析构?如果有顺序要求,崩溃了都不知道如何处理;不同的库使用不同的策略,用起来非常不习惯。

- 模板的应用

本来计划将基础库实现成纯模板,但是这套工具采用的是动态插件机制,模板和dll之间怎么用怎么尴尬,导致模板用起来脱裤子放屁.

- std::option及std::variant等

C++17带来了一系列词汇类型,可以用来表达一些可选、变体等内容,但是真实使用时,非常尴尬,写起来冗余很多,不禁怀疑是自己用错了还是不适用于这些场合。

- 设计模式

套用了一些设计模式,但是感觉并不好,使用起来蹩手蹩脚,却没有更好的方法。

个人反思了一下,可能还是经历得太少,思考得不够,路漫漫其修远兮......