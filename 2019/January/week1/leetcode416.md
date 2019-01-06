# [416. Partition Equal Subset Sum](https://leetcode.com/problems/partition-equal-subset-sum/)

题目要求给定一个非空的正整数数组,判断是否可以将其分成两个数组,这两个数组之和相同.

注意:

- 每个数组元素不大于 100
- 数组大小不超过 200

## 初步问题分析

分成两个数组,数组之和相同,也就是说,先求和得到`sum`,如果为奇数(`sum %2 != 0`)就不需要再判断了,肯定拆分不出来.然后是判断其中的一部分数之和能不能为`sum/2`.

那么究竟如何判断有一部分数之和为`sum/2`呢,这个动态规划问题的子问题是什么?

## 初步尝试

之前解决过一个问题是求出数组中求和为目标`target`的子序列有多少种,是否能够应用到这个上面? 毕竟子序列大于 0 种就存在之和为`sum/2`.

```C++
int calc_dp(std::vector<int>& dp,std::vector<int>& nums,int target) {
    if (dp[target] != -1) {
        return dp[target];
    }
    int result = 0;
    for (auto i = 0; i < nums.size(); i++) {
        if (target >= nums[i]) {
            result += calc_dp(dp, nums, target - nums[i]);
        }
    }
    dp[target] = result;
    return result;
}
bool canPartition(vector<int>& nums) {
    auto sum = std::accumulate(std::begin(nums), std::end(nums), 0);
    if (sum % 2 != 0) return false;

    //1,3,6
    auto target = sum / 2;

    //找出之和为target的子序列
    std::vector<int> dp(target+1, -1);
    dp[0] = 1;
    return (calc_dp(dp, nums, target) > 0);
}
```

可惜这个运行结果在`1,2,5`情况下是错误答案,生搬硬套行不通啊,还是要好好分析下子问题.

## 子问题是什么

通过阅读`discuss`搞明白了问题,这个问题可以理解为遇见某个数,选择求和还是继续下一个.假设`dp[i][j]`值为`num[0...i]`之和能否为`j`.那么在计算`dp[i][j]`时可以根据以下方式计算:

- 不选择`nums[i]`参与求和,`dp[i][j]=dp[i-1][j]`
- 选择`nums[i]`参与求和,`dp[i][j]=dp[i-1][j-nums[i]]`

也就是说`dp[i][j]=dp[i-1][j] || dp[i-1][j-nums[i]]`.

于是 2D 的动态规划方式实现为:

```C++
bool canPartition(vector<int>& nums) {
    auto sum = std::accumulate(std::begin(nums), std::end(nums), 0);
    if (sum % 2 != 0) return false;

    //1,3,6
    auto target = sum / 2;

    std::vector<std::vector<bool>> dp(nums.size() + 1, std::vector<bool>(target + 1, false));

    dp[0][0] = true;

    for (auto i = 1; i < nums.size()+1; i++) {
        dp[i][0] = true;
    }

    for (auto j = 1; j < target + 1; j++) {
        dp[0][j] = false;
    }

    for (auto i = 1; i < nums.size() + 1; i++) {
        for (auto j = 1; j < target + 1; j++) {
            dp[i][j] = dp[i - 1][j];
            if (j >= nums[i - 1]) {
                dp[i][j] = (dp[i][j] || dp[i - 1][j - nums[i - 1]]);
            }
        }
    }

    return dp[nums.size()][target];
}
```

## 减少空间复杂度的方法

在上述实现中可以看到,这里不太关注`dp[i][j]`中的`i`,可以简化 2D 的`dp`为 1D 的:

```C++
bool canPartition(vector<int>& nums) {
    auto sum = std::accumulate(std::begin(nums), std::end(nums), 0);
    if (sum % 2 != 0) return false;

    //1,3,6
    auto target = sum / 2;

    std::vector<bool> dp(target + 1, false);
    dp[0] = true;
    for (auto num : nums) {
        for (auto i = target; i >= num; i--) {
            dp[i] = dp[i] || dp[i - num];
        }
    }
    return dp[target];
}
```

在遍历`nums`的过程中,只要能达到`dp[target-num]`,就能够求和得到`dp[target]`,针对其它在`(target,num)`范围的数也是一样.因此在过程中可以持续更新`dp[i]`.

## 更为精巧的实现

在查看`discuss`的过程中,发现一个号称 4 行代码就可以解决的方案.于是研读了以下,确实非常精巧.

因为题目要求了数组最多 200 个数,每个数不大于 100,也就是说,目标最大为 200\*100/2,即 10000.之前的`std::vector<bool>`可以替换成`std::bitset<10001>`.而且位运算的特性决定了这个方案可能更加简单,不需要动态规划.

假设数组为`[1,2,3,4]`:

1. 加 1,则可能的和为`1`
2. 加 2,则可能的和为`1,2,3`
3. 加 3,则可能的和为`1,2,3,4,5,6`
4. 加 4,则可能的和为`1,2,3,4,5,6,7,8,9,10`

可以看到如果用`bitset`的某个位表示是否存在这个数,那么要从`1,2,3`得到`4,5,6`,只需要把`bitset`左移 3 位,而如果要保留`1,2,3`这三位,则只需要和右移结果合并即可.

于是实现就变成了:

```C++
bool canPartition(vector<int>& nums) {
    std::bitset<100*200/2+1> dp(1);
    auto sum = std::accumulate(std::begin(nums), std::end(nums), 0);
    if(sum %2 !=0) return false;

    for(auto num:nums){
        dp|=dp<<num;
    }
    return dp[sum/2];
}
```

时间和空间复杂度的最优解,实在是精巧.

## 总结

迄今为止已经做了二十多题动态规划问题,套路是摸清楚了,却受困于无法找出合适的子问题来,一直步履维艰.

今天也开了眼界,位操作的一些特性适当使用能够带来这样的好处,看来我的思维还是太局限啊.
