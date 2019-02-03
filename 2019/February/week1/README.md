# Weekly ARTS

- 在 MSVC 中如何分析构建效率
- CMake 快捷使用 vcpkg 库管理器
- 从"Why not Conan?"说起

## Algorithm  [474. Ones and Zeroes](https://leetcode.com/problems/ones-and-zeroes/)

题目要求假设有一组由`0`和`1`组成的字符串,给定`0`和`1`的个数`m`及`n`,求这些`0`和`1`构成的字符串个数最多有多少个?

这个题目就是判断某个字符串选与不选对结果造成的影响,而限制条件在于只有`m`个`0`和`n`个`1`.

假设结果为`dp`,那么最终结果为`dp[m][n]`,针对某个字符串,如果字符串中有`di`个`0`,`dj`个`1`,那么子问题就是:

```C++
dp[i][j]=std::max(dp[i][j],dp[i-di][j-dj]+1)
```

实现如下:

```C++
int findMaxForm(std::vector<std::string>& strs, int m, int n) {

    std::vector<std::vector<int>> dp(m+1,std::vector<int>(n+1,0));
    for(auto str:strs){
        auto length = str.size();
        auto number = std::count(std::begin(str),std::end(str),'0');
        int di = number;
        int dj = length-number;

        for(int i = m;i>=di; i--){
            for(int j = n ; j >=dj;j--){
               dp[i][j] = std::max(dp[i-di][j-dj]+1,dp[i][j]);
            }
        } 
    }
    return dp[m][n];
}
```


## Review [在 MSVC 中如何分析构建效率](WhySoSlow.md)

## Technique [CMake 快捷使用 vcpkg 库管理器](vcpkgTargets.md)

## Share 从["Why not Conan?"](https://github.com/Microsoft/vcpkg/blob/master/docs/about/faq.md#why-not-conan)说起

C++包管理器正在迅速发展,由于工作环境的原因,我从[`vcpkg`](https://github.com/Microsoft/vcpkg)有雏形后没多久就在关注并使用. 社区有过关于`Conan`与`vcpkg`的探讨,工作中也有同事用`Conan`而对`vcpkg`不太关心.

我无意探讨哪个更好,仅仅是从`vcpkg`的FAQ中看到了几点`vcpkg`开发者对于为何已有`Conan`还要开发`vcpkg`的答复:

- `Conan`依赖于为每个包发布独立副本.这个将会带来一些问题.假设我们的项目需要第三方库A与B,而A依赖于C的V1版本,B依赖于C的V2版本,那么该怎么办? 这种处理方式导致出现大量的包,互相之间无法共存.因而`vcpkg`采用了集中式的管理模式,并允许用户在其私有版本上做出调整.采用这种处理方式来产生有经过互相测试的高质量库,来支持用户使用及修改.

- 当依赖在库级别上是相互独立的版本,这将鼓励每个构造环境变得相对独特,无法从稳定且经过良好测试的生态环境中获得好处,也无法将自身贡献到这个生态环境出去.如果将构建流程由统一的平台管理,我们希望将集中测试和努力到常用的库版本,从而最大化生态环境的质量和稳定性.

- `vcpkg`希望能够使自身能够很好地集成到现有的系统管理器中,而不是尝试取代他们.

- `vcpkg`采用`CMake`是因为它算是事实上的构建"标准"工具,采用`C++`来实现包管理器也是希望用户可以不需要了解更多知识就能够理解包管理器及其实现.即使`Python`很简单,引入这样的依赖也是没有必要的.

在`reddit`上[Conan, vcpkg or build2?](https://www.reddit.com/r/cpp/comments/9m4l0p/conan_vcpkg_or_build2/)有开发者针对C++包管理器的探讨,虽然`Conan`目前占据主流位置,但是有个评论让我印象深刻,其中提到`vcpkg`的设计理念,类似于[CppCon 2017: Titus Winters “C++ as a "Live at Head" Language”](https://www.reddit.com/r/cpp/comments/73108j/cppcon_2017_titus_winters_c_as_a_live_at_head/)中的`Live at Head`,在[Why Adopt Abseil?](https://abseil.io/about/philosophy#why-adopt-abseil)有详细的阐述.

在我看来`vcpkg`的方式才是未来的趋势,为什么我们`suck in`各种版本? CI/CD的发展,DevOps的理念,持续交付的需求,不应当纠结具体的各种库版本,我们使用的是库,而不是各种版本的库."Live at Head",走向统一、秩序,而不是混乱、分裂.


## TODO

软件架构

- [The Clean Architecture](http://blog.cleancoder.com/uncle-bob/2012/08/13/the-clean-architecture.html)
- [DDD vs Clean architecture: hosting the business logic](http://objectcode101.com/ddd-vs-clean-architecture-hosting-the-business-logic/)
- [The Four Architectures That Will Inspire Your Programming](https://dzone.com/articles/four-architectures-will)

书

Patterns of Enterprise Application Architecture

CMake

- [More Modern CMake](https://github.com/Bagira80/More-Modern-CMake)
- [cmake-generator-expressions](https://cmake.org/cmake/help/latest/manual/cmake-generator-expressions.7.html)
- [Setting /PROFILE Linker Flag for CMake MSVC Target
  ](https://stackoverflow.com/questions/54091538/setting-profile-linker-flag-for-cmake-msvc-target)
