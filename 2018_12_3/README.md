# Weekly ARTS

- 如何打包Python模块
- 一种命名参数的写法
- 你的勤劳是否有意义?

## Algorithm [873. Length of Longest Fibonacci Subsequence](https://leetcode.com/problems/length-of-longest-fibonacci-subsequence/)

题目要求给定严格增长正整数序列`A`,找出最长的"类斐波那契数列"序列长度.类斐波那契数列定义为,给定序列`X_1,X-2,...,X_n`:

- `n >=3`
- `X_i+X_{i+1}=X_{i+2}`(针对所有`i+2<n`的情况)

### 非动态规划的解法

单纯根据类斐波那契数列的定义,以及当前的序列,来遍历所所有可能的结果.采用双层遍历,以两个初始化值为起点一直求和查找.

```C++
int lenLongestFibSubseq(vector<int>& A) {
    std::unordered_set<int> set(A.begin(), A.end());
    int result = 0;
    for (auto i = 0ul; i < A.size(); i++) {
        for (auto j = i + 1; j < A.size(); j++) {
            auto vi = A[i];
            auto vj = A[j];

            auto l = 2;
            while (set.find(vi + vj) != set.end()) {
                vj = vi + vj;
                vi = vj - vi;
                l++;
            }

            result = std::max(result, l==2? 0:l);
        }
    }

    return result;
}
```

这种解法比较简单粗暴,但是效率也低.还是考量下动态规划的解法.

### 动态规划解法

由于序列是增长序列,索引与内部数据直接没有关系,该如何表达解呢?

假设解为`dp`,`dp[i][j]`则为从`A[0..i]`,追加上`A[i..j]`序列后的最长序列长度.那么解之间的关系如下:

- 如果`A[i]+A[j]=A[k]`,那么`dp[j][k]=dp[i][j]+1`

在序列的`A[k]`之前的范围`A[i..j]`内需要找出问题解:

```C++
auto i = 0;
auto j = k-1;
while(j > i){
    if(A[i]+A[j] == A[k]){
        dp[j][k]=dp[i][j]+1;
        i++;//往前推进
        j--;
    }
    else if(/*小于目标值,向右侧推进*/){
        i++;
    }
    else if(/*大于目标值,向左侧推进*/){
        j--;
    }
}
```

在过程中记录最大的`dp`值即可,完整的实现如下:

```C++
int lenLongestFibSubseq(vector<int>& A) {
    auto n = A.size();
    int result = 0;

    std::vector<std::vector<int>> dp(n, std::vector<int>(n, 0));
    for (auto k = 1ul; k < n; k++) {
        auto i = 0ul;
        auto j = k - 1ul;
        while (j > i) {
            auto t = A[k];
            auto v = A[i] + A[j];
            if (v > t) {
                j--;
            }
            else if (v < t) {
                i++;
            }
            else
            {
                dp[j][k] = dp[i][j] + 1;
                result = std::max(result, dp[j][k]);
                i++;
                j--;
            }
        }
    }
    return result == 0 ? 0 : result + 2;
}
```

## Review [如何打包Python模块](PyPackage.md)

如何将实现的Python模块打包给其他人使用?

## Technique [一种命名参数的写法](NamedParameter.md)

C++中如何模仿Python的命名参数书写方法.

## Share 你的勤劳是否有意义?

最近《极客时间》上了个新专栏-《10x程序员工作法》,开篇词中说:

> 软件行业里有一本名著叫《人月神话》,其中提到两个非常重要的概念：本质复杂度和偶然复杂度。
> 简单来说,本质复杂度就是解决一个问题时,无论怎么做都必须要做的事,而偶然复杂度时因为选用的做事方法不当,而导致要多做的事。

这就让我想起最近的惨痛经历.

之前偶然了解到有[pybind11](https://github.com/pybind/pybind11)这么个库,能够为C++库提供Python绑定.由于现在项目组还只能用Visual Studio 2010,没办法用,也就搁置了. 公司切换C++编译器,要升级到Visual Studio 2015,为此我做了个专题-《现代C++为开发带了的改变》,发掘了很多新的方法和思路,苦等半年,也没升级,专题评审时被评委评论"事情做出来了再来说". 年底做规划又想起这茬来,琢磨了一下,可以将C++开发的功能提供Python接口,供测试使用.于是做起了预研.

首先面临的困难是`pybind11`需要`C++11`编译器,也就是说我必须将使用到的那么多C++库用VS2015编译出来.有一部分库能拿到VS2015编译结果包,但是其它的就不行了,只能拿源代码编译.又考虑到运行时依赖的各种动态库,这个肯定要上`vcpkg`或者`conan`这种包管理工具来自动处理依赖.最后还需要构造出Python可识别的`.whl`包,毕竟你不希望让别人上手之前有太多配置和限制.

也就是说,理想情况下:

1. 安装库依赖:`vcpkg install  library-x library_x:x64-windows`
2. 实现C++库的`PyAdapter`
3. 打包`python setup.py bdist_wheel`
4. 使用`pip install xxxxx.whl`

针对开发不应当过多关注库依赖等等,专注于利用如此简洁的`pybind11`库实现Python接口,而且能够很方便地打包.而打包的结果也应当很简单地使用.

然而实际上呢? 首先一部分库依赖即使已经用VS2015编译出结果了,也需要实现`vcpkg`或者`conan`适配;然后是其它库依赖需要借用`vcpkg`或者`conan`机制构造出对应的安装脚本来支持简单安装;在实现C++库的`PyAdapter`时还涉及一堆工程配置;即使是打包动作要书写的`setup.py`也需要各种探索(针对动态库打包分发的操作在各种能够查到的说明文档中都语焉不详).

在这个过程中浪费了大量时间,扩展了一部分`vcpkg`功能使其支持从`svn`迁出源代码,然后为一些库依赖实现了`vcpkg`的`port`,甚至为一些库提供了外挂式的工程配置来支持`vcpkg`安装脚本.并借由之前做`vcuser`的积累为`PyAdapter`提供解决方案级配置.然后花了两三天搞清楚Python的打包是怎么一回事.

在这个过程中什么是本质复杂度? 就是理想情况下的场景,你需要安装库依赖、实现适配、打包、安装Python包,这个世界就应当如此简单.偶然复杂度是什么?没有统一的包管理,没有可操作的配置方案,Python打个包也得各种琢磨,就一个感觉-混乱.

把时间和精力都浪费在这个上面,是否有意义?

以正面的思维来看,在工作之中以更理想化的视角,拆分出问题的本质复杂度和偶然复杂度,或许能够缓解这种现状,获得更好的结果.

## TODO

- [C++与Python联合调试](https://github.com/MicrosoftDocs/visualstudio-docs/blob/master/docs/python/working-with-c-cpp-python-in-visual-studio.md)
- [How can I make a Python Wheel from an existing native library?](https://stackoverflow.com/questions/24071491/how-can-i-make-a-python-wheel-from-an-existing-native-library)

- [一种命名参数的实现](https://gcc.godbolt.org/)
- [Named Arguments in C++](https://www.fluentcpp.com/2018/12/14/named-arguments-cpp/)
- [A brief introduction to Concepts – Part 1](https://blog.feabhas.com/2018/12/a-brief-introduction-to-concepts-part-1/)
- [Flip Model: A Design Pattern](https://accu.org/var/uploads/journals/Overload148.pdf#page=6)