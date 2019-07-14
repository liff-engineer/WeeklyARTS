# [富有表现力的 C++模板元编程](https://www.fluentcpp.com/2017/06/02/write-template-metaprogramming-expressively/)

有两种 C++开发者,一种喜欢元编程,然后是另外一种.

虽然我认为自己处在狂热爱好者的阵营中,我遇到的是比模板元编程多得多的开发者对其并没有多少兴趣,或者甚至发现它令人恶心.你属于哪个阵营呢?

在我看来,模板元编程不被许多人选择的其中一个原因是,它经常晦涩难懂.有时候它看起来像黑暗魔法,只能为可以理解这种方言的非常特殊的开发者所使用.当然,有时候也能够看到易懂的模板元编程内容,但是从平均水平上看,我发现它比普通代码要难于理解.

我想要指出的是,模板元编程并不是必须以这种方式实现.

我将为你展示如何使得模板元编程代码更具表现力.这并不是什么高深技术.

模板元编程通常被描述为 C++语言中的语言.那么为了使得模板元编程更具表现力,我们需要应用普通代码中一样的的规则.为了说明,我们将采用一段代码,只有最勇敢的人才能够理解,并在其上应用以下两个表达性原则:

- 选择好的名字，
- 分离抽象层次.

我告诉过你,这并不是什么高深技术.

## 代码的目的

我们将实现一个 API 用来检查表达式对于给定类型是否有效.

例如给定类型 `T`,我们想要直到 `T` 是否式可自增的,这就是说,对于类型 `T` 的对象 `t`,以下表达式:

```C++
++t
```

是否有效.如果 `T` 是`int`,则表达式有效,如果`T`是`std::string`,则表达式无效.

典型的可能实现如下:

```C++
template< typename, typename = void >
struct is_incrementable : std::false_type { };

template< typename T >
struct is_incrementable<T,
           std::void_t<decltype( ++std::declval<T&>() )>
       > : std::true_type { };
```

我不知道你有多少次需要复制这段代码,但是我在上面花费了大量时间.让我们看一看如何重构这段代码使其能够更快地理解.

平心而论,我必须说,要了解模板元编程,你需要了解一些结构.有点儿像你需要知道`if`,`for`和函数重载去理解 C++,模板元编程也有一些先决条件,例如`std::true_type`和 SFINAE. 如果你不知道,不要担心,我会在过程中解释.

## 基本

如果你已经熟悉了模板元编程,你可以跳到下一节.

我们的目标是可以使用如下方式查询一个类型:

```C++
is_incrementable<T>::value
```

其中`is_incrementable<T>`是个类型,它有个公开的布尔成员`value`,当`T`是可递增是为`true`,否则为`false`.

我们会使用到`std::true_type`.这是个只有公开布尔成员`value`为`true`的类型.如果`T`可以递增,我们就会让`is_incrementable<T>`继承自它.如你所料,如果不能递增,就会继承自`std::false_type`.

为了允许两种可能的定义,我们使用到模板特化.一种特化继承自`std::true_type`,另外一种继承自`std::false_type`.那么我们的解决方案类似于如下:

```C++
template<typename T>
struct is_incrementable : std::false_type{};

template<typename T>
struct is_incrementable<something that says that T is incrementable> : std::true_type{};
```

特化将会基于 SFINAE.简单来说,在特化中,我们会写一些代码来尝试自增`T`.如果`T`确实可自增,代码会有效,特化会被实例化(因为它总是比主模板优先级高).这一个将继承自`std::true_type`.

从另一方面说,如果`T`不能自增,则特化不会有效.这种场景 SFINAE 表明无效的实例不会报错.它只是被丢弃,主模板剩下唯一的选项,继承自`std::false_type`的那个.

## 选择好的名字

之前的实现用到了`std::void_t`.这个结构出现在 C++17 中,不过我们可以在 C++11 中很容易实现:

```C++
template<typename...>
using void_t = void;
```

`void_t`只是实例化传递给它的模板类型,但是从不使用.它更像是一个模板的代理母亲.

为了让代码工作,我们以如下方式书写特化:

```C++
template<typename T>
struct is_incrementable<T, void_t<decltype(++std::declval<T&>())>> : std::true_type{};
```

为了理解模板元编程,你还需要理解`decltype`和`declval`.`decltype`返回其参数的类型,`declval<T>()`则在`decltype`表达式中实例化类型`T`的对象(这个非常有用,因为我们不需要知道类型 T 的构造函数).也就是说`decltype(++std::declval<T&>())`是在`T`上调用`operator++`后的返回值类型.

正如上述所说,`void_t`只是用来实例化这个返回类型的辅助.它不携带任何数据或者行为,只是一种实例化返回类型的启动板.

如果自增表达式无效,则使用`void_t`的实例失败,SFINAE 起作用,`is_incrementable`则找到继承自`std::false_type`的主模板.

这是个非常棒的机制,但是我不喜欢这个名字.在我看来,这个绝对是错误的抽象层次:它实现为`void`,但是它真正的含义是试图实例化一个类型.通过将这部分信息添加到代码中,模板元编程表达式立即清晰起来:

```C++
template<typename...>
using try_to_instantiate = void;

template<typename T>
struct is_incrementable<T, try_to_instantiate<decltype(++std::declval<T&>())>> : std::true_type{};
```

给出的特化有两个模板参数,主模板因而也必须是两个参数.为了避免用户传递这个参数,我们提供了默认类型`void`.问题是如何命名这个辅助参数?

一种方式是完全不命名,就如上述代码:

```C++
template<typename T, typename = void>
struct is_incrementable : std::false_type{};
```

