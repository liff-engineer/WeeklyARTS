# [试图理解`算法=逻辑+控制`](https://time.geekbang.org/column/article/2751)

在《编程范式游记》第9篇《编程的本质》中,讲到了两个公式:

1. Programs = Algorithms + Data Structures
2. Algorithm = Logic + Control

前一个比较熟悉,`程序=算法+数据结构`,但是`算法=逻辑+控制`到底该如何理解呢?

文章中进行了讲解,对于具体含义和区分不再赘述,这里我拿两个例子来去分析和理解这个`算法=逻辑+控制`.

## [C++中事件分发模板实现](https://github.com/liff-engineer/WeeklyARTS/blob/6133e938ab64075f1321c00ef722c7b550174eae/2018_11_2/EventDispatch.md)

在之前做ARTS时看到了一个C++中事件分发模板实现的样例.里面实现了这样一个接口：

```C++
dispatch<event1,event2,event3>(event_id,event_handler,event_data);
```

那么业务需求是什么呢? 要根据不同的事件调用不同的处理函数,而我们使用了`dispatch`这个接口来实现业务需求,针对不同的`event`和`event_handler`,均可以采用一个`dispatch`分发.

在这里,算法中的`逻辑`就是我们的业务需求,根据不同的`event`分发给对应的`event_handler`,无论`dispatch`是如何实现的,它必须满足这个需求,也就是其逻辑.

而如何使用逻辑,这里表现为`dispatch`方法,当然也可以使用别的方式来实现,也就是说,针对上述逻辑,控制的方式可以有很多种,如果在编译期无法确定,那么示例中模板的方式就不可用,只能采用别的方式实现;而且在示例中演示了四种方式来实现`dispatch`.

再总结一下,针对这个问题,逻辑抽象就是`event`以及`event_handler`,控制抽象就是`dispatch`,一部分是逻辑的表征,另一部分是控制的实现,两者组成了算法;如果逻辑抽象`event`及`event_handler`能满足业务需求,那么控制就无需更改,即可适应不同的逻辑.

## [状态机实现对比](http://boost-experimental.github.io/sml/cppcon-2018/#/)

在CppCon2018上,`STATE MACHINES BATTLEFIELD`吸引了我的注意力.里面展示了各种各样的状态机实现方式.譬如如下状态转换图:

![状态机](http://boost-experimental.github.io/sml/cppcon-2018/images/connection.png)

这个能够清晰地看出来算法中逻辑和控制的分离.状态机本身就是需求的抽象,我们的业务需求可以描述成状态机,然后状态机运转起来完成需求.

逻辑部分就是状态机,而控制部分则描述了如何表示、使用状态机.那么什么是更好的实现方式? 要看哪种实现能够把逻辑和控制分离.

> 有效地分离Logic、Control和Data是写出好程序的关键所在

```C++
sml::sm connection = []{
  using namespace sml;
  return transition_table{
    * "Disconnected"_s + event<connect> / establish   = "Connecting"_s,
      "Connecting"_s   + event<established>           = "Connected"_s,
      "Connected"_s    + event<ping> [ is_valid ] / reset_timeout,
      "Connected"_s    + event<timeout> / establish   = "Connecting"_s,
      "Connected"_s    + event<disconnect> / close    = "Disconnected"_s
  };
};
```

以上是`[Boost].SML`表述状态机的方式,可以看到,直接书写状态转换表,来表示状态机.之后的实现方式可以采用4种实现策略：

- Jump Table
- Nested Switch
- If/Else
- Fold expressions

## 总结

以上两个示例能够清晰地看出来需求和实现之间的关系,确实是逻辑和控制的分离,不同的事件、不同的状态转换表,控制部分都能够处理.