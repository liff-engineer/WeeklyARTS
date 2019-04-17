# C++排序算法

C++的 STL 中定义了以下几种排序算法:

- `sort`
- `partial_sort`
- `stable_sort`
- `nth_element`

## `std::sort`

对范围内的元素进行升序排序.相等元素的顺序是不保证的.

这个是最常用的排序操作,可以指定`compare`操作来变成升序等.如果需要全排序,且相等元素的相对顺序无要求则可以使用.

譬如如下代码:

```C++
std::array<int, 10> s = {5, 7, 4, 2, 8, 6, 1, 9, 0, 3};

// sort using the default operator<
std::sort(s.begin(), s.end());
for (auto a : s) {
    std::cout << a << " ";
}
std::cout << '\n';
```

排序结果为:

```bat
0 1 2 3 4 5 6 7 8 9
```

## `std::partial_sort`

对范围内的元素进行升序排序,只排序到前`N`个元素.相等元素的相对顺序是不保证的.剩余元素的顺序是不确定的.

假设只需要最大/最小的前`N`个元素,那么是不需要全部排序完成的,这时候就可以使用该算法.

譬如如下代码:

```C++
std::array<int, 10> s{5, 7, 4, 2, 8, 6, 1, 9, 0, 3};

std::partial_sort(s.begin(), s.begin() + 3, s.end());
for (int a : s) {
    std::cout << a << " ";
}
```

排序结果为:

```bat
0 1 2 7 8 6 5 9 4 3
```

可以看到,前三个元素`0,1,2`排序完成,其他顺序不确定.

## `std::stable_sort`

该算法功能与`std::sort`类似,不同之处在于,该算法会保证相等元素的相对顺序是保持不变的.

例如如下代码:

```C++
struct Employee
{
    int age;
    std::string name;  // Does not participate in comparisons
};

bool operator<(const Employee & lhs, const Employee & rhs)
{
    return lhs.age < rhs.age;
}

int main()
{
    std::vector<Employee> v =
    {
        {108, "Zaphod"},
        {32, "Arthur"},
        {108, "Ford"},
    };

    std::stable_sort(v.begin(), v.end());

    for (const Employee & e : v)
        std::cout << e.age << ", " << e.name << '\n';
}
```

输出为:

```bat
32, Arthur
108, Zaphod
108, Ford
```

## `std::nth_element`

针对给定范围进行部分排序,确保这个范围被给定元素分区.这个相对比较难理解. 我们先来看以下示例:

```C++
std::vector<int> v{5, 6, 4, 3, 2, 6, 7, 9, 3};

std::nth_element(v.begin(), v.begin() + v.size()/2, v.end());
std::cout << "The median is " << v[v.size()/2] << '\n';

std::nth_element(v.begin(), v.begin()+1, v.end(), std::greater<int>());
std::cout << "The second largest element is " << v[1] << '\n';
```

输出结果为:

```bat
The median is 5
The second largest element is 7
```

在第一次排序动作时,我们指定了中间位置为分隔,这就会导致`v`的前半部分小,后半部分大,中值就是`v[v.size()/2]`.

在第二次排序动作时,我们指定了第二个位置为分隔,同时按照降序排序,那么`v`左侧都是比`v[1]`大的,右侧都是比`v[1]`小的,也就是说,通过这个算法,能够拿到从大到小的第`n`个元素.

`std::nth_element`适用于我们不在乎具体的顺序,而只是想知道第`n`个元素的情况.

## 总结

用了这么久的 STL,看过很多次排序相关的算法,每次都是眼高手低,直到看到[What's the practical difference between std::nth_element and std::sort?](https://stackoverflow.com/questions/10352442/whats-the-practical-difference-between-stdnth-element-and-stdsort)才发现自己不懂 STL,于是复习一遍,搞清楚排序算法的差别和应用场景.

之前看到别人使用 STL 部件组装各种算法,确实 STL 提供了足够好的基础设施,可以直接使用,也可以用来打造自己的算法.非常强大.
