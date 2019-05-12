# [C++实现稀疏集合](https://www.computist.xyz/2018/06/sparse-sets.html)

如果你有大量的整数需要进行如下操作:

1. 插入
2. 删除
3. 查找
4. 清除/移除所有元素

最有效率的方式是什么?

使用自平衡二分查找树,例如红黑树,AVL 树等等,这种时间复杂度针对插入、删除、查找等操作是`O(Log N)`.

也可以使用哈希,这样前三种操作时间复杂度为`O(1)`,第四种操作时间复杂度为`O(n)`.

我们也可以使用比特 vector,但是其需要`O(n)`来执行清除操作.

稀疏集合(Sparse Set)实现要优于以上所有,针对上述操作其复杂度均为`O(1)`,以下就是其设计思路及实现.

## 设计思路

稀疏集合包含两种数据结构:稠密集合 `D`,稀疏集合 `S`:

![数据结构](https://4.bp.blogspot.com/-NzEMnQ15M3E/Wx6OXv_zHeI/AAAAAAAAAFA/bIu23ILSK3AGSuzmRlM2qhCa3VdrxfWHQCLcBGAs/s1600/sparseset.png)

当整数`x`插入时,它追加到数组`D`,它在`D`中的索引被插入到`S`的索引`x`位置.如果我们要将`5`插入到上图集合中,最终结果是:`D[3]=5`、`S[5]=3`.

如果需要知道`x`是否在集合中,则只需要测试`D[S[x]]`是否与`x`相等即可.为了追加到`D`,我们需要追踪目标集合的大小`n`(不是容量).每次插入操作只需要递增`n`,而清除则只需要将`n`设置为 0 即可.

## 实现

稀疏集合只适用于无符号整数,我们定义模板如下:

```C++
template <typename T>
class SparseSet
{
    static_assert(std::is_unsigned<T>::value, "SparseSet can only contain unsigned integers");
```

然后定义两个集合以及容量和大小:

```C++
private:
    std::vector<T> dense;   //元素的稠密集合
    std::vector<T> sparse;  //映射到元素的稠密集合索引

    size_t size_ = 0;       //目前的大小,即元素个数
    size_t capacity_ = 0;   //目前的容量,取最大值+1.
```

提供一些基本的操作实现:

```C++
public:
    size_t size() const     { return size_; }
    size_t capacity() const { return capacity_; }

    bool empty() const      { return size_ == 0; }

    void clear()            { size_ = 0; }
```

以下是预留容量的实现:

```C++
void reserve(size_t u)
{
    if (u > capacity_)
    {
        dense.resize(u, 0);
        sparse.resize(u, 0);
        capacity_ = u;
    }
}
```

如果容量不足则需要扩大容量,否则无法表达更大的整数.

之后是实现是否存在某个整数的判断:

```C++
bool has(const T &val) const
{
    return val < capacity_ &&  //整数是否超出容量
        sparse[val] < size_ &&  //索引是否有效
        dense[sparse[val]] == val; //D[S[x]]==x
}
```

然后是插入操作:

```c++
void insert(const T &val)
{
    if (!has(val)) //已有则无需操作
    {
        if (val >= capacity_) //超范围则扩大容量
            reserve(val + 1);

        dense[size_] = val;
        sparse[val] = size_;
        ++size_;
    }
}
```

我们自然希望可以单独移除某个整数,这里为了能够在常数时间完成,我们采用将目标值和最后的值替换,然后缩小集合大小的方式:

```C++
void erase(const T &val)
{
    if (has(val))
    {
        dense[sparse[val]] = dense[size_ - 1];
        sparse[dense[size_ - 1]] = sparse[val];
        --size_;
    }
}
```

以上就是稀疏集合的核心实现.

然后我们既然提供了容器,也需要为其提供对应的迭代器,这里的实现非常简单,就是将稠密集合的迭代器暴漏出来:

```C++
using iterator       = typename std::vector<T>::const_iterator;
using const_iterator = typename std::vector<T>::const_iterator;

iterator begin()             { return dense.begin(); }
const_iterator begin() const { return dense.begin(); }

iterator end()               { return dense.begin() + size_; }
const_iterator end() const   { return dense.begin() + size_; }
```

[这里](https://gist.github.com/sjgriffiths/06732c6076b9db8a7cf4dfe3a7aed43a)是完整实现.

使用方式如下:

```C++
SparseSet<unsigned> ss;
ss.insert(5);
ss.insert(1000);
ss.insert(54);
ss.erase(5);
ss.insert(28);

for (auto &x : ss)
    cout << x << " ";
cout << endl;

for (auto it = ss.begin(); it != ss.end(); ++it)
    cout << *it << " ";
cout << endl;
```

输出结果为:

```bat
54 1000 28
54 1000 28
```
