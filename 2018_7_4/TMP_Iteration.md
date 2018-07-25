# [模板元编程:迭代比递归要好](https://quuxplusone.github.io/blog/2018/07/23/metafilter/)

原文见标题链接,本文将会对类型filter的实现进行分析,讲述其中用到的各种模板技术

## 需求

实现`filter`这种`metafunction`,可以将类型列表根据过滤函数过滤掉不满足条件的,得到新的类型列表,测试用例如下：

```C++
using Input = std::tuple<int, int&, char, char&>;
using Output = std::tuple<int&, char&>;
static_assert(std::is_same_v<
    filter<std::is_reference, Input>::type,
    Output
>);
```

注意`static_assert(bool_constexpr)`这种语法`C++17`才支持,如果你是`C++11`的编译器,书写方式应该是`static_assert(bool_constexpr,message)`。

可以看到,将`Input`根据是否是引用,过滤出的类型列表应当只保留了引用类型。

## 使用`tuple_cat`的初步实现

### 实现思路

1. 使用递归将类型列表拆分处理
2. 使用`metafunction`过滤类型得到`true`或者`false`
3. 如果为`true`,则使用`tuple_cat`合并当前类型和后续类型列表结果
4. 如果为`false`,则直接使用后续类型列表结果

### 实现解析-递归

```C++
//声明
template<template<typename> class P,typename S>
struct filter;

//实现体
template<template<typename> class P, typename H,typename... Ts>
struct filter<P, std::tuple<H, Ts...>>{
    using type = ....;//待完成 eg.typename filter<P,std::tuple<Ts...>>::type;
};

//递归终止条件
template<template<typename> class P>
struct filter<P, std::tuple<>> {
    using type = std::tuple<>;
};
```

以上就是一个递归结构,包含声明、实现和终止条件三部分,当类型列表为空时使用`struct filter<P, std::tuple<>>`的结果,而`struct filter<P, std::tuple<H, Ts...>>`则会不断调用`struct filter<P, std::tuple<H, Ts...>>`直到模板实例化为`struct filter<P, std::tuple<>>`结果终止,递归过程如下：

1. `filter<P,std::tuple<int,...>`
2. `filter<P,std::tuple<int&,...>`
3. `filter<P,std::tuple<char,...>`
4. `filter<P,std::tuple<char&>`
5. `filter<P,std::tuple<>`

到达终止条件后往上返回.

### 条件处理`std::conditional_t`

使用`std::conditional_t`根据`metafunction`结果使用不同的类型,从而可以实现移除掉特定类型的效果:

```C++
template<template<typename> class P, typename H,typename... Ts>
struct filter<P, std::tuple<H, Ts...>>{
    using type =  std::conditional_t<P<H>::value,
                    ..., //如果为true,则使用该处的类型
                    ...  //如果为false,则使用该处的类型
                    >;
};
```

当为`false`的时候,无需合并类型,直接使用后续类型列表的结果即可：

```C++
template<template<typename> class P, typename H,typename... Ts>
struct filter<P, std::tuple<H, Ts...>>{
    using type =  std::conditional_t<P<H>::value,
                    ..., //如果为true,则使用该处的类型
                    typename filter<P,std::tuple<Ts...>::type
                    >;
};
```

### 合并类型`tuple_cat`

这里需要借用`decltype`来推到合并出的类型,而且需要借用到`std::declval`在编译期构造出类型实例来正确推断类型:

```C++
decltype(std::tuple_cat(
    std::declval<std::tuple<H>>(),
    std::declval<typename filter<P,std::tuple<Ts...>>::type>()
));
```

通过这种方式可以将当前类型`H`与后续类型序列的`filter`合并起来。

### 最终实现

```C++
template<template<typename> class P,typename S>
struct filter;

template<template<typename> class P, typename H,typename... Ts>
struct filter<P, std::tuple<H, Ts...>> {
    using type = std::conditional_t<
        P<H>::value,
        decltype(std::tuple_cat(
            std::declval<std::tuple<H>>(),
            std::declval<typename filter<P, std::tuple<Ts...>>::type>()
        )),
        typename filter<P, std::tuple<Ts...>>::type
    >;
};

template<template<typename> class P>
struct filter<P, std::tuple<>> {
    using type = std::tuple<>;
};
```

## 快一点儿的实现

采用上述方式实现的`filter`,根据分析的过程,由于`std::conditional_t`的原因,可以发现需要实例化很多模板类型,即使过程中并不需要。

如果减少模板实例化的数量？可以使用如下方式替代`std::conditional_t`:

```C++
template<bool>
struct helper{
    template<typename Ts...>
    xxxx;
};

template<>
struct helper<false>{
    template<typename Ts...>
    xxxx;
};
```

当`helper`的模板参数为`true`或者`false`时,其使用的是偏特化的`helper`内部的模板类,而`helper`只会根据情况实例化最多两个：`helper<true>`和`helper<false>`。

那么实现就可以改写成如下方式:

```C++
template<template<typename> typename P,typename S>
struct filter;

template<bool>
struct helper {
    template<template<typename> typename P,typename H,typename... Ts>
    using type = decltype(std::tuple_cat(
        std::declval<std::tuple<H>>(),
        std::declval<typename filter<P, std::tuple<Ts...>>::type>()
    ));
};

template<>
struct helper<false> {
    template<template<typename> typename P, typename H, typename... Ts>
    using type = typename filter<P, std::tuple<Ts...>>::type;
};

template<template<typename> class P, typename H, typename... Ts>
struct filter<P, std::tuple<H, Ts...>> {
    using type =  typename helper<P<H>::value>::template type<P,H,Ts...>;
};

template<template<typename> class P>
struct filter<P, std::tuple<>> {
    using type = std::tuple<>;
};
```

## 更好的实现-使用迭代器

通过上面的分析可以知道,在递归过程中需要实例化非常多不同的`filter`,思考一下,其实并无必要,将类型`T`根据`metafunction`映射成`std::tuple<>`或者`std::tuple<T>`,然后将结果合并成新类型即可:

```C++
template<template<typename> typename P, typename S>
struct filter;

//类型映射
template<bool>
struct zero_or_one {
    template<typename E>
    using type = std::tuple<E>;
};

template<>
struct zero_or_one<false> {
    template<typename E>
    using type = std::tuple<>;
};

//迭代而非递归
template<template<typename> typename P,typename... Es>
struct filter<P, std::tuple<Es...>> {
    using type = decltype(std::tuple_cat(
        std::declval<typename zero_or_one<P<Es>::value>::template type<Es>>()...
    ));
};
```
