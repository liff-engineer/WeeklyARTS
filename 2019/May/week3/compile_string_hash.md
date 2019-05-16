# C++编译期字符串常量哈希

游戏行业为了性能,总有一些神奇的东西出来,譬如我读`ECS`设计的一种实现-[entt](https://github.com/skypjack/entt)的源代码时,上次发现了有`Sparse Set`这种数据结构,这次又再其中看到了`hashed_string`.

我们知道将字符串进行`hash`操作,然后生成的`hash`值(整数)可以直接进行比较操作,这比字符串比较效率要高.但是这样也存在一些问题,如果我们以`hash`值为键,对调试是非常不友好的,因为我们不知道这个到底代表了什么...

于是就有人利用 C++的编译期特性,设计了`hashed_string`这种东西.如果我们的字符串是编译期常量,则可以直接生成对应的`hash`,连运行时计算都省掉了,而且还能够看到对应的字符串信息.同时,借助于`constexpr`,这种结构在运行时也是可用的.

## 哈希函数的选择

在`entt`种使用的是[FNV-1a](https://en.wikipedia.org/wiki/Fowler%E2%80%93Noll%E2%80%93Vo_hash_function).其计算方式如下:

```txt
hash = FNV_offset_basis
for each byte_of_data to be hashed
    hash = hash XOR byte_of_data
    hash = hash × FNV_prime
return hash
```

其中`FNV_offset_basis`和`FNV_prime`为常量,如果要计算出`32`位无符号整数`hash`值,则:

- `FNV prime = 16777619`
- `FNV offset basis = 2166136261`

如果要计算出`64`位无符号整数`hash`值,则:

- `FNV prime = 1099511628211`
- `FNV offset basis = 14695981039346656037`

我们可以以如下方式实现:

```C++
namespace detail
{
    template<typename THash>
    struct fnv1a_constant;

    template<>
    struct fnv1a_constant<std::uint32_t>
    {
        static constexpr std::uint32_t prime = 16777619;
        static constexpr std::uint32_t offset = 2166136261;
    };

    template<>
    struct fnv1a_constant<std::uint64_t>
    {
        static constexpr std::uint64_t prime = 1099511628211ull;
        static constexpr std::uint64_t offset = 14695981039346656037ull;
    };

    template<typename THash>
    inline constexpr THash fnv1a_hash(const char* const str,const THash result = fnv1a_constant<THash>::offset)
    {
        return (str[0] == '\0')? result:
            fnv1a_hash(str+1,(result ^ static_cast<THash>(str[0]))*fnv1a_constant<THash>::prime);
    }
}
```

这时就可以以如下方式获取对应的`hash`值了:

```C++
auto hash = detail::fnv1a_hash<std::uint32_t>("liff.engineer@gmail.com");
```

在[Compile time string hashing](https://stackoverflow.com/questions/2111667/compile-time-string-hashing)中选用的是`CRC32`.

## `hashed_string`实现

我们首先声明模板类:

```C++
template<typename THash>
class hashed_string
{
private:
    THash  hash;
    const char* str;
};
```

然后为其提供构造函数:

```C++

//默认构造函数
constexpr hashed_string() noexcept
    :hash{},str{nullptr}
{};

//字符串常量构造函数
template<std::size_t N>
constexpr hashed_string(const char(&str)[N]) noexcept
    :hash{detail::fnv1a_hash<THash>(str)},str{str}
{}
```

然后为其实现数据访问接口:

```C++

constexpr const char* data() const noexcept{
    return str;
}

constexpr THash value() const noexcept{
    return hash;
}
```

在一些场景下需要自动转换,这里为其提供相应实现:

```C++
constexpr operator const char*() const noexcept { return str; };

constexpr operator THash() const noexcept {return hash;};
```

然后是比较操作:

```C++
constexpr bool operator==(const hashed_string& other) const noexcept{
    return hash == other.hash;
}
```

以上在编译期可用,为了避免直接传递`const char*`来进行构造,需要阻止对应的构造函数,这里通过包裹辅助类来实现:

```C++

private:
    struct const_wrapper{
        constexpr const_wrapper(const char* str) noexcept:str{str}{};
        const char* str;
    };

public:
    explicit constexpr hashed_string(const_wrapper wrapper) noexcept
        :hash{detail::fnv1a_hash<THash>(wrapper.str)},str{wrapper.str}{};
```

如果想要给其它运行期内容使用,则可以提供静态接口来计算:

```C++
template<std::size_t N>
inline static constexpr THash to_value(const char (&str)[N]) noexcept{
    return detail::fnv1a_hash<THash>(str);
}

inline static constexpr THash to_value(const_wrapper wrapper) noexcept{
    return detail::fnv1a_hash<THash>(wrapper.str);
}
```

## 其他

基于上述技术也可以实现对应字符串的`switch_case`操作.

## 参考

- [Compile Time String Hashing](https://xueyouchao.github.io/2016/11/16/CompileTimeString/)
- [Compile time string hash](https://vincentcalisto.com/2018/06/22/compile-time-string-hash/)
