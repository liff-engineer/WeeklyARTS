# Weekly ARTS

- 富有表现力的 C++模板元编程
- 在 C++中检测类型是否定义
- 由 X-Y 问题想到

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

## Review [富有表现力的 C++模板元编程](expressive_tmp.md)

## Technique [在 C++中检测类型是否定义](cpp_detect_type_defined.md)

## Share 由 X-Y 问题想到

有很多道理你之前都听过,读过之后就忘记了,直到你被某些事情折磨了很久,想明白了,才发现这些道理的可贵之处.

我要说的就是 X-Y 问题,最近工作碰见了一些典型的例子:

- 项目部署的过程中需要运行 Qt 的部署程序,项目中用得好好的,到其它团队那却出现各种问题,原因在于 Qt 的 windeployqt 程序实现机制,导致如果电脑中环境变量配置了其它版本 Qt 相关的内容,就会使用这些环境变量,从而导致部署出错. 于是我提供了解决方案,运行 windeployqt 时,为其提供合适的环境,即将所使用 Qt 版本路径添加到`Path`环境变量最前面. 万万没想到,在一些电脑上运行出错...... 于是同事束手无策,rollback 了. 然后就有同事开始分析问什么会出错/那台电脑会出错.浪费了大量时间之后,找到我,然后我也尝试跟随他的思路,给他定位哪里出错了,忘记了要解决的是什么问题.其实很简单,就是直接为 windeployqt 提供最小运行环境即可,每台电脑都有不同场景,没必要去关注之前的方案为什么出错.

- 之前要发版,结果服务器上构建一直出错,于是各种分析,找外部团队看问题出在哪里,耗费了大量人力和时间,最终是硬盘出问题了. 回到最初,我们的目标是在服务器上构建,却集中精力在看为什么这台服务器构建出错.跑偏了太多.

在回想一下自己的编码生涯,粗浅地学了很多东西,一直在解决 Y 问题,浪费了诸多时间精力.譬如目标方向是系统架构师,却沉迷 C++.选择比努力要重要.

## TODO

- [Expressive C++ Template Metaprogramming](https://www.fluentcpp.com/2017/06/02/write-template-metaprogramming-expressively/)
- [A brief introduction to Boost.Fibers](http://www.romange.com/2018/12/15/introduction-to-fibers-in-c-/)
