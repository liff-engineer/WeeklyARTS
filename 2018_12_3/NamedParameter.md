# [一种命名参数的写法](https://gcc.godbolt.org/z/PytaXZ)

刷Twitter看到一种很有意思的命名参数写法,在Python中传参数可以直接`参数名=参数值`,但是C++中不行,有一些追求可读性、可维护性等等的开发者就在折腾怎么在模仿一些Python特性.然后就有人秀肌肉了......

## 需求场景

假设有个`greet`函数,接受姓和名两个参数:

```C++
void greet(std::string first_name,std::string last_name);
```

希望能够跟`Python`一样使用如下方式:

```Python
greet(first_name='Bond',last_name='James')
```

## 参数的实现和区分

```C++
template <typename T, typename tag>
struct type
{
    type(T t) : value(t) {}
    T value;
};
```

通过`T`来指定参数类型,通过`Tag`来区分类型一致的不同参数.

然后针对`greet`的两个参数定义:

```C++
using first_name = type<std::string, struct first_name_tag>;
using last_name = type<std::string, struct last_name_tag>;
```

这样`first_name`和`last_name`就表示了两个内容类型为字符串的不同类型,可以安全地使用.

## 参数的存储

需要为参数构造和访问提供统一API,这里实现`named_parameter`结合之前的参数类型来存储:

```C++
template <typename T>
struct named_parameter
{
    constexpr named_parameter() = default;
    named_parameter(const named_parameter&) = delete;
    named_parameter& operator=(const named_parameter&) = delete;
    template <typename V>
    constexpr T operator=(V v) const { return T(v);}
};

template <typename T>
constexpr named_parameter<T> parameter;
```

这时如果将`greet`接口定义修改成:

```C++
void greet(parameter<first_name> fn,parameter<last_name> ln);
```

就可以采用如下操作:

```C++
greet(parameter<first_name>="Bond",parameter<last_name>="James");
```

## 支持打乱参数顺序

将参数使用`tuple`来存储:

```C++
template <typename ...T>
struct to_tuple : std::tuple<T...>
{
    using std::tuple<T...>::tuple;
    template <typename ... Ts>
    operator std::tuple<Ts...> () { return { std::get<Ts>(*this)...};}
};

template <typename ... T>
to_tuple(T...) -> to_tuple<T...>;


template <typename ... T>
struct needs
{
    template <typename ... U>
    needs(U&& ... u) : values(to_tuple(std::forward<U>(u)...)) {}
    std::tuple<T...> values;
};
```

其中`to_tuple`是用来进行构造的辅助类,`needs`用来存储参数.

这时就可以通过如下操作构造参数包了:

```C++
auto parameters = needs{parameter<last_name> = "Bond", parameter<first_name> = "James"};
```

然后调整`greet`实现为:

```C++
void greet(N::needs<first_name, last_name> v)
{
    std::get<first_name>(v.values).value;//参数first_name
    std::get<last_name>(v.values).value;//参数last_name
}
```

## 总结

确实很有意思,通过这些方式可以实现类似Python语言特性,不过个人感觉目前没有必要,只是增加了复杂度.不过其中使用的模板技术还是值得学习的.