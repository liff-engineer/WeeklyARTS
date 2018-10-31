# Weekly ARTS

- 花样多变的动态规划问题
- 继承与变体
- The Named Parameter Idiom
- 年轻人,到"前线"去

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

## Review [继承与变体](InheritanceAndVariant.md)

C++17带来了`std::variant`,给一些场景下替代继承写法提供了选择.

## Technique [The Named Parameter Idiom](NamedParameterIdiom.md)

## Share 年轻人,到"前线"去

项目组的实习生拿到了公司的offer,问我去哪个部门比较有前途,于其跟他聊了聊,顺便也记录下我对这些事情的看法。

先说结论,我认为,年轻人应该到"前线"去,去接触用户,去感受外面的世界。

做软件开发的核心价值是什么?是解决用户的问题,为客户提供价值.很多开发人员不愿意写业务代码,就希望去平台,搞算法,大数据,人工智能区块链,把自己埋头到具体技术上,两耳不闻窗外事一心只读圣贤书.

为什么开发人员三十多岁就危机了?你的价值在哪里?为什么没办法积累下来?为什么出了新技术你反应不够迅速就被淘汰了?产品有个讲法叫护城河,你有没有自己的护城河?

是的,你苦心钻研某某技术,终于成为大牛,确实是一个方向,问题是这么多公司,有多少需要这些大牛?

能不能换个思路,别把自己那些技术搞得那么金贵,各行各业那么多需求,很多时候不是说需要多么牛多么高深的技术,需要的是站在用户的角度考虑,为他们提供价值.

创新不是空中楼阁,很多都是来源于现实问题,你接触到这些问题才能逼迫你去成长去创新,去提升自己,建立护城河.

如果你看到危机文,心中发慌,担心眼前,担心未来,不如琢磨下,你未来能够提供什么价值,让自己不至于拼不过后来的年轻人。