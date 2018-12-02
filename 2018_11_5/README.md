# Weekly ARTS

- 动态规划一题
- C++17模拟Python中的enumerate

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

## Technique

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

## Share

pybind11

## TODO

状态机这种东西还是得好好琢磨琢磨
[[Boost].SML: C++14 State Machine Library](https://github.com/boost-experimental/sml)

- [Copy semantics and resource management in C++](https://www.deleaker.com/blog/2018/11/20/copy-semantics-and-resource-management-in-cpp/)
- [Tiny cheatsheets for C++11/14/17](https://www.walletfox.com/course/cheatsheets_cpp.php)
- [A zero cost abstraction?](https://joshpeterson.github.io/a-zero-cost-abstraction)
- [CppCon 2018: Modern C++ Design](https://abseil.io/blog/20181129-moderncpp)
