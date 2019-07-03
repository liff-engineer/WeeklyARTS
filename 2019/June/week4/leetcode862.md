# [862. Shortest Subarray with Sum at Least K](https://leetcode.com/problems/shortest-subarray-with-sum-at-least-k/)

题目要求给定整数数组`A`,找出最短子数组,要求子数字之和最少为`K`.如果不存在这样的子数组,则返回`-1`.

## 查找满足条件子数组

刚开始思路并不清晰,先尝试找出满足条件的子数组:

```c++
int result = 0;
int remain = K;
for (std::size_t i = 0; i < A.size(); i++, result++)
{
    remain -= A[i];
    if (remain <= 0)
        break;
}
if (remain <= 0)
    return result + 1;
return -1;
```

在此基础上实现多次查询动作:

```C++
int shortestSubarray(vector<int>& A, int K) {
    auto result = A.size() + 1;
    std::size_t idx = 0;
    int sum = 0;
    for (std::size_t i = 0; i < A.size(); i++)
    {
        sum += A[i];
        if (sum >= K)
        {
            sum = 0;
            //reverse search subarray
            for (auto j = i; j > idx; j--)
            {
                sum += A[j];
                if (sum >= K)
                {
                    idx = j;
                    break;
                }
            }

            result = std::min(result, i - idx + 1);
        }
        else
        {
            if (A[i] >= sum)
            {
                idx = i;
                sum = A[i];
            }
        }
    }
    return result > A.size() ? -1 : result;
}
```

最终执行超时,原因在于找到满足条件的子数组之后,还要收敛到最小,这个会执行多次.

之后实现就走不下去了.....

## `Discuss`中的实现

查阅了一下`Discuss`中的方案.发现一种处理方法,可以截取出`A[i..j]`之间的子数组和,即所谓的`prefix sum`:

```C++
auto n = A.size();
std::vector<int> B(n + 1, 0);
for (auto i = 0ul; i < n; i++)
{
    B[i + 1] = B[i] + A[i];
}
```

`B`的每一个元素都是前一项加上当前对应的`A`数组值.也就是说,如果要计算数组`A`的子数组之和`A[i..j]`,只需要`B[j+1]-B[i]`即可.

有了这种实现辅助,我们就可以实现出初步的解决方案:

```C++
int shortestSubarray(vector<int>& A, int K) {
    auto n = A.size();
    auto result = n + 1ul;
    std::vector<int> B(n + 1, 0);
    for (auto i = 0ul; i < n; i++)
    {
        B[i + 1] = B[i] + A[i];
    }

    for (auto j = 0ull; j < n + 1; j++)
    {
        for (auto i = 0ull; i < j; i++)
        {
            if (B[j] - B[i] >= K)
            {
                result = std::min(result, static_cast<decltype(result)>(j - i));
            }
        }
    }
    return result <= n ? result : -1;
}
```

我们通过遍历得到所有子数组和的情况从而计算出长度.

不过这种遍历计算效率较低,执行超时.

那么让我们看一看`Discuss`中的实现逻辑:

```C++
int shortestSubarray(vector<int>& A, int K) {
    auto n = A.size();
    auto result = n + 1ul;
    std::vector<int> B(n + 1, 0);
    for (auto i = 0ul; i < n; i++)
    {
        B[i + 1] = B[i] + A[i];
    }

    std::deque<int> idxs;
    for (auto j = 0ull; j < n + 1; j++)
    {
        while (!idxs.empty() && B[j] - B[idxs.front()] >= K)
        {
            result = std::min(result, static_cast<decltype(result)>(j - idxs.front()));
            idxs.pop_front();
        }

        while (!idxs.empty() && B[j] <= B[idxs.back()])
        {
            idxs.pop_back();
        }
        idxs.push_back(j);
    }
    return result <= n ? result : -1;
}
```

我们之前实现是通过遍历小于`j`的所有索引来比较的.这里使用了`std::deque`来存储要比较的索引.

首先我们来看`for`的第一块儿.可以知道`std::deque`中从小到大保存了所有要比较的`i`值.当有新的`j`时,如果`deque.front`位置的索引能够满足题目中的条件,我们为了找到最小的子数组,就需要继续往后推进,直到不满足条件为止.这时能够找到最小的长度.

如果数组中没有负数,上述代码就足够了.但是由于存在负数,在一些场景下就会出问题,譬如针对数组`[84, -37, 32, 40, 95]`.如果`k`为`167`,原本后三个数之和就够了,但是中间出现了`-37`,第一段代码碰见`-37`就跳出了.如果要正常运转,则需要跳过这种会使得递增序列`std::deque`中断的位置,这就是第二段代码的目的.

再回顾一下,我们要在`std::deque`中保存`prefix sum`递增的序列.然后遍历查找满足条件的索引.从而找到最短子数组.
