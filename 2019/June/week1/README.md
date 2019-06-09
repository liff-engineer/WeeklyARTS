# Weekly ARTS

- `function_ref`:可调用对象的非持有引用

## Algorithm [1006. Clumsy Factorial](https://leetcode.com/problems/clumsy-factorial/)

正整数的阶乘计算方式为`factorial(N)=N*(N-1)*(N-2)....*(1)`.题目中定义了一种`clumsy factorial`操作,对以上的序列计算方式,不再是全部的乘法,而是`*`、`/`、`+`、`-`顺序执行.例如`clumsy(10)=10*9/8+7-6*5/4+3-2*1`.除法结果向下取整.

题目要求给定整数`N`计算出对应的值.

我们从题目中可以找到规律,`clumsy`计算可以分为三个部分:

- 头部 3 个数,`N~(N-3)`,固定计算
- 中间数,4 个一组可分别计算
- 尾部 0~3 个数,根据余数分别计算

因而我们的解决方案如下:

```C++
int clumsy(int N) {
    //1:n->1
    //2:n*(n-1)->2
    if (N < 3)
        return N;
    int result = N * (N - 1) / (N - 2);
    for (auto i = (N - 3); i > 3; i += 4)
    {
        result += i - (i - 1) * (i - 2) / (i - 3);
    }
    switch (((N - 3) % 4))
    {
    case 3:
    {
        result += 3 - 2 * 1;
    }
    break;
    case 2:
    {
        result += 2 - 1;
    }
    break;
    case 1:
    {
        result += 1;
    }
    break;
    default:
        break;
    }
    return result;
}
```

然而在计算过程中发现,大整数情况下乘法结果溢出,于是我尝试着将乘法和除法操作进行化简,即针对计算式`(i - 1) * (i - 2) / (i - 3)`提取函数:

1. 以`(i-3)`为`n`,改写计算式为`(n+2)*(n+1)/n`
2. 展开计算式得到`(n^2+3n+2)/n`
3. 化简得到`n+3+2/n`
4. 考虑到`n>3`,则实际计算结果为`n+3`
5. 计算式实际结果为`(i-3)+3=i`

也就是说,头部 3 个数计算结果为`N+1`,中间 4 个一组的数字计算结果都为 0,那么解决方案可以简化为:

```C++
int clumsy(int N)
{
    //1:n->1
    //2:n*(n-1)->2
    if (N < 3)
        return N;
    int result = N + 1;
    switch (((N - 3) % 4))
    {
    case 3:
    {
        result += 3 - 2 * 1;
    }
    break;
    case 2:
    {
        result += 2 - 1;
    }
    break;
    case 1:
    {
        result += 1;
    }
    break;
    default:
        break;
    }
    return result;
}
```

很不幸,在`N=4`时结果错误,因为`2/(N-2)`为`1`,即计算开头 3 个数时`2/n`计算不能省略,过程中如果整除,数据也不对.以上省略的条件为,有前 3 个,中间 4 个和 0~3 个余数,即`N<=10`均无法套用,这里直接编制成表:

```C++
int clumsy(int N)
{
    std::array<int, 12> results = {
        0,
        1,
        2,
        3 * 2 / 1,
        4 * 3 / 2 + 1,
        5 * 4 / 3 + 2 - 1,
        6 * 5 / 4 + 3 - 2 * 1,
        7 * 6 / 5 + 4 - 3 * 2 / 1,
        8 * 7 / 6 + 5 - 4 * 3 / 2 + 1,
        9 * 8 / 7 + 6 - 5 * 4 / 3 + 2 - 1,
        10 * 9 / 8 + 7 - 6 * 5 / 4 + 3 - 2 * 1,
        11 * 10 / 9 + 8 - 7 * 6 / 5 + 4 - 3 * 2 / 1};

    std::array<int, 4> remains = {
        8 - 7 * 6 / 5 + 4 - 3 * 2 / 1,
        5 - 4 * 3 / 2 + 1,
        6 - 5 * 4 / 3 + 2 - 1,
        7 - 6 * 5 / 4 + 3 - 2 * 1};

    if (N < 0)
        return N;
    if (N < results.size())
        return results[N];
    int result = N + 1 + 2 / (N - 2);
    result += remains[((N - 3) % 4)];
    return result;
}
```

提交之后发现运行结果为 4ms,依然不是最好的.这里可以将`results`和`remains`声明成`constexpr static`,从而避免运行时消耗,即可以 0ms 运行完成.

## Review [`function_ref`:可调用对象的非持有引用](function_ref.md)

## Technique

## Share
