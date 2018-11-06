# Weekly ARTS

- 动态规划一题
- C++的初始化
- 展开`std::tuple`
- 如何提高新版本C++的使用率?为什么会有这个问题

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

## Share [如何提高新版本C++的使用率?为什么会有这个问题](https://www.reddit.com/r/cpp/comments/9uf0hg/askcpp_how_are_we_going_to_improve_the_adoption/)

用C++的朋友,你现在在使用C++98、C++03、C++11、C++14、C++17还是C++20?

看到了reddit上的讨论,在公司使用新的C++标准版本如此艰辛,不由得想起自己现在的境况:现在工作中依然在使用Visual Studio 2010,也就是带有部分C++11特性的C++03版本,而同事的代码还处在C++98时代,掐指一算这都2018年了,用20年前的标准写代码,还有部分同事用的是带类的C......而我个人搞的项目使用的是C++17.

你说能有啥变化?且听我给你说说:

- 统一初始化
- 智能指针
- `Rule of Zero`
- `std::any`、`std::optional`、`std::variant`
- SFINAE
- `enum class`
- `lambda`
- 模板元编程
- `std::file_system`
- `std::thread`
- `range-for`
- `AAA - Almost always auto`
- 可变参数模板
- 结构体绑定
- ......

新版本的C++在表达能力、安全性、性能方面均能够得到提升。

可是你在工作中为什么不能使用? 我觉得排除外部因素,可能有以下原因:

1. 没能领会到现代C++的魅力
2. 即使C++向后兼容,也不能支持"你们"无缝升级

而第二个原因是需要好好反思的,为什么语言能够向后兼容,切换个语言版本却那么艰辛?是不是自动化不够?导致升级编译器担惊受怕,写得破代码新版编译器能够识别出更多潜在错误导致处理起来比较繁琐?

很多C++使用者耗费了大量时间去钻研奇技淫巧,而不能好好地用一用C++标准委员会付出那么多时间和精力为开发者提供的更好的C++语言,然后再出去说C++太复杂,学起来太难,要换别的语言?

> C++ is a horrible language. It's made more horrible by the fact that a lot of substandard programmers use it, to the point where it's much much easier to generate total and utter crap with it.

现在C++在向好的方向发展,而你呢?

## TODO

模板元编程资料

- [An introduction to C++ template programming](http://www.cs.bham.ac.uk/~hxt/2016/c-plus-plus/intro-to-templates.pdf)

- [An inspiring introduction to Template Metaprogramming](https://cdn2-ecros.pl/event/codedive/files/presentations/2017/code%20dive%202017%20-%20Milosz%20Warzecha%20-%20An%20inspiring%20introduction%20to%20template%20metaprogramming.pdf)

- [practical-c-plus-plus-metaprogramming](ftp://89.22.96.127.static.alvotech.net/docs/cs/practical-c-plus-plus-metaprogramming.pdf)

- [METAPROGRAMMING IN C++14 AND BEYOND](http://ldionne.com/accu-bay-area-meetup-03-2017/#/)

- [INSTANTIATIONS MUST GO!](https://www.yumpu.com/en/document/view/46723598/instantiations-must-go)

- Modern Template Metaprogramming:A Compendium

[P1095R0/N2289: Zero overhead deterministic failure](http://www.open-std.org/jtc1/sc22/wg14/www/docs/n2289.pdf)
