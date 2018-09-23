# 使用模板实现事件/消息处理的一种方法

在[Dr. Strangetemplate](https://github.com/MCGallaspy/dr_strangetemplate)中演示了模板在事件/消息处理中的一种用法,让我们来学习一下。

## 面临的问题

假设有一些不同的消息,也有一些不同的消息处理对象,示例如下：

```C++
struct msg_create_t {};
struct msg_delete_t {};
struct msg_update_t {};

struct msg_create_handler {
    void handle(msg_create_t const& msg);
};

struct msg_create_delete_handler {
    void handle(msg_create_t const& msg);
    void handle(msg_delete_t const& msg);
};

struct msg_handler {
    void handle(msg_create_t const& msg);
    void handle(msg_delete_t const& msg);
    void handle(msg_update_t const& msg);
};
```

按照面向对象的方式写,基本上会将`msg`抽象为基类,`msg_handler`也抽象为基类,从而实现为如下方式:

```C++
class msg {
public:
    virtual ~msg() = default;
};

class msg_handler {
public:
    virtual ~msg_handler() = default;
    virtual void handle(msg* v) = 0;
};
```

至少在Qt的事件机制中就是采用这种方式,但是实际上如果这些`msg`是功能、含义、类型完全不一样的,按照面向对象的写法又会将其拆分成不同的基类,把`msg_handler`也进行拆分,从而导致大量样板代码的出现,以及复杂的类继承关系,那么如果采用模板能够达成什么效果呢?

## 模板要达成的目标

保持原始的设计不变,可以使用模板达成如下效果:

```C++
template<typename T>
class dispatcher {
public:
    template<typename U>
    static void post(U const&);
};

template<typename... Args>
class type_list {};

using msg_handlers = type_list<msg_create_handler, msg_create_delete_handler, msg_handler>;
using msg_dispatcher = dispatcher<msg_handlers>;

void example() {
    msg_dispatcher::post(msg_create_t{});
    msg_dispatcher::post(msg_delete_t{});
    msg_dispatcher::post(msg_update_t{});
}
```

在编译期指定可能的`msg_handler`,向`msg_handler`投递任意的事件类型,无需基类`msg`和`msg_handler`。

那么该如何实现?

## 如何实现

- 实现`type_list`来存储`msg_handler`类型列表,并可以对其进行编译期遍历
- 实现`msg_handler`的成员检查,判断是否能够处理对应的`msg`
- 实现`dispatcher`来正确投递`msg`给对应的`msg_handler`

### `type_list`

先来看看如何实现`type_list`:

```C++
template<typename... Args>
struct type_list;

template<typename T>
struct type_list<T> {
    using head = T;
};

template<typename Head,typename... Tail>
struct type_list<Head, Tail...> :type_list<Head>
{
    using tail = type_list<Tail...>;
};
```

使用可变参数模板等特性即可实现一个类型列表,然后编译期遍历操作:不断将类型头部移除,直到为空,则停止遍历：

```C++
template<typename T,typename = void>
struct count:std::integral_constant<int,1>{};

template<typename T>
struct count<T,std::void_t<typename T::tail>>:
    std::integral_constant<int,1+count<typename T::tail>()>{};

template<typename T>
struct has_tail:std::conditional_t<(count<T>::value == 1),std::false_type,std::true_type>{};
```

实现`count`来判断`type_list`类型个数,然后当个数为1时`has_tail`就为`false_type`,否则为`true_type`.

### 针对`msg_handler`的成员函数检查

简单起见,这里假设成员函数为静态成员函数:

```C++
template<typename Handler,typename M,typename = void>
struct has_handler :std::false_type {};

template<typename Handler, typename M>
struct has_handler<Handler, M, decltype(Handler::handle(std::declval<const M&>()))> :std::true_type {};
```

`has_handler`默认为`false_type`,然后使用SFINAE和`decltype`将包含特定参数类型的`handle`方法判断出来,如果有则为`true_type`.

### `dispatcher`及展开动作

现在就要处理对应的`handler`集合及其展开了,首先假设`post_impl`:

```C++
template<typename M,typename List,bool HasTail,bool HasHandler>
struct post_impl;
```

然后根据是否有`tail`和`handle`来进行操作,譬如如果有`tail`就需要继续展开,如果有`handler`就需要调用:

```C++
template<typename M,typename List >
struct post_impl<M, List, true, true>
{
    static void call(M const& m) {
        List::head::handle(m);

        using Tail = typename List::tail;

        constexpr bool has_tail_v = has_tail<Tail>::value;
        constexpr bool has_handler_v = has_handler<typename Tail::head, M>::value;
        post_impl<M, Tail, has_tail_v, has_handler_v>::call(m);
    }
};
```

分别根据`HasTail`和`HasHandler`来提供不同的偏特化,使得能够按照预期展开类型列表并调用处理函数。

### 实现`dispatcher`

到这一步实现就比较简单了:

```C++
template<typename... Handlers>
struct dispatcher
{
    template<typename M>
    static void post(M const& v) {
        constexpr bool has_tail_v = has_tail<Handlers>::value;
        constexpr bool has_handler_v = has_handler<typename Handlers::head, M>::value;

        post_impl<M, Handlers, has_tail_v, has_handler_v>::call(v);
    }
};
```

## 总结

模板处理这类问题的思路可以理解为`Duck Type`,看起来像鸭子,走起路来像鸭子,就认为其为鸭子,在这种应用场景下,只关注其自身有的接口(能力),而不是类型.

但是也存在问题,这些信息需要编译期确定好,没有面向对象的实现方法那种全动态的灵活,这可能是导致其没有广泛应用的原因。