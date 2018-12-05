# Weekly ARTS

- C++17模拟Python中的enumerate
- C++ & Python - pybind11 入门
- 人生苦短我还用C++?

## Algorithm [62. Unique Paths](https://leetcode.com/problems/unique-paths/)

有一个`m`*`n`的网格,从左上角移动到右下角,每次只能向下或者向右移动,那么最多有多少种可能的行走路径?

由于只能向下或者向右移动,那么走到特定位置的可能情况是上两个情况的和,假设解决结果为`dp`,在位置`dp[i][j]`的可能行走路径为:

```C++
dp[i][j]=dp[i-1]dp[j]+dp[i][j-1]
```

而在第一行和第一列,`dp[0][0..n]`和`dp[0..m][0]`均为`1`.

实现如下:

```C++
int uniquePaths(int m, int n) {
    std::vector<std::vector<int>> dp(m, std::vector<int>(n, 1));
    //dp[i][j] = dp[i-1]dp[j] + dp[i][j-1]
    for (auto j = 1; j < n; j++) {
        for (auto i = 1; i < m; i++) {
            dp[i][j] = dp[i - 1][j] + dp[i][j - 1];
        }
    }
    return dp[m-1][n-1];
}
```

## Review [C++17模拟Python中的enumerate](enumerate.md)

一篇介绍如何模拟Python中enumerate的文章.

## Technique [C++ & Python - pybind11 入门](pybind11.md)

C++和Python,鱼和熊掌可以兼得.

## Share 人生苦短我还用C++?

最近刚完成了今年的专题,一两百页的PPT《现代C++为开发带来的改变》.从代码书写讲到表达意图,然后是代码的组织结构,设计模式,一直到对思维方式的影响,本以为写完可以放松一下,可实际并非如此.

在最近两三年,我开始深度关注C++语言,每天接受大量的讯息.今年借着公司升级编译器的契机,开始更进一步地思考,能够为现在项目组的软件开发提供什么更好的思路和实践.

在这个过程中我学到非常多的知识,更多的感觉是危机,作为工作近10年的老程序员,越来越意识到一个问题,C++是真的难,这个难不是说C++语言本身,是C++语言所处的环境,导致我们被迫从难到不正常的路径去掌握新的语言特性,实践出更好的应用.

过程中有人问我怎么学C++,思考了一下,我也不知道啊,不知道怎么学会的,也说不清楚是哪本书,哪些教程,哪些文章,抑或项目中的实践促使我掌握了这门编程语言,甚至说我总结不出来一个学习路径来给别人提供建议.

在给PPT列完提纲之后,曾经找专题导师聊过这个,他希望我能够展现出来完全新的一门C++语言,来“改变”现在各个项目组对C++的认知,我觉得这份PPT确实能够做到一点点,但是问题在于,它和现在的以OO为主流的软件设计方式不太一样,利用了语言的特点和特性,来展示不同的设计和实现方法.能有多少人能够吸收,能不能得到实践的机会,都是疑问,我都在怀疑是不是浪费了时间.

人生苦短我还用C++? 或许该换个python/go,抑或提升下思考层次了.

## TODO

状态机这种东西还是得好好琢磨琢磨
[[Boost].SML: C++14 State Machine Library](https://github.com/boost-experimental/sml)

C++17 fold expression的应用一则,需要学习学习这个特性.

```C++
#include <cstdlib>
#include <type_traits>

template<typename T, typename... Ts>
constexpr size_t get_index_in_pack() {
    // Iterate through the parameter pack until we find a matching type,
    // incrementing idx for each non-match. Short-circuiting of operator ||
    // on !++idx (always false) takes care of aborting iteration at the right
    // point
    size_t idx = 0;
    (void)((std::is_same_v<T, Ts> ? true : !++idx) || ...);
    return idx;
}

static_assert(get_index_in_pack<char,   char, size_t, int>() == 0);
static_assert(get_index_in_pack<size_t, char, size_t, int>() == 1);
static_assert(get_index_in_pack<int,    char, size_t, int>() == 2);
```

- [Copy semantics and resource management in C++](https://www.deleaker.com/blog/2018/11/20/copy-semantics-and-resource-management-in-cpp/)
- [Tiny cheatsheets for C++11/14/17](https://www.walletfox.com/course/cheatsheets_cpp.php)
- [A zero cost abstraction?](https://joshpeterson.github.io/a-zero-cost-abstraction)
- [CppCon 2018: Modern C++ Design](https://abseil.io/blog/20181129-moderncpp)
