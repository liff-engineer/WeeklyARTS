# [A new look on template meta-programming](https://meetingcpp.com/mcpp/slides/2018/tmp.pdf)

这是在Meeting C++ 2018中的一篇演讲,从中可以根据一个示例来展现C++中模板元编程的新面貌,也让我们得以了解C++20中`concept`会对C++模板编程产生的影响.

> Make your code readable. Pretend the next person who looks at your code is a psychopath and they know where you live.
>
> Philip Wadler

## 元编程

首先看一看元编程中非常重要的组成部分-`meta-function`:

- 编译期执行
- No input or output
- 不仅仅是将值映射成值

例如针对`std::vector<int>`,是由模板`std::vector`和模板参数`int`组合而成,如果想要获取`std::vector`所存储的数据类型,可以据此写出一个`meta-function`：

```C++
template<typename T>
using inner_type_t = typename T::value_type;

inner_type_t<std::vector<int>;
```

在上述代码中:

- 函数参数:`template<typename T>`
- 函数名: `using inner_type_t =`
- 函数结果: `typename T::value_type;`
- 函数调用: `inner_type_t<std::vector<int>>`

以上是使用`template alias`模板别名实现的,常规的实现语法如下:

```C++
template<typename T>
class inner_type {
    using type = typename T::value_type;
};

inner_type<std::vector<int>>
inner_type<std::vector<int>>::type
```

其中`inner_type<std::vector<int>>::type`是对函数结果的访问.

自然也可以为函数参数提供默认值,譬如:

```C++
template<typename T,typename Expected = void>
class expect_inner {
    using type = typename T::value_type;
    constexpr bool value = std::is_same_v<type,Expected>;
};

expect_inner<std::vector<int>>::type
expect_inner<std::vector<int>>::value
```

可以利用之前提到的模板别名提供更简洁的`meta-function`结果访问:

```C++
template<typename T,typename E = void>
using expect_inner_t = typename expect_inner<T,E>::type;

template<typename T,typename E = void>
constexpr bool expect_inner_v =  expect_inner<T,E>::value;
```

可以看到,`meta-function`是作用于类型上的`function`:

- 对类型进行转换
- 映射类型到值
- 映射值到类型

那么这个有什么用呢？假设要为集合类型实现`sum`操作:

```C++
template<typename C>
??? sum(const C& collection){
    return std::accumulate(...);
}
```

面临的问题是,这个`sum`函数的返回值是什么类型?我们可以添加一个模板参数来指定返回值类型,也可以采用`std::accumulate`的方式增加`init`函数参数来确定,或者说?能不能利用之前的`inner_type`?

```C++
template <typename C,typename Val = inner_type_t<C>>
Val sum(const C& collection)
{
    const auto begin = std::begin(collection);
    const auto end = std::end(collection);
    if (begin == end) {
        return Val{}; // or throw an exception
    } else {
        const auto init = *begin;
        return std::accumulate(++begin, end, init);
    }
}
```

这样就可以应用到序列容器了.但是有一个问题,如果容器没有`value_type`定义呢?

这时就需要根据迭代器获取容器内容的类型,譬如:

```C++
template<typename T>
using inner_type_t = decltype(*std::begin(std::declval<T>()));
```

不过上述写法有一些问题:

```C++
template<typename... T>
class print_types;

print_types<inner_type_t<std::vector<bool>>,
    inner_type_t<std::vector<int>>>();
```

在编译时gcc会报错:`invalid use of incomplete type'class print_type<bool, const int&>'`.

也就是说需要在获取容器内容类型时将`const`、`&`等修饰移除:

```C++
template<typename T>
using inner_type_t = std::remove_cvref_t<decltype(*std::begin(std::declval<T>()))>;
```

这样针对任何带迭代器的序列容器`sum`均可以工作了.

## 要求

现在有两种`inner_type_t`的实现,到底哪种更好?是使用`value_type`的还是迭代器的? 这里实际上有两种要求或者说定义：

- `HasValueType`

```C++
template<typename C>
concept HasValueType =
    requires{ typename C::value_type;};
```

- `HasBeginIterator`

```C++
template<typename C>
concept HasBeginIterator =
    requires(C c) { *std::begin(c);};
```

根据两种要求,可以分别实现:

```C++
template<typename C>
    requires HasValueType<C>
auto sum(C c){
    ...
}

template<typename C>
    requires not HasValueType<C>
            and HasBeginIterator<C>
auto sum(C c){
    ...
}
```

或者说使用`if constexpr`将其合并成一个实现:

```C++
template<typename T>
auto sum(const T& coll){
    if constexpr(HasValueType<T>){
        ...
    }
    else if constexpr(HasBeignIterator<T>){
        ...
    }
}
```

可以将结果类型获取实现为辅助类:

```C++
template <typename T>
auto inner_type_helper(T&& t)
{
    if constexpr (HasValueType<T>) {
        return std::declval<typename T::value_type>();
    } else if constexpr (HasBeginIterator<T>) {
        return *std::begin(t);
    } else {
        static_assert(fail<T>,”Unable to deduce the value type”);
    }
}

template <typename T>
using inner_type = decltype(inner_type_helper(std::declval<T>());
```

