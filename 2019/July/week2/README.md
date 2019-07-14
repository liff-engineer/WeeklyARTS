# Weekly ARTS

## Algorithm [857. Minimum Cost to Hire K Workers](https://leetcode.com/problems/minimum-cost-to-hire-k-workers/)

有`N`个员工,第`i`个员工的才能为`quality[i]`,最小薪酬预期为`wage[i]`.

现在需要雇佣`K`个员工组成一个组合.当雇佣员工时需要按照以下规则支付薪酬:

1. 每个员工需要根据与其它员工的才能比例来支付;
2. 每个员工都需要支付其最低薪酬预期.

返回满足条件情况下所需金钱成本最少的组合.

这个题目做起来真的是一头雾水,好不容易分析清楚怎么计算的,却不知道如何找出金钱成本最小的组合.查阅了 Discuss 才明白个中思路.

首先看条件`1`,要根据才能比例来支付,假设员工`i`和`j`,最终为他们支付的薪酬为`money[i]`和`money[j]`,那么关系如下:

- `quality[i]:quality[j] = money[i]:money[j]`
- `money[i]:quality[i] = money[j]:quality[j]`

假设为`i`支付了最小薪酬`wage[i]`即可满足场景,那么`money[i]=wage[i]`,而`money[j]= quality[j]*(wage[i]/quality[i])`.也就说说,这种场景下,`wage[i]/quality[i]`这个比率决定了最终结果.能够找到比率最小的场景,就是成本最小的场景.

搞清楚这个关系,就可以解决对应的问题了:

1. 计算出比率,并根据从小到大的顺序排序.
2. 遍历场景找出最小成本

由上述分析得出,在比率确定的情况下,`quality[j]`越大,成本越高.因此遍历场景时,找到组合`K`后需要抛出最大`quality`的继续遍历,最终实现如下:

```C++
double mincostToHireWorkers(std::vector<int>& quality, std::vector<int>& wage, int K) {
    auto n = quality.size();
    std::vector<std::pair<double, int>> ratio_quality_pairs;
    ratio_quality_pairs.reserve(n);
    for (auto i = 0ul; i < n; i++) {
        ratio_quality_pairs.push_back(
            std::make_pair(static_cast<double>(wage[i]) / quality[i],
                quality[i]));
    }

    std::sort(ratio_quality_pairs.begin(), ratio_quality_pairs.end());

    auto result = std::numeric_limits<double>::max();
    auto sum = 0.0;

    std::priority_queue<int> pq;
    for (auto pair : ratio_quality_pairs)
    {
        sum += pair.second;
        pq.push(pair.second);

        if (pq.size() > K) {
            sum -= pq.top();
            pq.pop();
        }

        if (pq.size() == K) {
            result = std::min(result, sum * pair.first);
        }
    }
    return result;
}
```

## Review

## Technique

## Share
