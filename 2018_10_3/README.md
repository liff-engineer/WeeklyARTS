# Weekly ARTS

- 动态规划一题
- Qt容器还是STL容器?
- Range-v3入门

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

## Share
