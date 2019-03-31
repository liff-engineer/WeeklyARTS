# [204. Count Primes](https://leetcode.com/problems/count-primes/)

题目要求给定正整数`n`,求出小于`n`的所有素数个数.

## 第一次尝试

既然是判断小于`n`的素数个数,首先实现素数的判断:

```C++
bool is_prime(int n)
{
    if(n <= 1) return false;
    for(auto i = 2 ; i < n ; i++)
    {
        if(n % i == 0)
            return false;
    }
    return true;
}
```

然后一个循环操作即可:

```C++
if(n <= 2) return false;
int result = 0;
for(auto i = 2 ; i < n; i++)
{
    if(is_prime(i))
        result++;
}
return result;
```

这个虽然能够得到计算的结果,但是效率非常低,提交会报超时.

## 小幅度优化

我们可以尝试以下几点来进行优化:

- 如果是`2`或者`3`的倍数,则肯定不是素数
- 小于`n`的素数,最大值是`sqrt(n-1)`,无需循环判断到`n`

实现如下:

```C++
//排除小于2的特殊情况
if (n <= 2)
    return 0;
//2,3两种情况直接返回
if (n <= 3)
    return 1;
if (n <= 4)
    return 2;

auto is_prime = [](int i) -> bool {
    //快速检测
    if (i % 2 == 0 || i % 3 == 0)
        return false;
    auto sqrt_n = static_cast<int>(std::sqrt(i));
    //根据特性减少检测次数
    for (auto j = 2; j <= sqrt_n; j++)
    {
        if (i % j == 0)
            return false;
    }
    return true;
};

int result = 2;
//直接从5开始
for (auto i = 5; i < n; i++)
{
    if (is_prime(i))
        result += 1;
}
return result;
```

使用上述方式比原始版本效率要高不少,但是依然比较低.

## `6k ± 1`

在`Wiki`上列出了多种素数检测方法,其中一种叫`6k ± 1`,即步进为`6`,检测`6k+1`和`6k-1`是否能够被整除.

```C++
auto is_prime = [](int i) -> bool {
    //快速检测
    if (i % 2 == 0 || i % 3 == 0)
        return false;
    //步进6
    for (auto j = 5; j * j <= i; j += 6)
    {
        //6k-1 和 6k+1
        if (i % j == 0 || i % (j + 2) == 0)
            return false;
    }
    return true;
};
```

完整实现如下:

```C++
int countPrimes(int n) {
    //排除小于2的特殊情况
    if (n <= 2)
        return 0;
    //2,3两种情况直接返回
    if (n <= 3)
        return 1;
    if (n <= 4)
        return 2;

    auto is_prime = [](int i) -> bool {
        //快速检测
        if (i % 2 == 0 || i % 3 == 0)
            return false;
        //步进6
        for (auto j = 5; j * j <= i; j += 6)
        {
            //6k-1 和 6k+1
            if (i % j == 0 || i % (j + 2) == 0)
                return false;
        }
        return true;
    };

    int result = 2;
    for (auto i = 5; i < n; i++)
    {
        if (is_prime(i))
            result += 1;
    }
    return result;
}
```

当然,`wiki`上还有几种快速测试素数的方法,但是都是概率性的,不能严格保证结果.

使用上述实现即可通过测试被`accept`.但是提交后就会发现其效率依然很低.

看过效率高的解决方案之后,才发现自己思维上有些盲点.

## 效率高的解决方案

相对高效得多的方案,并不是一个个验证某个数是不是素食,毕竟即使原先一个数验证是否素数需要 100 次比较,哪怕减少到 10 次,依然要对每个数进行 10 次检验.

这里高效的解决方案就是,反其道而行,把不是素数的标记出来,每次循环能够标记大量非素数,实现如下:

```C++
//反其道而行,计算所有非素数
int countPrimes(int n)
{
    if (n <= 2)
        return 0;
    int result = n / 2;
    std::vector<bool> noprimes(n, false); //假设都是素数
    int sqrt_n = std::sqrt(n - 1);
    for (auto i = 3; i <= sqrt_n; i += 2)
    {
        if (!noprimes[i])
        {
            auto step = i * 2;
            for (auto j = i * i; j < n; j += step)
            {
                if (!noprimes[j])
                {
                    noprimes[j] = true;
                    result--;
                }
            }
        }
    }
    return result;
}
```