这种一种方式来传达"不要看这个,这个不相干,存在只是为了技术原因",我认为是合理的.另一个选项是给其提供名字来说明其含义.第二个参数是**尝试**在特化中实例化表达式,我们可以将这个信息通过名字表述出来,这时完整的解决方案如下:

```C++
template<typename...>
using try_to_instantiate = void;

template<typename T, typename Attempt = void>
struct is_incrementable : std::false_type{};

template<typename T>
struct is_incrementable<T, try_to_instantiate<decltype(++std::declval<T&>())>> : std::true_type{};
```

## 分离抽象层次

我们可以在这里结束了.但是`is_incrementable`中的代码还是太技术了,而且可以被提取到更低的抽象层次.此外,当我们需要相同的技术来检查其它表达式时,这会非常便利,同时也可以避免代码重复.

我们最终将会得到类似于`is_detected`这种实验特性.

在上述代码中变化最大的是`decltype`表达式部分.我们将其提取为模板参数.请注意,我们需要小心挑选名称:这个参数表现的是表达式的类型.

这个表达式依赖模板参数.所以不能简单地使用`typename`,而是需要使用模板:

```C++
template<typename T, template<typename> class Expression, typename Attempt = void>
struct is_detected : std::false_type{};

template<typename T, template<typename> class Expression>
struct is_detected<T, Expression, try_to_instantiate<Expression<T>>> : std::true_type{};
```

这时`is_incrementable`实现可以改写为:

```C++
template<typename T>
using increment_expression = decltype(++std::declval<T&>());

template<typename T>
using is_incrementable = is_detected<T, increment_expression>;
```

### 允许在表达式中使用多种类型

目前为止,我们使用的表达式只牵扯到一种类型,如果能够传递多种类型给表达式会更好.譬如检测两个类型是否是可赋值的.

为了完成这个能力,我们需要使用可变参数模板来表达表达式中使用到的类型.我们可能会添加`...`来实现,但是这不能工作:

```C++
template<typename... Ts, template<typename...> class Expression, typename Attempt = void>
struct is_detected : std::false_type{};

template<typename... Ts, template<typename...> class Expression>
struct is_detected<Ts..., Expression, try_to_instantiate<Expression<Ts...>>> : std::true_type{};
```

这是因为`typename... Ts`会吃掉后面所有的模板擦拭你,所以它需要被放到最后.但是默认的模板参数`Attempt`也需要放到最后,所以我们面临这个问题.

让我们尝试将参数包易懂到模板参数列表最好,然后移除`Attempt`的默认类型:

```C++
template<template<typename...> class Expression, typename Attempt, typename... Ts>
struct is_detected : std::false_type{};

template<template<typename...> class Expression, typename... Ts>
struct is_detected<Expression, try_to_instantiate<Expression<Ts...>>, Ts...> : std::true_type{};
```

但是什么类型传递给`Attempt`了?

首先我想到的是传递`void`,但是这样做会使得调用者困惑:传递`void`意味着什么?与函数的返回类型想法,`void`在模板元编程中并不意味着"无",因为它是种类型.

所以我给给其命名来更好地表达意图.一些人称这种东西为"dummy",但是我喜欢更显式地表明它:

```C++

using disregard_this = void;
```

不过我猜具体的名称是个人品味.

那么检测是否可以赋值实现如下:

```C++
template<typename T, typename U>
using assign_expression = decltype(std::declval<T&>() = std::declval<U&>());

template<typename T, typename U>
using are_assignable = is_detected<assign_expression, disregard_this, T, U>
```

当然,即使有`disregard_this`来帮助读者理解,但是存在理解问题.

一种解决方案是通过间接实现:`is_detected_impl`.在模板元编程中,"impl\_"通常意味着间接实现.虽然我没有觉得这个词很自然,但是我想不出更好的名称,因为很多模板元编程在使用它,知道它很有必要.

我们还可以利用这间接实现来获取`::value`书写,从而使得每次使用时更加简单.

最终实现如下:

```C++
template<typename...>
using try_to_instantiate = void;

using disregard_this = void;

template<template<typename...> class Expression, typename Attempt, typename... Ts>
struct is_detected_impl : std::false_type{};

template<template<typename...> class Expression, typename... Ts>
struct is_detected_impl<Expression, try_to_instantiate<Expression<Ts...>>, Ts...> : std::true_type{};

template<template<typename...> class Expression, typename... Ts>
constexpr bool is_detected = is_detected_impl<Expression, disregard_this, Ts...>::value;
```

这里是如何使用它:

```C++
template<typename T, typename U>
using assign_expression = decltype(std::declval<T&>() = std::declval<U&>());

template<typename T, typename U>
constexpr bool is_assignable = is_detected<assign_expression, T, U>;
```

生成的值可以在编译期和运行期使用.示例如下:

```C++
// compile-time usage
static_assert(is_assignable<int, double>, "");
static_assert(!is_assignable<int, std::string>, "");

// run-time usage
std::cout << std::boolalpha;
std::cout << is_assignable<int, double> << '\n';
std::cout << is_assignable<int, std::string> << '\n';
```

输出如下:

```bat
true
false
```

## 元编程不必如此复杂

确实,要理解模板元编程需要一些前置条件,例如 SFINAE 之类.但是除此之外,没有必要使得使用模板元编程的代码不必要地复杂.

考虑以下单元测试目前的好实践:不能因为这不是生产代码就降低我们的质量标准.这更适用于模板元编程:它就是生产代码.因为这个原因,让我们以对待其它代码的方式对待它,努力使其更具表现力.机会是,更多的人会被吸引,社区更繁荣,想法就会更多.
