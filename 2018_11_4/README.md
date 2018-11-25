# Weekly ARTS

- 模板元编程的新面貌
- 模板元编程应用之结构体与数据库记录直接映射

## Algorithm [486. Predict the Winner](https://leetcode.com/problems/predict-the-winner/)

这个题目和[977. Stone Game](https://leetcode.com/problems/stone-game/)非常相似,问题是这样的,给定一组非负整数,玩家1和玩家2轮流从数组头部或者尾部拿走一个数字,直到这组数字全部被挑选完,这时玩家中数字之和最大的获胜.注意题目还要求如果两个玩家数字之和相同则玩家1获胜.那么给定一组数字,判断玩家1是否能够获胜.

假设经过选择之后,轮到玩家1选择,当前的数组为`nums[i..j]`,当前的解-即玩家1超过玩家2的数字和`dp[i][j]`,那么玩家1有两种选择:

1. 拿`nums[i]`,这时结果为`nums[i]-dp[i+1][j]`
2. 拿`nums[j]`,这时结果为`nums[j]-dp[i][j-1]`

如果玩家1要获胜,需要拿到当前结果最大值`max(nums[i]-dp[i+1][j],nums[j]-dp[i][j-1])`.

实现如下:

```C++
bool PredictTheWinner(vector<int>& nums) {
    auto n = nums.size();
    std::vector<std::vector<int>> dp(n, std::vector<int>(n, 0));
    for (int i = 0; i < n; i++) dp[i][i] = nums[i];
    for (int j = 1; j < n; j++){
        for (int i = 0; i < n - j; i++){
            dp[i][i + j] = std::max(nums[i] - dp[i + 1][i + j], nums[i + j] - dp[i][i + j - 1]);
        }
    }
    return dp[0][n - 1] >= 0;
}
```

## Review [模板元编程的新面貌](tmp.md)

## Technique [模板元编程应用之结构体与数据库记录直接映射](StructVSDBInterface.md)

通常数据库会被拆分成表、字段、记录等,而在应用程序中,经常会将其转换为结构体,来表达业务模型.

而使用结构体对数据库执行读写操作的代码是重复性非常高的,能否使用模板元编程技术自动完成?

## Share 编程语言对软件设计能有什么样的影响?

最近在准备年终的专题,探讨现代C++对开发带来的改变,然后把整体脉络梳理了一下,我提出这样的结构和我的“导师”过了一遍:

1. 表达式层级代码书写
2. 函数等实现表意
3. 类等组织形式
4. 设计模式等
5. 软件设计思路

内容导师表示认可,但是过程中导师一再提及要从软件设计角度来实现方案,而不是利用语言特性去做.这也引发了我的一些思考,编程语言对软件设计能够带来什么样的影响? 设计模式等很多是从面向对象的角度来进行软件设计,那么如果用C++,或者其他编程语言也要遵循这些设计模式,或者说对设计原则进行考虑么?

编程语言的一些与众不同的特性是否值得我们付出精力去研究去实践? 还是说应该站在“更高”的维度去思考软件的设计与实现?

针对设计模式中的监听者模式,相较传统的OO实现,Qt的信号与槽相对来讲很有优势,更何况有C++的模板特性加持,这就和普通的设计有不少区别;C++语言特性支持了内嵌的DSL,使得可以直接编码书写状态转换表来实现状态机,又和常规的OO实现有非常多不同,那么需要付出精力去学习推广和应用么?还是说用传统的设计模式实现?

STL本身的设计和面向对象的就不一样,还有functional programming,采用不同的编程语言应该会影响到对应软件的设计和实现吧?还是说广大开发习惯用Java,用OO,那就把C++代码也用OO实现?

应当采用什么样的思维方式去看待编程语言和软件设计,以及如何实践,这是个值得思考的问题。

## TODO

- [C++ Lambdas aren’t magic, part 1](https://medium.com/@winwardo/c-lambdas-arent-magic-part-1-b56df2d92ad2)
- [C++ Lambdas aren’t magic, part 2](https://medium.com/@winwardo/c-lambdas-arent-magic-part-2-ce0b48934809)
- [type_traits, SFINAE, and Concepts](https://kapows.github.io/posts/type_traits-sfinae-concepts/)
- [std::experimental::is_detected](https://en.cppreference.com/w/cpp/experimental/is_detected)
- [Inline Namespaces 101](https://foonathan.net/blog/2018/11/22/inline-namespaces.html)
- [Stop Teaching C++](https://ibob.github.io/blog/2018/11/22/stop-teaching-cpp/)
- [How I format my C++ papers](https://mpark.github.io/programming/2018/11/16/how-i-format-my-cpp-papers/)