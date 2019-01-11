# [使用基类的构造函数](https://www.andreasfertig.blog/2019/01/using-base-class-constructor.html)

在[Reddit-Using base class constructor](https://www.reddit.com/r/cpp/comments/aec09o/using_base_class_constructor/)上展示了一种派生类使用基类构造函数的写法,很有意思:

```C++
class Foo
{
public:
    Foo(double amount) {}
    Foo(int x, int y = 2) {}
};

class Bar : public Foo
{
public:
    using Foo::Foo;

    int mX;
};

int main()
{
    Bar bar0{100.0};
    Bar bar1(100.0);

    Bar bar2(1);
}
```

如果基类有多种构造函数,如果常规方式,很可能要把基本的构造方法重新实现一遍,采用这种方式就可以避免大量代码的书写.但是这种方式有些问题,因为直接使用了基类的构造函数,派生类的成员变量是没有通过构造函数初始化的.

而如果你使用了[NSDMI:Non-static data member initializers](http://www.open-std.org/jtc1/sc22/wg21/docs/papers/2008/n2756.htm),即可解决这个问题.

```C++
class Foo
{
public:
    Foo(double amount) {}
    Foo(int x, int y = 2) {}
};

class Bar : public Foo
{
public:
    using Foo::Foo;
    int mX{1};
};

int main()
{
    Bar bar0{100.0};
    Bar bar1(100.0);

    Bar bar2(1);
}
```

可以通过[C++ Insights](https://cppinsights.io/)来审视某段代码最终在编译过程中是如何展开的,譬如`lambda`、`range-for`、编译器默认实现的一些函数等等.

这种特性在使用`Mixin`时特别有用:

```C++
#include <string>

struct edo
{
    int id{1024};
    std::string name{"edo"};
};

struct ent
{
    ent(int id,std::string name)
    :id{id},name{name}{};

    int id{1023};
    std::string name{"ent"};
};

template<typename T>
struct Mixin:public T
{
    using T::T;
    double weight{3.1415926};
};

int main(){
    Mixin<edo>  r{};

    Mixin<ent> r1{1000,"abc"};

    return 0;
}
```

如果没有`using T::T`这种写法,那么就需要这么写来支持原有的构造函数:

```C++
template<typename T>
struct Mixin:public T
{
    template<typename... Args>
    Mixin(Args&&... args):T{std::forward<Args>(args)...}{};
};
```

这种特性被称为[Inheriting constructors](https://en.cppreference.com/w/cpp/language/using_declaration).
