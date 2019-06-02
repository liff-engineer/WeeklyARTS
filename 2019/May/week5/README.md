# Weekly ARTS

- C++闭包及 TEPS 的一种应用

## Algorithm [747. Largest Number At Least Twice of Others](https://leetcode.com/problems/largest-number-at-least-twice-of-others/)

题目要求,给定整数数组`nums`,总是存在一个最大的整数,求这个数组是否满足最大的整数是其它所有整数的至少两倍大小.如果是,则返回最大整数的索引,否则返回`-1`.

单次循环即可,过程中需要记录下最大值和次大值,由于需要返回索引,这里的最大值记录索引,实现如下:

```C++
int dominantIndex(vector<int>& nums) {
    std::size_t idx = 0;
    int last=0;
    for(auto i = 1ul; i < nums.size();i++){
        auto v = nums[i];
        if(v > nums[idx]){
            last = nums[idx];
            idx = i;
        }
        else if(v > last){
            last = v;
        }
    }

    if(nums[idx] >= last*2)
        return idx;
    return -1;
}
```

## Review

## Technique [C++闭包及 TEPS 的一种应用](closure_apply.md)

## Share
