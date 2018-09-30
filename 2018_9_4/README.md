# Weekly ARTS

- 如何整合3D内容到Qt Graphics View

## Algorithm [413. Arithmetic Slices](https://leetcode.com/problems/arithmetic-slices/description/)

题目给定数`num`,要求依次输出从`0`到`num`的所有数二进制表示中的`1`的个数。

### 解决思路

使用动态规划的算法来计算,其子问题关系如下：

 v(n) = v(n/2) + ((n%2==0)? 0:1)

某个数n的`1`个数由除以`2`剩余的整数,以及除以`2`的余数来决定。

从大到小计算除各个数的`1`个数,记录下来供后续使用,避免重复计算.

### 原始实现

从大到小计算,并记录过程中的值：

```C++
int count_bit(std::vector<int>& results, int v)
{
    if (results.at(v) != -1) return results.at(v);
    int r = count_bit(results, v / 2) + (v % 2 == 0 ? 0 : 1);
    results[v] = r;
    return r;
}
vector<int> countBits(int num) {
    std::vector<int> results(num + 1, -1);
    results[0] = 0;
    for (int i = num; i > 0; i--) {
        count_bit(results, i);
    }
    return results;
}
```

### 更为简洁清晰的实现

换个角度从小到大计算,能够使得实现简单许多:

```C++
vector<int> countBits(int num) {
    std::vector<int> results(num + 1, 0);
    for (int i = 0; i <= num; i++) {
        results[i] = results[i >> 1] + (i & 1);
    }
    return results;
}
```

## Reivew

## Technique [如何整合3D内容到Qt Graphics View](Mixin2D&3DinQt.md)

学习了在Qt中如何以3D模型为底,在其上实现2D场景的方法。

## Share
