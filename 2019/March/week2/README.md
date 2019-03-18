# Weekly ARTS

- `简洁`数据结构
- cmake 部署小提示

## Algorithm [868. Binary Gap](https://leetcode.com/problems/binary-gap/)

随机个题目休闲一下,题目要求给定整数,求出其二进制表示中两个`1`之间最远间隔,其中`0b11`间隔为`1`,如果找不到则返回`0`.

### 第一种解法

通过不断除以`2`,可以理解为右移,取得的余数就是二进制的值,当为`1`时开始重新计数,并记录过程中的最大值:

```C++
int binaryGap(int N)
{
    int  last = 0;
    int  current = 0;
    bool flag = false;
    while (N > 0)
    {
        if (N % 2 != 0)
        {
            if (flag)
            {
                last = std::max(last, current);
            }
            flag = true;
            current = 1;
        }
        else if(flag)
        {
            current++;
        }
        N /= 2;
    }
    return last;
}
```

可以看到这种解法上,写法还是需要注意的,需要三个变量,`last`存储结果,`current`进行间隔计数,`flag`用来控制是否计数. 条件判断需要比较小心,可以使用`std::bitset`来改进.

### 采用`std::bitset`的写法

采用`std::bitset`则可以使用普通循环,而无需使用`while`,由于可以追溯,用于计数的变量也不需要了:

```C++
int binaryGap(int N)
{
    std::bitset<32> v = N;
    int  result = 0;
    auto last = 0ul;
    for (auto i = 0ul; i < v.size(); i++)
    {
        if (!v[i])
            continue;
        if (v[last]) {
            result = std::max(result, static_cast<int>(i - last));
        }
        last = i;
    }
    return result;
}
```

`std::bitset`的优势在于可以将其直接作为二进制数组进行操作,写法上会简单清晰许多.

## Review [`简洁`数据结构](simple-data-structures.md)

## Technique [cmake 部署小提示](cmake-deploy-tips.md)

## Share

## TODO

- [Hello C++ Insights](https://www.andreasfertig.blog/2019/03/hello-c-insights.html)
- 使用`Modern CMake`进行`deploy`
