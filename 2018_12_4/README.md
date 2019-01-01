# Weekly ARTS

- `Concepts`简介
- Flip Model 设计模式
- 关于`Standard Ranges`引发的讨论

## Algorithm [309. Best Time to Buy and Sell Stock with Cooldown](https://leetcode.com/problems/best-time-to-buy-and-sell-stock-with-cooldown/)

题目要求,给定一个股票的价格序列,来计算出最大收益,要求同时只能买入或者卖出,当卖出股票时第二天不能再买入.

这个题目是要找出各种状态下的关系,这里分三种:买入,卖出,持有(不能买卖).

- `sell`
- `buy`
- `hold`

各种状态下的关系为:

- `sell`卖出

要么不卖-`sell[i]=sell[i-1]`,要么卖出-`sell[i]=buy[i-1]+price`

- `buy`买入

要么不买-`buy[i]=buy[i-1]`,要么买入-`buy[i]=hold[i-1]-price`

- `hold`持有

上次卖出、买入、持有三种情况`hold[i]=max(buy[i-1],sell[i-1],hold[i-1])`

也就是说:

```C++
sell[i]=std::max(buy[i-1]+prices[i],sell[i-1]);
buy[i]=std::max(hold[i-1]-prices[i],buy[i-1]);
hold[i]=std::max(buy[i-1],std::max(sell[i-1],hold[i-1]));
```

既然要找最大值,`hold[i]`不需要与`buy[i-1]`比较,也就是说`hold[i]=std::max(sell[i-1],hold[i-1])`.而且`hold[i]<=sell[i]`,进一步化简为`hold[i]=sell[i-1]`.

于是变成了:

```C++
buy[i]=std::max(sell[i-2]-prices[i],buy[i-1]);
sell[i]=std::max(buy[i-1]+prices[i],sell[i-1]);
```

每一步运算均和上一步有关系,可以化简为:

```C++
buy = std::max(last_sell-price,last_buy);
sell = std::max(last_buy+price,last_sell);
```

实现如下:

```C++
int maxProfit(vector<int>& prices) {
    int buy = std::numeric_limits<int>::min();
    int sell = 0;
    int last_buy = buy;
    int last_sell = 0;

    for (auto price : prices) {
        last_buy = buy;
        buy = std::max(last_sell-price,last_buy);
        last_sell = sell;
        sell = std::max(last_buy + price, last_sell);
    }
    return sell;
}
```

## Review [`Concepts`简介](concepts.md)

## Technique [Flip Model 设计模式](FlipModel.md)

## Share 关于`Standard Ranges`引发的讨论

[range-v3](https://github.com/ericniebler/range-v3)的作者在 2018 年的 12 月 4 日发布了一篇博文[Standard Ranges](http://ericniebler.com/2018/12/05/standard-ranges/),然后经过两三周的发酵,酿成了一场大范围的讨论,详见:

- 主要"战场":["Modern" C++ Lamentations](http://aras-p.info/blog/2018/12/28/Modern-C-Lamentations/)及[twitter](https://twitter.com/aras_p/status/1078682464602726400)
- [Reddit 讨论](https://www.reddit.com/r/programming/comments/aac4hg/modern_c_lamentations/)
- [Hacker News 讨论](https://news.ycombinator.com/item?id=18777735)
- 还有知乎如何评价体[如何评价 "Modern" C++ Lamentations ？](https://www.zhihu.com/question/307348605/answer/562411756)

由于[Standard Ranges](http://ericniebler.com/2018/12/05/standard-ranges/)这篇博文刚一发出我就研读了两遍,没有在 C++社群上看到对其的大规模讨论,看到 InfoQ 的推送也在微信群里"狡辩"了几句,直到假期回来才发现 Twitter 上讨论"疯了".

所以,争论的焦点在哪里?

1. 写法
1. 编译时间
1. 非优化版本运行性能

源头是写法,C++标准委员会倾向于不增加语言特性,而是以库形式实现.而`range-v3`的作者在文中所举的示例确实很难懂,比较糟糕.但是后续的焦点不在这里.

由于 C++语言以及模板实现机制的原因,编译时间对于很多稍大点儿的项目都是比较不能接受的.即使是预编译头、并行编译、联机编译这些手段都加上,编译时间也比较可怕.

然后是非优化版本运行性能,C++号称`zero-overhead abstraction`,基本上是内敛等各种优化手段,需要开启编译器优化,而针对调试版本或者非优化版本,与优化版本相比,运行性能实在是低到可怕,这严重影响了软件调试和 BUG 分析等,在我实际工作之中,哪怕工作环境也都是拿`Release`版本进行调试.

争论的问题确实存在,也确实如争论文章所言,C++在这些方面的表现实在是糟糕.更别说语言复杂度了.

所以,我对这个事情的看法是,短期内不会发生改变,你可以"弃坑",也可以采用 C++的子集来实现你的应用.

而对于那些"被迫"使用 C++的开发者,我对这个事情有不同看法:语言的设计有其考量和平衡,我们选择和使用语言也有其目的和侧重点.

关注的重点是什么?能不能达到目的.

有问题?可以得到解决或者缓解.譬如 Python,性能为人诟病,依然挡不住大家喜爱,性能不够 C/C++来凑.

没必要去唱衰,甚至于义愤填膺.
