# 三个动态规划问题

动态规划问题一直“老大难”,这周完成了三个题目,还是有些坎坷。

## [64. Minimum Path Sum](https://leetcode.com/problems/minimum-path-sum/)

题目要求给定`mxn`的网格,填充的是非负整数,找到一个从左上角到右下角的路径,使得路过的网格数之和最小,求出这个最小的路径数之和.

限制:每次只能向下走一格或者向右走一格.

这个问题轻车熟路,假设到每个网格的最小路径数之和为`dp[i][j]`,由于只能向下或者向右走,那么要么是从`dp[i-1][j]`来,要么是从`dp[i][j-1]`来,要求最小值,那就是`dp[i][j] = std::min(dp[i-1][j],dp[i][j-1])`.

在最右侧和最上侧路径唯一,则可以确定初始化.

完整实现如下:

```C++
int minPathSum(vector<vector<int>>& grid) {
    int m = grid.size();
    if (m == 0) return 0;
    int n = grid.front().size();
    auto dp = grid;
    for (auto i = 1; i < m; i++) {
        dp[i][0] += dp[i - 1][0];
    }
    for (auto j = 1; j < n; j++) {
        dp[0][j] += dp[0][j-1];
    }
    for (auto i = 1; i < m; i++) {
        for (auto j = 1; j < n; j++) {
            dp[i][j] += std::min(dp[i - 1][j], dp[i][j - 1]);
        }
    }
    return dp[m - 1][n - 1];
}
```

## [377. Combination Sum IV](https://leetcode.com/problems/combination-sum-iv/)

题目要求给定一组正整数,而且没有重复,找出求和为指定正整数`target`的所有可能数组合是多少.

这个题目我只能看出来`dp[target] = dp[target-v1]+dp[v1]+dp[target-v2]+dp[v2]+...`,因而刚开始我尝试了以下实现:

```C++
int require_dp(std::map<int, int>& dp, std::vector<int>& nums,int n, int v)
{
    //已计算
    if (dp.find(v) != dp.end()) {
        return dp[v];
    }
    int  result = 0;
    {//在数据中存在则初始值为1
        auto it = std::find(nums.begin(), nums.end(), v);
        if (it != nums.end()) {
            result = 1;
        }
    }

    auto it = std::find_if(nums.begin(), nums.end(), [v](auto t) { return v > t; });
    for (it; it < nums.end(); ++it) {
        result += require_dp(dp, nums, n, *it);
        result += require_dp(dp, nums, n, v - *it);
    }
    dp[v] = result;
    return result;
}

int combination_sum4(std::vector<int>& nums, int target)
{
    //从大到小排序
    std::sort(nums.begin(), nums.end(), std::greater<int>());
    std::map<int, int> dp;
    return require_dp(dp, nums, nums.size(), target);
}
```

很不幸样例都没通过,也就是说子问题不是这个.

百思不得其解之和看了看Discuss,才发现自己很接近了,子问题没照好,条件写得有问题.正确的子问题是:

```C++
dp[target]=sum(dp[target-nums[i]]...);
```

之前算了两次...

对应的解法应该是:

```C++
int calc_dp(std::vector<int>& dp, std::vector<int>& nums, int target) {
    if (dp[target] != -1) {
        return dp[target];
    }

    int result =  0;
    for (auto i = 0; i < nums.size(); i++) {
        if (target >= nums[i]) {
            result += calc_dp(dp,nums, target - nums[i]);
        }
    }
    dp[target] = result;
    return result;
}
int combinationSum4(vector<int>& nums, int target) {
    std::vector<int> dp(target + 1, -1);
    dp[0]=1;
    return calc_dp(dp, nums, target);
}
```

## [718. Maximum Length of Repeated Subarray](https://leetcode.com/problems/maximum-length-of-repeated-subarray/)

给定两个整数数组`A`和`B`,返回在两个数组中都存在的最长子数组长度.

这个动态规划问题套路比较常规,假设`dp[i][j]`为`A[i..]`和`B[j..]`的最长子数组长度,那么可以得到`dp[i][j]=condition(dp[i-1][j-1]+1)`,意思是说,如果当前`A[i]`和`B[j]`一致,那么其子数组长度就是`dp[i-1][j-1]+1`.在求`dp`得过程中寻找最大值:

```C++
int findLength(vector<int>& A, vector<int>& B) {
    auto n = std::max(A.size(), B.size());
    std::vector<std::vector<int>> dp(n,std::vector<int>(n,0));
    int result = 0;
    for (auto i = 0; i < A.size(); i++) {
        for (auto j = 0; j < B.size(); j++) {
            if (A[i] == B[j]) {
                dp[i][j] = 1;
            }
        }
    }
    for (auto i = 1; i < A.size(); i++) {
        for (auto j = 1; j < B.size(); j++) {
            //dp[i][j] = condition(dp[i-1][j-1]+1)
            if (A[i] == B[j]) {
                dp[i][j] = dp[i - 1][j - 1] + 1;
                result = std::max(dp[i][j], result);
            }
        }
    }
    return result;
}
```

但是这个跑出来效率很差,又做了些许调整:

```C++
int findLength(vector<int>& A, vector<int>& B) {
    auto n = std::max(A.size(), B.size());
    std::vector<std::vector<int>> dp(n,std::vector<int>(n,0));
    int result = 0;
    for (auto i = 0; i < A.size(); i++) {
        if (A[i] == B[0]) {
            dp[i][0] = 1;
        }
    }
    for (auto j = 0; j < B.size(); j++) {
        if (A[0] == B[j]) {
            dp[0][j] = 1;
        }
    }
    for (auto i = 1; i < A.size(); i++) {
        for (auto j = 1; j < B.size(); j++) {
            //dp[i][j] = condition(dp[i-1][j-1]+1)
            if (A[i] == B[j]) {
                dp[i][j] = dp[i - 1][j - 1] + 1;
                result = std::max(dp[i][j], result);
            }
        }
    }
    return result;
}
```

这个也好不到哪里,现在问题能解决了,写法还是要多学习.