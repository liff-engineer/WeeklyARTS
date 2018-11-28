# [C++17模拟Python中的enumerate](http://reedbeta.com/blog/python-like-enumerate-in-cpp17/)

在Python中有个内置函数`enumerate()`,当你遍历对象时,可以获取索引及其内容,例如:

```Python
for i, thing in enumerate(listOfThings):
    print("The %dth thing is %s" % (i, thing))
```

通常遍历`listOfThings`会给你`thing`,但是没有`i`,然而在一些情况下两者都需要.

C++的`range-for`和Python的`for`循环比较类似,那么能不能在C++中实现类似`enumerate`的写法呢?

在C++17中添加了结构化绑定这种特性,使得可以将tuple类型分解到不同的变量,如果迭代器返回的是`std::tuple<index,object>`,那么就可以模拟出类似的写法:

```C++
std::vector<std::tuple<index,object>> things;
for(auto [idx,thing]:things){
    //...
}
```

如果实现`enumerate()`将`range-for`的迭代器包裹成另外一种迭代器,并为其增加`index`信息,就可以这样用：

```C++
std::vector<object> things;
for(auto [i,thing]:enumerate(things)){
    //...
}
```

首先,根据目标迭代器实现带`index`的迭代器:

```C++
template<typename TIter>
struct iterator
{
    std::size_t i;
    TIter       iter;
    bool        operator !=(iterator const& other) const { return iter != other.iter;  };
    void        operator ++() {  ++i;++iter; }
    auto        operator *() const {  return std::tie(i,*iter); }
};
```

然后为其实现迭代器包裹(仿容器):

```C++

template<typename T>
struct iterable_wrapper
{
    T iterable;
    auto begin {  return iterator{0,std::begin(iterable)}; };
    auto end { return {0,std::end(iterable)}; };
};

```

然后是`enumerate()`函数:

```C++

template<typename T,typename TIter = decltype(std::begin(std::declval<T>())),typename = decltype(std::end(std::declval<T>()))>
constexpr auto enumerate(T && iterable){
    return iterable_wrapper<T>{ std::forward<T>(iterable) };
}
```

完整代码如下:

```C++
template<typename T,typename TIter = decltype(std::begin(std::declval<T>())),typename = decltype(std::end(std::declval<T>()))>
constexpr auto enumerate(T && iterable){
    struct iterator
    {
        std::size_t i;
        TIter       iter;
        bool        operator !=(iterator const& other) const { return iter != other.iter;  };
        void        operator ++() {  ++i;++iter; }
        auto        operator *() const {  return std::tie(i,*iter); }
    };

    struct iterable_wrapper
    {
        T iterable;
        auto begin {  return iterator{0,std::begin(iterable)}; };
        auto end { return {0,std::end(iterable)}; };
    };
    return iterable_wrapper{ std::forward<T>(iterable) };
}
```

注意`enumerate()`模板参数应用了SFINAE来保证能够正确应用到可迭代对象.

而在`range-v3`-C++20中range库的参考实现中,已经实现了该操作,详见[Add "enumerate" view](https://github.com/ericniebler/range-v3/pull/941).

在`range-v3`中的实现相对来讲更为简单,可见其强大的表达能力,值得关注.