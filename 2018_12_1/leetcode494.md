# [494. Target Sum](https://leetcode.com/problems/target-sum/)

## 题目要求

给定正整数数组`nums`,以及一个目标整数`S`,针对数组`nums`里的每个整数,可以相加也可以相减,求出通过`nums`各个整数相加、相减得到结果`S`的方式有多少种?

## 思考

首先题目是一个动态规划问题,那么子问题到底在哪里?如果把方法的个数定义为`dp`,那么`dp[i]`和`dp[i+1]`有什么关系,要知道每个`dp`对应了`n`个可能值,再加上`nums[i]`的相加、相减两种情况可能指又会乘以2,完全想不明白子问题在哪里.那么就先看最直接的解决办法吧。

## 第一次尝试

起始值是`-S`,针对每个数有加减两种情况,假设每一个数字加减会开两个分支,过程中记录下这所有情况,最终统计结果中`0`的个数.

```C++
int find_target_sum_ways(std::vector<int> nums, int S)
{
    std::vector<int> targets;
    targets.push_back(-S);
    for (auto v : nums) {
        //分支1
        for (auto& t : targets) {
            t += v;
        }
        //分支2
        auto size = targets.size();
        targets.resize(size * 2);
        for (auto i = 0ul; i < size; i++) {
            targets[i + size] = targets[i] - 2*v;
        }
    }
    return std::count(std::begin(targets), std::end(targets), 0);
}
```

提交后提示申请了太多内存,确实如此,有多少个数,就是`2`的几次方,这里最多20个数,要申请太多内存了.

## 第二次尝试

如何减少内存占用?我想到的办法是在过程中移除注定无法继续的分支,譬如后续的数字之和为10,如果这时的和大于10或者小于-10,就会无法达成最终和为0的结果.因而可以将数字先从大到小排序,然后在过程中移除无法继续的分支,从而减少内存占用:

```C++
int findTargetSumWays(vector<int>& nums, int S) {
    auto numbers = nums;
    std::sort(numbers.begin(), numbers.end(), std::greater<int>());

    std::vector<int> targets;
    targets.push_back(-S);

    int last_n = numbers.size();

    auto verify = [](int t, int limit)->bool {
        return abs(t) <= limit;
    };

    for (auto v : numbers) {
        //值必须在这个limit上,否则无法达到0
        auto limit = v * last_n;
        last_n--;
        targets.erase(std::remove_if(targets.begin(), targets.end(),
            [&](auto t) { return !verify(t, limit); }), 
            targets.end());

        //分支1
        for (auto& t : targets) {
            t += v;
        }
        //分支2
        auto size = targets.size();
        targets.resize(size * 2);
        for (auto i = 0ul; i < size; i++) {
            targets[i + size] = targets[i] - 2 * v;
        }
    }
    return std::count(std::begin(targets), std::end(targets), 0);
}
```

提交之后确实通过了,但是只是好于40%的解决方案,那么意味着或者说从开始注定了这不是合适的解决方案.

## 合适的解决方案

百思不得其解,即使看了代码之后也完全摸不清楚实现的思路,于是看了下Discuss,发现自己不适合搞算法啊...... 竟然思路是这样的.

先把问题化简了看,假设给定的这组数组是要拆分成两个数组,两个数组之和相同,这样将其中一个数组加上减号,就能够得到求和为0.这里假设这两数组分别为`sum(P)`和`sum(N)`,那么可以得到`sum(P)-sum(N) = 0`.而我们知道`sum(P)+sum(N)=sum(nums)`,`sum(nums)`可以直接求和得到.

于是化简出来的问题为:

1. `sum(P)-sum(N)=0`
2. `sum(P)+sum(N)+sum(P)-sum(N)=0+sum(nums)`
3. `2*sum(P)=sum(nums)`
4. `sum(P)=sum(nums)/2`

也就是说,这个问题就变成了从数组`nums`中找出数列使其求和为`sum(nums)/2`,这样的数列有多少个.

将之前的目标`0`替换为`target`,则问题可以变成`sum(P)=(target+sum(nums))/2`,然后求出`sum(P)`有多少种.

由于都是整数,如果`(target+sum(nums))`不是偶数则不能有结果,这个可以快速判定,当时偶数的时候,则变成求子序列个数的问题.

Discuss中C++的实现如下:

```C++
int findTargetSumWays(vector<int>& nums, int s) {
    int sum = accumulate(nums.begin(), nums.end(), 0);
    return sum < s || (s + sum) & 1 ? 0 : subsetSum(nums, (s + sum) >> 1); 
}

int subsetSum(vector<int>& nums, int s) {
    int dp[s + 1] = { 0 };
    dp[0] = 1;
    for (int n : nums)
        for (int i = s; i >= n; i--)
            dp[i] += dp[i - n];
    return dp[s];
}
```

## 总结

处理完这个题目之和,心中不免有些沮丧,有明确的解题方向,却找不出其中的规律和方法,如果不下苦功夫去见识更多,是不是就局限在这里了?