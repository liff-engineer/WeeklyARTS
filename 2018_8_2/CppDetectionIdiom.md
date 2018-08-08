# C++ Detection Idiom

在为命令模式设计通用模板库时遇到个需求:根据类型判断是否有对应签名的成员函数,并根据是否存在执行不同的操作.示例如下:

```C++
template<typename T>
struct fn_has_filter {
    using type = std::false_type;
};

template<typename T>
void require_impl(const T& request, std::true_type) {
    std::cout << "require with filter!\n";
}

template<typename T>
void require_impl(const T& request, std::false_type) {
    std::cout << "require without filter!\n";
}

template<typename T>
void require(const T& request) {
    return require_impl(request, fn_has_filter<T>::type{});
}
```

这时就可以以如下方式使用了:

```C++
struct request_with_filter {
    bool filter() {};
};
struct request_without_filter {};

void example() {
    require(request_with_filter{});
    require(request_without_filter{});
}
```

但是如何实现`fn_has_filter`?

## [SFINAE](https://en.cppreference.com/w/cpp/language/sfinae)

>"Substitution Failure Is Not An Error"
>
>This rule applies during overload resolution of function templates: When substituting the deduced type for the template parameter fails, the specialization is discarded from the overload set instead of causing a compile error.

简单来说就是,如果函数模板匹配失败不会引起编译错误。

例如：

```C++
template<typename T>
int f(typename T::B*); //f v1
template<typename T>
int f(T);   //f v2

struct result
{
    using B = int;
}

void example(){
    auto r1 = f<int>(0); //由于T(int)没有::B,因而使用f的v2版本
    auto r2 = f<result>(0);//由于T(result)有result::B,因而使用f的v1版本
}
```

`SFINAE`在之前时判断类型是否有对应方法的主要手段,例如如下判定是否为`Class`的模板实现:

```C++
template<typename T>
class is_class {
    typedef char yes[1];
    typedef char no[2];

    template<typename C> static yes& test(int C::*); // selected if C is a class type
    template<typename C> static no&  test(...);      // selected otherwise
public:
    static bool const value = sizeof(test<T>(0)) == sizeof(yes);
};
```

如果类型`C`有成员方法,则会匹配到返回值类型为`yes`的`test`,注意`value`的写法,`test<T>(0)`中`0`可以匹配成空指针,通过静态方法的返回值类型大小来在编译期得到值。

通过这种方式就可以实现之前的`fn_has_filter`:

```C++
template<typename T>
struct has_filter_helper
{
    typedef char yes[1];
    typedef char no[2];

    template<typename U,bool(U::*)()>
    struct check;

    template<typename C> static yes& test(check<C,&C::filter> *);
    template<typename C> static no&  test(...);
public:
    static bool const value = sizeof(test<T>(0)) == sizeof(yes);
};

template<typename T,bool B>
struct fn_has_filter_impl;

template<typename T>
struct fn_has_filter_impl<T,false> {
    using type = std::false_type;
};

template<typename T>
struct fn_has_filter_impl<T, true> {
    using type = std::true_type;
};

template<typename T>
using  fn_has_filter = fn_has_filter_impl<T, has_filter_helper<T>::value>;
```

## [decltype](https://en.cppreference.com/w/cpp/language/decltype)

之前我们使用`check`模板,限制了可识别的函数签名,那么如果只要求有个名为`filter`的函数改如何处理?

这就使用到了`decltype`,`decltype`用来识别表达式或者`entity`的类型,例如：

```C++
int i = 33;
decltype(i) j = i*2;//根据i推到出其类型为int
```

在C++14之后可以使用如下操作:

```C++
template<typename T,typename U>
auto add(T t,U u) -> decltype(t+u){
    return t+u;
}
```

这样的书写方式可以实现泛型版本的`add`而不用担心返回不恰当的类型。

在这里我们可以使用`decltype`推到出`C::filter`的类型而不需要借助于`check`：

```C++
template<typename T>
struct has_filter_helper
{
    typedef char yes[1];
    typedef char no[2];

    template<typename C> static yes& test(decltype(&C::filter));
    template<typename C> static no&  test(...);
public:
    static bool const value = sizeof(test<T>(0)) == sizeof(yes);
};
```

## [std::declval](https://en.cppreference.com/w/cpp/utility/declval)

之前的`decltype`非常好用,但是有一些限制,例如：

```C++
struct Default {
    int foo() const {
        return 1;
    }
};

struct NonDefault {
    NonDefault(const NonDefault&){}
        int foo() const {
        return 1;
    }
};

void example(){
    decltype(Default().foo()) n1 =1;//n1为整数类型
    decltype(NoDefault().foo()) n2 =n1;//编译错误,NoDefault没有默认构造函数
}
```

可以看到使用`decltype`时,如果需要编译期构造具体类型并调用其操作获取返回值,那么对应类型是有限制的,因而有了`declval`：

> Converts any type T to a reference type, making it possible to use member functions in decltype expressions without the need to go through constructors.

可以看到`declval`使得编译期可以在`decltype`里使用成员函数儿不需要通过构造函数,这使得通用性的类型信息判断成为可能。

对于上述示例可以改写成:

```C++
decltype(std::declval<NonDefault>().foo()) n2 = n1;
```

## 如何判断成员变量的存在

现在可以针对类型`T`使用`declval`和`decltype`来根据名称获取某个成员变量的类型,通过这种方式可以用来判断成员变量是否存在。

让我们来看一看如何实现,首先是如何获取成员变量类型:

