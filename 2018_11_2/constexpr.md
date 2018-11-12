# [解密`constexpr`](https://blog.quasardb.net/demystifying-constexpr/)

C++11和C++14带来了大量新特性,其中`auto`、`lamda`及右值引用等是大家比较关注和经常使用的,而对于模板相关新特性则应用较少,这里对`constexpr`进行了讲解.

## 从编译期值说起

在编码过程中有一些值属于常量,在编译期就能够明确知道其值,譬如:

```C++
int val = 3；
```

如果确定要其在编译期保持不变,在C++03中通常是如下形式:

```C++
static const int val = 3;
```

针对编译期值也可以做一些基本的算术操作:

```C++
static const int a = 1;
static const int b = 2;
static const int a_plus_b = a+b;
```

这样编译器可以在编译时进行运算来优化,即使没有`static`、`const`等这些关键字,编译器也能够猜出哪些是编译期确定的值,不过最好你能够提供足够的信息来帮助编译器决定。

在C++14中引入了新的关键字`constexpr`,如果你想要表达编译期值,可以使用如下写法:

```C++
static constexpr int a = 2;
```

注意不带`static`关键字的也有效,但是并不是相同的意思,`static`表示变量的生命周期,一个`static constexpr`变量必须在编译期设置,因为其生命周期是整个程序,如果不带`static`则编译器可以在之后决定其值,而不限制在编译期.

## `constexpr`：如果可以,在编译期完成

常量表达式并不意味着`编译期表达式`、`常量`或者`常量函数`,可以简单将常量表达式理解为:

> 给定编译期输入,常量表达式可以计算出结果.

对于变量来讲,其含义直截了当.如果你在编译期设置值,则你在编译期能够拿到结果.

在C++14中,`constexpr`不仅可以应用到变量上,也可以应用到函数或者方法上,这意味着什么?

`constexpr`函数如果其输入编译期可知,则能够在编译期计算出结果.

## `constexpr`函数示例

```C++
int add(int a,int b){
    return a+b;
}
```

如果`a`和`b`在编译期可知,那么`add`就能够在编译期计算出结果,因而`add`是能够作为`constexpr`函数的:

```C++
constexpr int add(int a,int b){
    return a+b;
}

static constexpr int val = add(3,4);
```

虽然`add`被`constexpr`修饰,依然可以作为普通函数在运行时使用.

应用同样的规则,那么以下函数能否声明为`constexpr`?

```C++
int add_vectors_size(std::vector<int> const& a,std::vector<int> const& b){
    return a.size() + b.size();
}
```

`std::vector`的大小只有在运行期才能够拿到,因而不能为`constant expression`.

而如果使用`std::array`则不一样了,因为`std::array`的大小在编译期即可决定:

```C++
template <std::size_t N1, std::size_t N2>  
int add_arrays_size(const std::array<int, N1> & a,  
                    const std::array<int, N2> & b)
{
   return a.size() + b.size();
}
``

## `constexpr`的限制

虽然在C++14中规则有所放松,但是限制还是比"编译期输入产生编译期输出"要严格,具体可以查看[C++ reference](https://en.cppreference.com/w/cpp/language/constexpr).

## 多用`constexpr`少用模板

之前C++里元编程都特制模板元编程,而模板元编程相对来讲比较难以理解和书写,有了`constexpr`之后完全可以用普通的函数/变量书写方式来完成编译期动作,譬如计算`factorial`：

```C++

constexpr unsigned int factorial(unsigned int n)  
{
    return (n <= 1) ? 1 : (n * factorial(n - 1));
}

static constexpr auto magic_value = factorial(5);  

```

## 尽可能使用`constexpr`

什么时候应该使用`constexpr`? 和`const`一样,如果能,就尽可能使用。


## 总结

`constexpr`在最新的`C++17`以及`C++20`中都在不断增强,在元编程方面的应用值得去关注,后续元编程的方式会越来越多,就如[hana](https://www.boost.org/doc/libs/1_61_0/libs/hana/doc/html/index.html)中针对C++计算四象限的区分,`constexpr`是其中强有力的手段.