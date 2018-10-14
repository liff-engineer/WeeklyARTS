# Weekly ARTS

- 是什么使得C++超越带类的C?
- Qt与OpenGL
- 关于教程类技术文章的一些看法

## Algorithm [977. Stone Game](https://leetcode.com/problems/stone-game/)

这是个很有意思的题目,给定个数为偶数的正整数数组`piles`,Alex和Lee两个人,Alex开始从首尾挑选数字,最终手上数字之和大的获胜,题目要求仅当Alex获胜时返回`True`.

### 当前条件下Alex必赢

由于有偶数个正整数,也就是说Alex拿一半,Lee拿另外一半,Alex只要保证每次拿的都是最大的,即可赢得胜利,反正个数一样,而且Alex先拿,一定能拿到最大的。这大概就是为什么这道题目133个`like`、242个`dislike`的原因吧。

### 动态规划的解法

动态规划的核心在于分解出子问题,那么针对这个题目,子问题是什么?在每个步骤Alex如何选择能决定其结果。

假设经过选择后当前序列为`piles[i..j]`,而当前解为`dp[i][j]`,那么有两种拿法

1. Alex拿`piles[i]`,而这时结果为`piles[i]-dp[i+1][j]`
2. Alex拿`piles[j]`,这时的结果为`piles[j]-dp[i][j-1]`

Alex如果要获胜,需要拿到当前结果最大值,就是`max(piles[i]-dp[i+1][j],piles[j]-dp[i][j-1])`

```Cpp
dp[i][j]=std::max(piles[i]-dp[i+1][j],piles[j]-dp[i][j-1])
```

解决方案为:

```C++
bool stoneGame(vector<int>& piles) {
    auto n = piles.size();
    std::vector<std::vector<int>> dp(n, std::vector<int>(n, 0));
    for (int i = 0; i < n; i++) dp[i][i] = p[i];
    for (int j = 1; j < n; d++){
        for (int i = 0; i < n - j; i++){
            dp[i][i + j] = std::max(piles[i] - dp[i + 1][i + j], piles[i + j] - dp[i][i + j - 1]);
        }
    }
    return dp[0][n - 1] > 0;
}
```

## Review [是什么使得C++超越带类的C?](https://www.reddit.com/r/cpp/comments/9k82rx/key_features_that_make_c_c_with_classes/)

这个是`Reddit`上的一个讨论,在十几天前就看到了,没看完,一直没关电脑,今天把这些C++特性总结一下,看看自己是不是在用带类的C。

- RAII
- 模板`Templates`、泛型编程`Generic programming`
- lambda
- iterator抽象
- 类型系统/类型安全
- 值语义`Value sematics`
- constexpr
- 异常
- auto
- alias
- decltype
- STL
- 智能指针
- 所有权转移`ownershit transfer`
- move语义`move semantics`
- 词汇类型`vocabulary types`
- 命名空间

## Technique [Qt与OpenGL介绍](QtOpenGL101.md)

关于在Qt中使用`OpenGL`的一些介绍。

## Share 关于教程类技术文章的一些看法

最近在用`Qt`和`OpenGL`实现简单的`3DViewer`,整整一周多时间都卡在实现摄像机上,用Google英文中文搜索了很多,也看了很多源码,发现教程类技术文章存在着一些问题。

首先,内容过时严重,`OpenGL`现在已经到`OpenGL 4.6`,而大多数`OpenGL`相关教程都相对老旧,使用的都是`OpenGL 3.0`之前的内容,本来就是看教程,基础不够,看起来一头雾水。

其次,部分内容没有讲透,或者没有标明使用场景,在实现摄像机的过程中,基本上教程把概念讲讲,然后使用某个库,写一些代码样例,这样算结束了;实际上只是覆盖了这种场景,学习者跟着学习,抄了编代码,以为自己懂了,一旦切换下场景就懵了,功力不深直接走了弯路。

然后,对受众需有所要求,教程有其适用场景,并不是都适合初学者学习,对初学者等有一些要求需要明确,有些内容有可能需要先读读书建立概念,这个不能省。

当然,看起来确实吹毛求疵了,毕竟不花钱学知识,我从中体会到的是,写文章也是技术活,要考虑到很多方面,需要多多练习。