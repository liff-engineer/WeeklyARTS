# [Guaranteed Copy Elision Does Not Elide Copies](https://blog.tartanllama.xyz/guaranteed-copy-elision/)

C++17合并了一个提案[Guaranteed copy elision through simplified value categories](http://www.open-std.org/jtc1/sc22/wg21/docs/papers/2015/p0135r0.html).简单直译为:通过简化值策略来保证副本消除.主要是用来解决以下问题:

```C++
struct non_moveable {
    non_moveable() = default;
    non_moveable(non_moveable&&) = delete;
};
non_moveable make() { return {}; }
non_moveable x = make(); //compiles in C++17, error in C++11/14
```

之前`non_moveable x = make()`是通过移动复制动作来实现,就会导致没有移动复制操作的类编译失败.

虽然提案名称上有"保证副本消除",但是新的规则并不是保证副本消除.实际上是通过新的值策略规则使得副本从一开始都不存在.理解这个差别需要深入理解目前的C++对象模型.

## 值策略

为了理解这之前和之后的差别,首先需要了解什么是值策略.这里的值策略并不是指值的策略,而是用来描述表达式的特性.C++中的表达式有以下三者之一的值策略:`lvalue`,`prvalue`(纯右值),或者`xvalue`,这里又有两种父策略：所有的`lvalues`和`xvalues`都是`glvalues`,所有的`prvalues`和`xvalues`都是`rvalues`.

![值策略](https://blog.tartanllama.xyz/assets/valcat.png)

在C++标准里是这样解释的:

- `glvalue`([一般性左值])是决定对象、位域或者函数的`identify`的表达式
- `prvalue`是根据其所处的上下文,来初始化对象、位域或者计算操作符运算值的表达式
- `xvalue`是一个`glvalue`,来表示对象或者位域的资源可以被复用(通常是因为其生命周期要终结了)
- `lvalue`是一个不是`xvalue`的`glvalue`
- `rvalue`是一个`prvalue`或者`xvalue`

以下是一些示例:

```C++
std::string s;
s //lvalue: identity of an object
s + " cake" //prvalue: could perform initialization/compute a value

std::string f();
std::string& g();
std::string&& h();

f() //prvalue: could perform initialization/compute a value
g() //lvalue: identity of an object
h() //xvalue: denotes an object whose resources can be reused

struct foo {
    std::string s;
};

foo{}.s //xvalue: denotes an object whose resources can be reused
```

## C++11

那么表达式`std::string{"a pony"}`的属性是什么?

这是一个`prvalue`,类型是`std::string`,值是`a pony`,它命名了个临时值.

最后一点是重点,这个是C++11和C++17中真正有区别的地方.在C++11中,`std::string{"a pony"}`确实命名了一个临时值.

> Temporaries of class type are created in various contexts: binding a reference to a prvalue, returning a prvalue, a conversion that creates a prvalue, throwing an exception, entering a handler, and in some initializations.

让我们看一下以下代码是如何交互的:

```C++
struct copyable {
    copyable() = default;
    copyable(copyable const&) { /*...*/ }
};
copyable make() { return {}; }
copyable x = make();
```

`make()`返回了一个临时值,这个临时值会被移动到`x`中,由于`copyable`没有移动构造,这个操作会调用复制构造.然而,这份副本是没有任何必要的,因为对象在`make()`的过程中构造,副本永远不会被别的使用.标准允许这份副本被消除,不是在`make`的时候,而是在构造时(The standard allows this copy to be elided by constructing the return value at the call-site rather than in make).这个被称为副本消除.

不幸的是,即使副本被消除了,构造函数还是必须存在. 这就导致了以下代码会出现编译错误:

```C++
struct non_moveable {
    non_moveable() = default;
    non_moveable(non_moveable&&) = delete;
};
non_moveable make() { return {}; }
auto x = make();
```

这也导致了其它问题:

- 在使用`Almost Always Auto`风格时:`auto x = non_moveable{}; //compiler error`
- 语言不保证构造函数不被调用
- 为了支持某些场景,必须为其实现复制/移动构造,但是这个并没有任何意义
- 无法给函数使用值传递`non-moveable`类型

那么解决方案是什么呢?

## C++17

C++17采用了不同的方法.与其保证这些场景下副本会被消除,不如直接改变规则,让这些副本从一开始就不存在.要达成这个需要重定义合适临时值会被创建.

之前的值策略里提到,`prvalue`的存在就是为了初始化.C++11创建临时值较早,使用其完成初始化之和再清理副本.在C++17中临时值的实体化要一直到实现初始化时.

这个特性有一个更好的名字.不是保证副本消除.而是延迟临时值实体化.

临时值初始化从`prvalue`中创建临时对象,然后变成一个`xvalue`.当绑定引用或者在`prvalue`上实现成员访问时最常见.

```C++
struct foo {
    int i;
};

foo make();
auto& a = make();  //temporary materialized and lifetime-extended
auto&& b = make(); //ditto

foo{}.i //temporary materialized

auto c = make(); //no temporary materialized
```

## 总结

之前曾经在使用`Almost Always Auto`风格时看到介绍说有一些例外的场景,当时不太明白到底时什么,为什么C++17之和就可以了.读完这篇文章算是差不多清楚了.要理解C++标准还是很考验人的.