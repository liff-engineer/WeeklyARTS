# Weekly ARTS

- 在 MSVC 中如何分析构建效率
- CMake 快捷使用 vcpkg 库管理器

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

## Share

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
