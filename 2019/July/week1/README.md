# Weekly ARTS

## Algorithm [801. Minimum Swaps To Make Sequences Increasing](https://leetcode.com/problems/minimum-swaps-to-make-sequences-increasing/)

题目要求有两个等长数组`A`和`B`.可以交换`A[i]`和`B[i]`,即同位置的可以交换.希望得到两个严格递增的数组`A`和`B`.求最少交换次数是多少.

题目的分类是动态规划,针对特定位置`i`,有两种场景:

- 交换
- 不交换

这两种场景有其前提和结果.譬如不交换,则需要满足`A[i-1]<A[i]`和`B[i-1]<B[i]`,这时交换次数不变;交换的话,需要满足`A[i-1]<B[i]`和`B[i-1]<A[i]`,这时根据动态规划问题特性,则需要寻找最小交换次数.

根据上述思路,实现如下:

```C++
int minSwap(std::vector<int> A, std::vector<int> B)
{
    auto n = A.size();
    auto nc = std::vector<int>(n, 0);
    auto c = std::vector<int>(n, 1);

    for (auto i = 1ul; i < n; i++) {
        nc[i] = c[i] = static_cast<int>(n);
        //无需调整的场景
        if (A[i - 1] < A[i] && B[i - 1] < B[i]) {
            nc[i] = nc[i - 1];
            c[i] = c[i - 1] + 1;
        }
        //需要调整的场景
        if (A[i - 1] < B[i] && B[i - 1] < A[i]) {
            nc[i] = std::min(nc[i], c[i - 1]);
            c[i] = std::min(c[i], nc[i - 1] + 1);
        }
    }
    return std::min(c[n - 1], nc[n - 1]);
}
```

运行后发现效率和内存占用都较高,实际上无需将`nc`和`c`两种状态存储为数组,只需要记录最近一次结果即可:

```C++
int minSwap(vector<int>& A, vector<int>& B) {
    auto n = A.size();
    int nc_last = 0;
    int c_last = 1;

    for (auto i = 1ul; i < n; i++) {
        int nc = n;
        int c = n;
        //无需调整的场景
        if (A[i - 1] < A[i] && B[i - 1] < B[i]) {
            nc = nc_last;
            c = c_last + 1;
        }
        //需要调整的场景
        if (A[i - 1] < B[i] && B[i - 1] < A[i]) {
            nc = std::min(nc, c_last);
            c = std::min(c, nc_last + 1);
        }

        nc_last = nc;
        c_last = c;
    }
    return std::min(c_last, nc_last);
}
```

## Review

## Technique

## Share

## TODO

- [Expressive C++ Template Metaprogramming](https://www.fluentcpp.com/2017/06/02/write-template-metaprogramming-expressively/)
- [A brief introduction to Boost.Fibers](http://www.romange.com/2018/12/15/introduction-to-fibers-in-c-/)
