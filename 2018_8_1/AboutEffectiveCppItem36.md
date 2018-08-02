# "尽信书不如无书"

## 缘起

最近在采用模板技术做一些模块上的可扩展设计,示例如下：

```C++
struct empty_result_t {};

template<typename T=empty_result_t>
struct result_t:public T
{
    template<typename... Args>
    void apply(Args&&... args);
    void confirm();
};

template<typename T=result_t<>>
struct user_result_t:public T
{
    using T::apply;
    template<typename... Args>
    void apply(Args&&... args){
        //基于T扩展或者重写
        T::apply(std::forward<Args>(args)...);
    }
    void confirm(){
        //基于T扩展或者重写
        T::confirm();
    }
};
```

跟别人沟通后,得到的反馈是他们觉得模板比较“难懂”,调试比较困难,而且面向对象的方式也可以达到这种效果,于是我基于此实现了面向对象版本的示例:

```C++
struct result_t
{
    void apply(arg1_t arg1);
    void apply(arg2_t arg2);
    void confirm();
};

struct user_result_t:public result_t
{
    using result_t::apply;
    void apply(arg1_t arg1){
        result_t::apply(arg1);
    }
    void confirm(){
        result_t::confirm();
    }
};
```

**so far so good**!

## 问题来了

但是熟读《Effect C++》的朋友可能看出了问题,在书中条目36:

>Item 36: Never redefine an inherited non-virtual function.

为什么有这个条目呢?我们看一下上述样例的一种用法：

```C++
void example(){
    user_result_t user_result;
    result_t* result = &user_result;
    result->apply(arg1);
    result->confirm();
}
```

这段代码会产生什么样的效果?`result`调用的所有方法都是`result_t`的,而不是我们要求的`user_result_t`的。

为什么存在这样的问题：与虚函数不同,普通的函数调用是编译期决定的,如果指针类型是`result_t`那么,非虚函数调用就是调用的`result_t`的方法!

之所以有这个条目36,还有一个问题就是继承表达的是一种`is-a`关系,而且面向对象设计原则中有一种叫做里氏替换原则,这种场景下使用继承是有问题的。

## 怎么解决

《Effect C++》中条目36中说得很明白：**Never redefine**;而原始设计就是想要提供这样的重用和扩展,是设计出了问题?

### 解决方法:用多态

解决问题从问题源头出发,既然是因为非虚函数编译期确定,那么把方法改成虚方法总可以了吧:

```C++
struct result_t
{
    virtual void apply(arg1_t arg1);
    virtual void apply(arg2_t arg2);
    virtual void confirm();
};

struct user_result_t:public result_t
{
    using result_t::apply;
    void apply(arg1_t arg1) override{
        result_t::apply(arg1);
    }
    void confirm() override{
        result_t::confirm();
    }
};
```

这种方法有一个比较明显的问题,如果不用`override`,很容易因为函数名等出错而没办法发现,而且需要把`result_t`中所有可能被重新实现的方法声明为`virtual`。

还有一个有些严重的问题：在性能关键的位置虚方法会有性能损耗,而这个场景下损耗是不必须的！

### 解决方法：用模板

最初设计的写法使用了C++的`Mixin`模式,这点和条目36是否有冲突?我纠结了很久,毕竟是经典书籍,就因为这么一条,`Mixin`模式就限定了不能应用于`redefine`的场景?

事实上,条目36没有问题,而采用模板的实现方式也没有问题,通过深入了解就会发现,使用`Mixin`的`redefine`和条目36描述的场景是不一样的,虽然"非常容易"混淆:

- 条目36只是描述了面向对象的场景
- `Mixin`模式只是形似面向对象

`Mixin`的类型之间没有继承关系:

```C++
result_t<> result;
user_result_t<> user_result = result;//编译失败！

result_t<>* result_p = &user_result;//编译失败
```

即使可以定义`user_result_t`的构造函数来接受`result_t`类型,但是,只是能够用来进行构造动作,编译完之后,这就是两种完全没有关系的类型。

## 思考

C++中由于有模板这种技术存在,在看到一些经典书籍的时候也需要多多思考,不能没有摸透就贸然在所用场景下应用那些书中的知识,知其然知其所以然。
