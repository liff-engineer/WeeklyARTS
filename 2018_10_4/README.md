# Weekly ARTS

- 花样多变的动态规划问题

## Algorithm [714. Best Time to Buy and Sell Stock with Transaction Fee](https://leetcode.com/problems/best-time-to-buy-and-sell-stock-with-transaction-fee)

题目是这样的,给定股票价格数组/序列`prices`,以及每次卖出时的交易费用`fee`,每次只能买1单位,必须卖出之后才能买入,求能够获得的最大收益是多少.

### 问题分析

在处于某位置时,有两种状态:手里有股票,手里没股票;而手里有股票考虑的是是否卖出,手里没股票要考虑是否买入,卖出跟买入状态是纠缠在一起的,因而不能采用之前处理dp问题定义单个dp数组来记录过程状态.

需要定义卖出收益数组和买入收益数组,卖出时的值由上次卖出和上次买入这次卖出取最大值;买入时的值由上次买入和上次卖出这次买入的最大值进行对比,也就是说:

- 本次卖出 = max(上次卖出,上次买入这次卖出)
- 本次买入 = max(上次买入,上次卖出这次买入)

### 解决方案

定义每次买入及卖出收益数组`buy`与`sell`,则可以得到

- buy[i] = std::max(buy[i-1],sell[i-1] - prices[i])
- sell[i] = std::max(sell[i-1],buy[i-1]+prices[i]-fee)

最终返回最大收益即可.

```C++
int maxProfit(vector<int>& prices, int fee) {
    std::vector<int> buy(prices.size());
    std::vector<int> sell(prices.size());

    sell[0] = 0;
    buy[0] = -prices.at(0);
    for (auto i = 1ul; i < prices.size(); i++) {
        //买入动作,上一次买入 与 上一次卖出这次买入对比
        buy[i] = std::max(buy[i - 1], sell[i - 1] - prices[i]);

        //卖出动作,上一次卖出 与 上一次买入这次卖出对比
        sell[i] = std::max(sell[i - 1], buy[i - 1] + prices[i] - fee);
    }
    return std::max(buy.back(),sell.back());
}
```

### 总结

动态规划问题从easy做到medium,本以为摸清楚套路了,玩玩没想到这种问题花样还挺多,之前easy时是一维,后来双因素编程两维,这次来了个互相纠缠,分析归纳的能力还需要加强啊。

## Review 

模板元编程资料

- [An introduction to C++ template programming](http://www.cs.bham.ac.uk/~hxt/2016/c-plus-plus/intro-to-templates.pdf)

- [An inspiring introduction to Template Metaprogramming](https://cdn2-ecros.pl/event/codedive/files/presentations/2017/code%20dive%202017%20-%20Milosz%20Warzecha%20-%20An%20inspiring%20introduction%20to%20template%20metaprogramming.pdf)

- [practical-c-plus-plus-metaprogramming](ftp://89.22.96.127.static.alvotech.net/docs/cs/practical-c-plus-plus-metaprogramming.pdf)

- [METAPROGRAMMING IN C++14 AND BEYOND](http://ldionne.com/accu-bay-area-meetup-03-2017/#/)

- [INSTANTIATIONS MUST GO!](https://www.yumpu.com/en/document/view/46723598/instantiations-must-go)

- Modern Template Metaprogramming:A Compendium

## Technique

[P1095R0/N2289: Zero overhead deterministic failure](http://www.open-std.org/jtc1/sc22/wg14/www/docs/n2289.pdf)

## Share [Inheritance vs std::variant](https://cpptruths.blogspot.com/2018/02/inheritance-vs-stdvariant-based.html)

## Share 