```C++
struct result_t
{
    int v;
};

void example() {
    decltype(std::declval<result_t>().v) result = 10;
    std::cout << result << "\n";
}
```

那么如何结合`SFINAE`和上述操作来判断呢?

```C++
template<typename...>
using helper_t = void;

template<typename T,typename V = helper_t<>>
struct fn_has_v:std::false_type {};

template<typename T>
struct fn_has_v<T,helper_t<decltype(std::declval<T>().v)>>:std::true_type{};
```

使用`helper_t`来为成员变量`v`提供类型推导书写位置,`helper_t<>`则为类型推导失败的提供`fallback`,当类型`T`包含成员变量`v`时`SFINAE`起作用得到`std::true_type`,否则得到`std::false_type`。

## [std::void](https://en.cppreference.com/w/cpp/types/void_t)

上一部分可以看到`helper_t`的作用,在很多场景下都可以使用,因而标准提案[N3911](http://www.open-std.org/jtc1/sc22/wg21/docs/papers/2014/n3911.pdf)将`void_t`,在C++17中已经进入标准,如果编译期目前不支持,则可以自行编写,其用法示例如下：

```C++
// primary template handles types that have no nested ::type member:
//主模板,用来处理没有包含::type的成员
template< class, class = std::void_t<> >
struct has_type_member : std::false_type { };

//specialization recognizes types that do have a nested ::type member:
//偏特化的,用来识别包含::type的类型
template< class T >
struct has_type_member<T, std::void_t<typename T::type>> : std::true_type { };
```

`void_t`也可以用来验证表达式是否有效:

```C++
// primary template handles types that do not support pre-increment:
template< class, class = std::void_t<> >
struct has_pre_increment_member : std::false_type { };
// specialization recognizes types that do support pre-increment:
template< class T >
struct has_pre_increment_member<T,
           std::void_t<decltype( ++std::declval<T&>() )>
       > : std::true_type { };
```

## [C++ Detection Idiom](http://www.open-std.org/jtc1/sc22/wg21/docs/papers/2015/n4502.pdf)

由于在很多模板库中需要对类型是否包含某个成员函数等等进行判断,C++标准提案 **N4502** 尝试将这些模板技巧标准化.

譬如原始版本的`detect`辅助模板类:

```C++
template<typename,template<typename> class,typename = std::void_t<>>
struct detect:std::false_type{};

template<typename T,template<typename> class Op>
struct detect<T,Op,std::void_t<Op<T>>>:std::true_type{};
```

可以看到类型`T`即为要检测的模板类型,`Op`即为检测体,类比之前判断是否存在成员变量`v`时使用的`decltype(std::declval<T>().v)`。

现在看一下如何使用`detect`实现`is_assignable`：

```C++
template<typename T>
using assign_op_t = decltype( std::declval<T&>() = std::declval<T const&>());

template<typename T>
using is_assignable = detect<T,assign_op_t>;
```

之前的检测成员变量`v`示例可以改写为:

```C++
template<typename T>
using has_v_op_t = decltype( std::declval<T>().v);

template<typename T>
using has_v = detect<T,has_v_op_t>;
```

## 如何实现检测特定函数签名

函数签名需要参数列表,那么就会需要将原先的`detect`进行调整:

```C++
namespace detail
{
    template<typename E,template<typename...> typename Op,typename... Args>
    struct detector
    {
        using value_t = std::false_type;
    };

    template<template<typename...> typename Op, typename... Args>
    struct detector<std::void_t<Op<Args...>>, Op, Args...>
    {
        using value_t = std::true_type;
    };
}

template<template<typename...> typename Op, typename... Args>
using is_detected = typename detail::detector<std::void_t<>,Op, Args...>::value_t;
```

假设我们的函数簇为`filter`,参数不定,则判断是否有函数`filter`的实现为:

```C++
template<typename T,typename... Args>
using has_method_filter_t = typename std::integral_constant<
    decltype(std::declval<T>().filter(std::declval<Args>()...))(T::*)(Args...),
    &T::filter>::value_type;

template<typename T, typename... Args>
using has_method_filter = is_detected<has_method_filter_t, T,Args...>;
```

使用方式如下:

```C++
static_assert(has_method_filter<request_with_filter>::value, "");
static_assert(has_method_filter<request_with_filter,int>::value, "");
static_assert(!has_method_filter<request_without_filter>::value, "");
static_assert(!has_method_filter<request_without_filter,int>::value, "");
```

## 参考

- [Detection Idiom - A Stopgap for Concepts](https://blog.tartanllama.xyz/detection-idiom/)
- [Quick Q: How to require an exact function signature in the detection idiom?](https://isocpp.org/blog/2017/07/quick-q-how-to-require-an-exact-function-signature-in-the-detection-idiom)
- [Can we use the detection idiom to check if a class has a member function with a specific signature?](https://stackoverflow.com/questions/35843485/can-we-use-the-detection-idiom-to-check-if-a-class-has-a-member-function-with-a)
- [std::experimental::is_detected, std::experimental::detected_t, std::experimental::detected_or](https://en.cppreference.com/w/cpp/experimental/is_detected)
- [Notes on C++ SFINAE](https://www.bfilipek.com/2016/02/notes-on-c-sfinae.html)
- [SFINAE Followup](https://www.bfilipek.com/2016/02/sfinae-followup.html)
- [在C++中优雅地检测类型/表达式有效性： void_t & is_detected](https://zhuanlan.zhihu.com/p/26155469)
