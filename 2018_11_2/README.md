# Weekly ARTS

- 动态规划一题
- C++中事件分发模板实现

## Algorithm [646. Maximum Length of Pair Chain](https://leetcode.com/problems/maximum-length-of-pair-chain/)

题目要求给定`n`对整数,每一对整数第一个值总是要小于第二个值,针对`(a,b)`这对整数,如果`(c,d)`中`b < c`,这样才能够连接起来.

那么给定整数对集合,最大能够链接起来的长度是多少?不必使用上所有的对,也不限定其顺序。

解决动态规划问题,首先要找出子问题,假设整数对已经被排序排过了,那么如果`dp[i]`为第`i`个整数对的最大链接长度是多少呢?

无论`dp[i]`能不能与之前的链接到一起,其作为链接中的一环,至少是`1`,如果能与之前的任何一对构成链接,那么就是之前的长度加1,也就是说：

```C++
if(v[i][0] > v[j][1]){
    dp[i] = std::max(dp[i],dp[j]+1);//i > j
}
```

因而解决思路是:

1. 从小到大排序
2. [1..n]遍历,求解`dp[i]`
3. 求出最大`dp`值

实现如下:

```C++
int findLongestChain(vector<vector<int>>& pairs) {
    //排序保证顺序
    std::sort(std::begin(pairs), std::end(pairs), 
        [](auto lhs,auto rhs)->bool {
        return lhs.at(0) < rhs.at(0);
    });
    //一维的,默认为1
    auto n = pairs.size();
    if(n <1) return 0;
    std::vector<int> dp(n, 1);
    for (auto i = 1ul; i < n; i++) {
        for (auto j = 0ul; j < i; j++) {
            if (pairs[i][0] > pairs[j][1]) {
                dp[i] = std::max(dp[i], dp[j] + 1);
            }
        }
    }
    return *std::max_element(std::begin(dp),std::end(dp));
}
```

## Review

- [Demystifying constexpr](https://blog.quasardb.net/demystifying-constexpr/)
- [constexpr ALL the Things!](https://www.youtube.com/watch?v=PJwd4JLYJJY&list=PLHTh1InhhwT6bwIpRk0ZbCA0N2p1taxd6&index=15)

## Technique [C++中事件分发模板实现](EventDispatch.md)

偶然看到的一些代码片段,事件分发在C++中竟然有这么多模板实现,语言愈发强大了.

## Share C++"专家"新特性是否"不实用"?

C++17标准已经发布了,看一看C++11、C++14、C++17的新特性,有多少是给“专家”使用的模板新特性? 对于普通开发者是否实用? 

在广大普通开发者中呼声比较高的`module`、`network`等等依然还要等待,有不少人对此表示失望,C++标准委员会的人是否居庙堂之高,已经不知道底层疾苦了?

我觉得事情并非如此,这些新特性能够给库开发者提供足够好的支持,从而影响到普通开发者,譬如`range-v3`这种,给普通开发者带来多少便利?

## TODO

- [constexpr specifier](https://en.cppreference.com/w/cpp/language/constexpr)
- [Member templates](https://en.cppreference.com/w/cpp/language/member_template#Conversion_function_templates)
- [user-defined conversion](https://en.cppreference.com/w/cpp/language/cast_operator)
- [Andrei Alexandrescu “Expect the expected”](https://www.youtube.com/watch?v=PH4WBuE1BHI)

- [C++ METAPROGRAMMING: EVOLUTIONAND FUTURE DIRECTIONS](http://www.meeting-cpp.de/tl_files/mcpp/2016/Louis%20Dionne%20-%20c++%20metaprogramming%20-%20evolution%20and%20future%20directions.pdf)

- [std::variant and the Power of Pattern Matching](https://meetingcpp.com/2018/Talks/items/std__variant_and_the_Power_of_Pattern_Matching.html)

- [Pointers to Member Functions](https://isocpp.org/wiki/faq/pointers-to-members#memfnptr-vs-fnptr-more)

- ["Alias template to avoid ugly syntax"](https://twitter.com/meetingcpp/status/1029797123502563328)

- [Pointers to members](https://en.cppreference.com/w/cpp/language/pointer#Pointers_to_data_members)
