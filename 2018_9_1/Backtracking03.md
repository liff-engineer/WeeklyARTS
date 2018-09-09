# [回溯法03](https://en.wikipedia.org/wiki/Backtracking)

本周继续练习回溯法的题目,基本套路已经摸透,基本上10分钟完成一题。

## [77. Combinations](https://leetcode.com/problems/combinations/description/)

题目要求给定整数n和k,返回可能的k个数集合,数的取值范围是1到n,且不重复。

思路如下:

- 遍历1到n,走取当前值和不取当前值两个分支
- 当取的数个数为k时停止递归,记录结果

实现如下:

```C++
void backtrack(std::vector<std::vector<int>>& results,
    std::vector<int>& result,int n,int next, int remain)
{
    if (remain <= 0) {
        results.push_back(result);
        return;
    }
    if (next > n) return;
    result.push_back(next);
    backtrack(results, result, n, next + 1, remain - 1);
    result.pop_back();
    backtrack(results, result, n, next + 1, remain);
}

vector<vector<int>> combine(int n, int k) {
    std::vector<std::vector<int>> results;
    std::vector<int> result;
    backtrack(results, result, n, 1, k);
    return results;
}
```

## [39. Combination Sum](https://leetcode.com/problems/combination-sum/description/)

题目要求给定一组数和一个整数target,返回所有由这组数中数之和为target的集合,这组数没有重复,且取数时可以重复取。

思路如下:

- 排序并遍历这组数
- 针对当前数,求出最多可重复数量count,开count+1个分支,分别取0~count个当前数

实现如下:

```C++
void backtrack(std::vector<std::vector<int>>& results, const std::vector<int>& candidates,
    std::vector<int>& result, int index, int remain)
{
    if (remain == 0) {
        results.push_back(result);
        return ;
    }
    if (index >= candidates.size()) return;
    auto v = candidates.at(index);
    if (remain < 0 || remain < v) return;
    auto count = remain / v;
    std::fill_n(std::back_inserter(result), count, v);
    for (int i = 0; i < count; i++) {
        backtrack(results, candidates, result, index + 1, remain%v + i * v);
        result.pop_back();
    }

    //不使用当前值
    backtrack(results, candidates, result, index + 1, remain);
}
vector<vector<int>> combinationSum(vector<int>& candidates, int target) {
    std::vector<std::vector<int>> results;
    std::vector<int> result;
    std::sort(candidates.begin(),candidates.end());
    backtrack(results, candidates, result, 0, target);
    return results;
}
```

## [90. Subsets II](https://leetcode.com/problems/subsets-ii/description/)

题目要求给定一组可能包含重复的整数,返回所有可能的子集,注意子集不能重复。

这个要注意如何处理子集不能重复,思路如下:

- 排序并遍历所有整数
- 针对当前数,找到共有count个当前数,开count+1个分支,分别取0到count个当前数

实现如下:

```C++
void backtrack(std::vector<std::vector<int>>& results, std::vector<int>& result,const std::vector<int>& nums,int n,int index)
{
    if (index >= n) {
        results.push_back(result);
        return;
    }

    //pick equal range
    int last = index + 1;
    for (; (last < n) && (nums.at(index) == nums.at(last)); last++);

    std::fill_n(std::back_inserter(result), last - index, nums.at(index));
    for (auto i = index; i < last; i++) {
        backtrack(results, result, nums, n, last);
        result.pop_back();
    }

    backtrack(results, result, nums, n, last);
}
vector<vector<int>> subsetsWithDup(vector<int>& nums) {
    std::sort(nums.begin(), nums.end());
    std::vector<std::vector<int>> results;
    std::vector<int> result;
    backtrack(results, result, nums, nums.size(), 0);
    return results;
}
```

## 总结

可以看到,回溯法能够解决的问题非常规律,解法也很套路,抓住几个关键特征即可;不过实现时需要注意,写法不一样效率可能不一样,硬套回溯法能解决问题,但是效率不够高。

至此已经完成了39个回溯法题目中的13个,可以告一段落,继续其他类型的算法题目了。