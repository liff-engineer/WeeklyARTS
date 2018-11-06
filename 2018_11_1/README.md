# Weekly ARTS

- 动态规划一题
- C++的初始化
- 展开`std::tuple`

## Algorithm [931. Minimum Falling Path Sum](https://leetcode.com/problems/minimum-falling-path-sum/)

题目要求给定矩形整数数组`A`,求出最小下落路径:下落路径可以从第一行任意元素开始,然后在每一行选择一个元素,下一个元素的列位置与上一个元素列位置偏差不能大于1.

按照之前了解的动态规划问题套路,可以看到,其子问题归纳如下:

```C++
dp[i] = dp[i-1]+std::min(A[i][j]...)
```

但是具体实现就会发现一维的`dp`是不够的,首先可以从第一行任意元素开始,如何选?其次是下一行元素选择是有限制的,因而这个可能要转换成二维`dp`才能解决:

```C++
dp[i][j]=A[i][j]+std::min(dp[i-1][j-1],dp[i-1][j],dp[i-1][j+1])
```

针对第一行初始化值为:

```C++
dp[0][j]=A[0][j];
```

最终求出最后一行`dp[n-1][0..n-1]`其中的最小值即可,完整的解决方案如下:

```C++
int minFallingPathSum(vector<vector<int>>& A) {
    auto n = A.size();
    std::vector<std::vector<int>> dp(n, std::vector<int>(n, 0));

    //dp[i][j] = std::min(dp[i-1][j-1],dp[i-1][j],dp[i-1][j+1])+v[i][j]
    //初始化dp
    for (auto j = 0ul; j < n; j++) {
        dp[0][j] = A[0][j];
    }

    for (auto i = 1ul; i < n; i++) {

        dp[i][0] = A[i][0] + std::min(dp[i - 1][0],dp[i - 1][1]);

        for (auto j = 1ul; j < n - 1; j++) {
            dp[i][j] = A[i][j] +
                std::min(std::min(
                    dp[i - 1][j - 1],
                    dp[i - 1][j]),
                    dp[i - 1][j + 1]);
        }

        if (n > 1) {
            dp[i][n - 1] = A[i][n - 1] + std::min(dp[i - 1][n - 2], dp[i - 1][n - 1]);
        }
    }

    int result = dp[n - 1][0];
    for (auto j = 1ul; j < n; j++) {
        result = std::min(dp[n-1][j],result);
    }
    return result;
}
```

时隔一个月感觉终于进入状态了,差不多能够独立解决动态规划类问题。

## Review [C++的初始化](CppInitialization.md)

C++11引入了统一初始化,为什么,会带来那些改变?

## Technique [展开`std::tuple`](ExplodingTuple.md)

如何展开`std::tuple`?又有什么作用?

## Share

## TODO

模板元编程资料

- [An introduction to C++ template programming](http://www.cs.bham.ac.uk/~hxt/2016/c-plus-plus/intro-to-templates.pdf)

- [An inspiring introduction to Template Metaprogramming](https://cdn2-ecros.pl/event/codedive/files/presentations/2017/code%20dive%202017%20-%20Milosz%20Warzecha%20-%20An%20inspiring%20introduction%20to%20template%20metaprogramming.pdf)

- [practical-c-plus-plus-metaprogramming](ftp://89.22.96.127.static.alvotech.net/docs/cs/practical-c-plus-plus-metaprogramming.pdf)

- [METAPROGRAMMING IN C++14 AND BEYOND](http://ldionne.com/accu-bay-area-meetup-03-2017/#/)

- [INSTANTIATIONS MUST GO!](https://www.yumpu.com/en/document/view/46723598/instantiations-must-go)

- Modern Template Metaprogramming:A Compendium

[P1095R0/N2289: Zero overhead deterministic failure](http://www.open-std.org/jtc1/sc22/wg14/www/docs/n2289.pdf)
