# [C++中的初始化](https://www.youtube.com/watch?v=7DTlWPgX6zs)

C++11带来了`Uniform Initialization`,让我们来系统地了解一下C++中初始化的`前世今生`,以及其存在的问题。

C++98/C++03中的初始化操作非常混乱:

```C++
int i1;//未定义值
int i2 = 42.8;//使用42初始化
int vals[] = {1,2,3}; //聚合初始化

std::complex<double> c(4.0,3.0); //类初始化
int i3(42.9);   //使用42初始化
int i4 = int();  //使用0初始化

std::vector<std::string> cities;//容器没有初始化
cities.push_back("Berlin");
cities.push_back("Rome");
```

C++中初始化的术语:

- 直接初始化(Direct initialization)
  - 直接传递初始化值
- 复制初始化(Copy initialization)
  - 使用`=`初始化
  - 如果类构造函数以`explicit`修饰则不可以
- 默认初始化(Default initialization)
  - 只有相应的构造函数有定义才能初始化
- 零值初始化(Zero initialization)
  - 对象使用`0`初始化
  - 给全局/静态/线程局部对象使用
- 值初始化(Value initialization)
  - 对象总是能初始化为值(使用构造函数初始化或者零值初始化)
- 列表初始化(List initialization)
  - 对象使用`{}`初始化(直接列表初始化或者复制列表初始化)
  - 对象总是能初始化为值(使用构造函数初始化或者零值初始化)  
- 聚合初始化(Aggregate initialization)
  - 如果类型是聚合的,需要使用特定形式的列表初始化进行初始化

为了解决初始化操作这一团乱麻:不同的语法,不同的条款和规则,C++11将初始化操作进行了统一(同时保持向后兼容):使用`{...}`进行所有的初始化操作。

```C++
int i1;//未定义值
int i2 = 42.8;//使用42初始化
int i3(42.9);   //使用42初始化
int i4 = int();  //使用0初始化

int i5{42};
int i6 = {42};
int i7{};
int i8 = {};

int vals1[] = {1,2,3}; //聚合初始化
int vals2[] {1,2,3};

std::complex<double> c1(4.0,3.0); //类初始化
std::complex<double> c1{4.0,3.0};
std::complex<double> c1 = {4.0,3.0};

std::vector<std::string> cities{"Berlin","Rome"};
std::vector<int> vals2{0,8,15,i1+i2};
```

## AAA(Almost Always Auto)

由Herb Sutter于2013年提出,声明形式为:

```C++
auto x = ...;
using T = ...;
```

- 如果不在乎类型则可以考虑使用`auto`:`auto x = initializer;`
- 当你希望明确类型时,考虑以如下形式声明局部变量:`auto x= type{expr};`

那么如下代码:

```C++
int i = 42;
long v = 42;
Customer c{"Jim",77};
std::vector<int>::const_iterator p =v.begin();
```

应用`AAA`之后:

```C++
auto i = 42;
auto v = 42l;
auto c = Customer{"Jim",77};
auto p = v.cbegin();
```

优点:

- 不会忘记初始化

## C++17:Mandatory RVO and Copy Elision

从临时值(prvalues)进行复制初始化不再需要可调用的复制/移动构造函数.

譬如如下类:

```C++
class NoCopyAndMove{
public:
    NoCopyAndMove() = default;

    //禁止掉拷贝和移动构造函数
    NoCopyAndMove(NoCopyAndMove const&)=delete;
    NoCopyAndMove(NoCopyAndMove &&)=delete;
};
```

以下操作在C++17及之后有效:

```C++
void foo(NoCopyAndMove obj);

foo(NoCopyAndMove{});

NoCopyAndMove bar(){
    return NoCopyAndMove{};
}

NoCopyAndMove x = bar();

foo(bar());

const NoCopyAndMove& r {bar()};
```

## 解决`Most Vexing Parse`问题

## 统一初始化操作禁止隐式`Narrowing`

`{...}`用来将浮点数转换成整数

## Style Guide

- [Tip of the Week #88: Initialization: =, (), and {}](https://abseil.io/tips/88)
- CppCoreGuideline