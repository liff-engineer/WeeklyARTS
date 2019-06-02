# Weekly ARTS

- C++闭包及 TEPS 的一种应用
- "人丑"就该多读书

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

## Review [Everything You Need to Know About std::any from C++17](https://www.bfilipek.com/2018/06/any.html)

- [When should I use std::any](https://stackoverflow.com/questions/52715219/when-should-i-use-stdany)
- [std::any: How, when, and why](https://devblogs.microsoft.com/cppblog/stdany-how-when-and-why/)

## Technique [C++闭包及 TEPS 的一种应用](closure_apply.md)

## Share "人丑"就该多读书

最近工作思考问题时想到了"正交性"这种设计,上周 review 了一段《Unix 编程艺术》中关于紧凑性和正交性的内容.然后就发现自己显示器下面垫了本《Unix 编程艺术》.于是就重新读了起来.

才读了几章,受益颇多,对里面讲到的很多东西都有了更切身的理解和体会.可叹自己数年前就买了一堆书,没有感受到书中的精髓,反而是通过这几年摸爬滚打,才慢慢领悟和理解那些书中早已讲述过的内容. 有种不听老人言,被现实教训过之后,才明白那些早已听过的话之可贵.可惜时光一去不复返.

多读书,读进去,用起来,切莫再浪费时间.