这时如下代码及运行结果为:

```C++
int[] xs { 1, 2, 3 };
print_types<
        inner_type<std::vector<bool>>,
        inner_type<std::vector<int>>,
        inner_type<decltype(xs)>
    >

bool
int
int
```

而我们对于能够处理的对象也可以写出对应要求:

```C++
template <typename Begin, typename End>
concept Range =
    std::is_copy_constructible_v<Begin>
    and requires (Begin b, End e) {
        *b;
        ++b;
        b != e;
        b == e;
    };
```

这些代码在C++20或许可以编译,但是回到现实世界,目前的编译器不支持这些约束,那么该怎么办呢?

## 引入`void`

```C++
template<typename...>
using void_t = void;
```

这个`void_t`是做什么用的? -- **SFINAE**.

应用`void_t`实现`HasValueType`如下:

```C++
//定义1
template<typename T,typename = void_t<>>
struct has_value_type:std::false_type{};

//定义2
template<typename T>
struct has_value_type<T,void_t<typename T::value_type>>:std::true_type{};
```

定义1为主模板,定义2为模板偏特化,当类型`T`满足`typename T::value_type`时则`has_value_type`被实例化为定义2,否则被实例化为类型1.

通用的方式来判断是否有迭代器:

```C++
template <typename T,typename = void_t<>>
struct is_iterable : std::false_type {};

template <typename T>
struct is_iterable<
     T,
    void_t<
        decltype(*std::begin(std::declval<T>())),
        decltype(std::end(std::declval<T>())),
        ⋯
        >
    > : std::true_type {};
```

## `detector`惯用法

以上的示例只是展示了检测类型是否有`value_type`或者迭代器的方法,实际上针对检测类型还有各种各样的需求,有没有办法能够提供统一的方法来检测?

Walter E. Brown 发明了`detector`:

```C++
template<typename Def,typename Void,
    template<typename...> typename Op,
    typename... Args>
struct DETECTOR {
    using value_t = std::false_type;
    using type = Def;
};

template<typename Def,
    template<typename...> typename Op,
    typename... Args>
struct DETECTOR<Def,void_t<Op<Args...>>,Op,Args...> {
    using value_t = std::true_type;
    using type = Op<Args...>;
};

template<template<typename...> typename Op,
    typename... Args>
using is_detected = typename DETECTOR<nonesuch,void,Op,Args...>::value_t;

template<template<typename...> typename Op,
    typename... Args>
using detected_t = typename DETECTOR<nonesuch,void,Op,Args...>::type;
```

这时就可以很方便地来根据迭代器判断结果类型了:

- 判断`begin`

```C++
template<typename T>
using nonmember_begin = decltype(std::begin(std::declval<T>()));

if constexpr (is_detected_v<nonmember_begin,std::string>){
    ...
}
```

- 判断`end`

```C++
template <typename T>
using nonmember_end = decltype(std::end(std::declval<T>()));

if constexpr (is_detected_v<nonmember_begin, std::string> &&
            is_detected_v<nonmember_end, std::string>) {
            ⋯
}
```

- 解引用

```C++
template <typename T>
using dereference = decltype(*(std::declval<T>()));

if constexpr (
    is_detected_v<free_begin, std::string> &&
    is_detected_v<free_end, std::string> &&
    is_detected_v<dereference, detected_t<free_begin, std::string>>) {
    ⋯
}
```

之前定义的`range`实现：

```C++
template <typename T>
using increment = decltype(++(std::declval<T>()));

template <typename T>
using copy_assign = decltype(std::declval<T&>() =
std::declval<const T&>());

template <typename T>
constexpr bool is_input_iterator =
                    is_detected_v<dereference, T> &&
                    is_detected_v<increment, T> &&
                    is_detected_v<copy_assign, T>;

template <typename T, typename U = T>
using eq_compare = decltype(
            (std::declval<T>() == std::declval<U>()) &&
            (std::declval<T>() != std::declval<U>()));

template <typename R>
constexpr bool is_input_range =
        is_input_iterator<
        detected_t<free_begin, R>> &&
        is_detected_v<eq_compare,
            detected_t<free_begin, R>,
            detected_t<free_end, R>
>;
```

针对`detector`还有以下一些常用法:

```C++
template <typename Def, template<typename...> typename Op, typename... Args>
using detected_or = DETECTOR<Default, void, Op, Args...>;

template <typename Expected,template <typename...> typename Op,typename... Args>
using is_detected_exact =is_same<Expected, detected_t<Op, Args...>>;

template <typename To,template<typename...> typename Op,typename... Args>
using is_detected_convertible = is_convertible<detected_t<Op, Args...>, To>;
```

## 总结

这个演讲从一个视角讲述了在现有C++标准支持之下如何实践模板元编程,相比C++11之前的模板元编程确实简化了许多,尤其是其中演示的`detector`惯用法,使得使用C++开发软件有了更多想象空间.