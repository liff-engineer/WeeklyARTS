# 提纲
- 大概聊一下CRTP
- 基于 [Jonathan Boccara's blog - Fluent {C++}](https://www.fluentcpp.com/)上关于`Variadic CRTP`的三篇文章
    - [Variadic CRTP: An Opt-in for Class Features, at Compile Time](https://www.fluentcpp.com/2018/06/22/variadic-crtp-opt-in-for-class-features-at-compile-time/)
    - [Variadic CRTP Packs: From Opt-in Skills to Opt-in Skillsets](https://www.fluentcpp.com/2018/06/26/variadic-crtp-packs-from-opt-in-skills-to-opt-in-skillsets/)
    - [How to Reduce the Code Bloat of a Variadic CRTP](https://www.fluentcpp.com/2018/07/03/how-to-reduce-the-code-bloat-of-a-variadic-crtp/)

## 从`std::enable_shared_from_this`谈起
什么是CRTP?最典型的例子就是标准库中的[std::enable_shared_from_this](https://en.cppreference.com/w/cpp/memory/enable_shared_from_this):
```C++
struct object_t:std::enable_shared_from_this<object_t>
{
    void apply(){
        auto self = shared_from_this();//获取指向自身的智能指针
    }
};
```
在`Boost.ASIO`的[聊天室示例](https://www.boost.org/doc/libs/1_67_0/doc/html/boost_asio/examples/cpp11_examples.html)中chat_server.cpp可以看到其“神奇”的应用:
```C++
class chat_session
  : public chat_participant,
    public std::enable_shared_from_this<chat_session>
{
    void start()
    {
        room_.join(shared_from_this());
        do_read_header();
    }

    void do_read_header()
    {
        auto self(shared_from_this());
        boost::asio::async_read(socket_,
            boost::asio::buffer(read_msg_.data(), chat_message::header_length),
            [this, self](boost::system::error_code ec, std::size_t /*length*/)
            {
                if (!ec && read_msg_.decode_header())
                {
                do_read_body();
                }
                else
                {
                room_.leave(shared_from_this());
                }
            });
    }
}
```
## CRTP
CRTP的写法如下：
```C++
template<typename Dervied>
class Skill
{
public:
    void ability(){
        auto dervied = static_cast<Dervied&>(*this);
        dervied.skillImpl();
        dervied.skillImpl();
        //...
    }
};

class Human:public Skill<Human>
{
public:
    void skillImpl(){};
}
```

可以看到`Human`通过继承自模板`Skill`,即可得到接口`ability`,其行为是调用`Human`自身的方法,是不是类似于虚函数?

在基类里声明虚函数并使用,子类实现虚函数,基类调用的函数实际上执行的是子类里的实现,这就是动态多态的基本方式;而使用CRTP可以有一样的行为,而且是编译期确定的,无需查询虚函数表等等操作,这种技术被称为静态多态。

当然CRTP还能给有别的用途,可以基于提供了相同接口的`Apply`实现通用的操作。

## Variadic CRTP
之前的`Human`只继承自一种`Skill`,如果继承自多种`Skill`,从而拥有不同的能力,该如何实现?
```C++
template<typename Dervied>
class Skill1
{
public:
    void ability1(){
        auto dervied = static_cast<Dervied&>(*this);
        //...
    }
};

template<typename Dervied>
class Skill2
{
public:
    void ability2(){
        auto dervied = static_cast<Dervied&>(*this);
        //...
    }
};

class Human:public Skill1<Human>,Skill2<Human>
{};
```

这样我们的`Human`就有了两种`Skill`,C++11引入了可变参数模板,那么能否采用可变参数模板来使得`Human`作为模板类使用呢?我们尝试如下方法：
```C++
template<typename... Skills>
class Human:public Skills...
{};

using XHuman = Human<Skill1,Skill2>;

XHuman man;
man.ability2();
```

遗憾的是它无法通过编译,因为`Skill1`、`SKill2`是模板而不是类,需要写成如下形式:
```C++
template<template<typename> typename... Skills>
class Human:public Skills<Human<Skills...>>...
{};
```
这时就可以使用`Human<Skill1,Skill2>`了,而且`Human`的`Skill`可以随意组合使用,新增也非常容易。

## Variadic CRTP存在的问题
可以看到,这种方式非常之灵活,也会带来一些问题,我们知道C++的模板都会实例化出类来,包含了用到的所有方法及实现,如果有非常多的`Skill`存在,就可能实例化出非常多的类型来,从而引起代码大小快速增大,如何解决这个问题？

解决思路从原因开始找起,之所有实例化出来非常多的类型,是因为`Skill`有很多,排列组合出来更多,能不能减少`Skill`的数量而不减少功能?

## 从Skills到Skills集合
如果将各种`Skills`根据分类组合成不同的`Skills`集合,那么`Human`就会变成`Skills`集合的集合,`Skills`集合的数量会大大减少,从而减少了`Human`的类型数量:

```C++
template<typename Dervied>
struct SkillSet1:Skill1<Dervied>,Skill2<Dervied> {};

template<typename Dervied>
struct SkillSet2:Skill3<Dervied>,Skill4<Dervied> {};

using XHuman = Human<SkillSet1,SkillSet2>;
```
看起来比较像`composite`设计模式了,实际上在使用C++实现`composite`可以考虑用`CRTP`或者`Mixin`来实现。









