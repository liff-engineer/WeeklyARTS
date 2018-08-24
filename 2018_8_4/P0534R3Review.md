# [call/cc (call-with-current-continuation): A low-level API for stackful context switching](http://www.open-std.org/jtc1/sc22/wg21/docs/papers/2017/p0534r3.pdf)

什么是`call/cc`,让我们先从定时器聊起。

## 关于定时器的实现

大家都用过闹钟,设定好时间,然后你可以去忙别的,当时间到了,闹钟响起,你就可以去处理特定时间要去完成的事情.然而这么个简单的需求-定时器,在之前的C++标准库中却不存在,为什么?

C++中之前的编程模型是单线程顺序执行,程序正在全心全意地做事情,定时器怎么运行?在嵌入式领域,定时器这种是通过中断来实现的,芯片上有专门的定时器芯片独立运行,当设定的时间到了,就会触发中断,在芯片上写程序需要响应中断,就要写中断例程,触发中断进入中断例程,执行完毕后回到程序主流程上。

在工作中,通常都会碰到这样的场景,你需要设置定时器,等到定时器定时完成,才继续往下执行;而你有不能干等着什么事情都不做,所以在不是等待定时器,而是先去做别的事情,等定时器通知完成,再往下执行,而这个,就是`call/cc`要解决的场景。

## “分时复用”

分时复用,就是再每个任务执行需要一段时间,那就分时间段,这个时间段执行a任务,下个时间段执行b任务,然后再下个时间段... 用同一台机器完成多个任务。

`call/cc`提供了这样一种能力,当前任务执行需要等等,那就保存起当前任务,切换到另一个任务,执行完成后再切换回来;这些任务在同一个机器/线程上执行.,只不过当前任务执行到一个阶段,需要等待某些内容就绪,那就先把机器释放出来,可以有别的任务继续执行,在别的任务执行完成或者需要等待时再切换回来.这样就能充分利用,避免等待。

## `call/cc`带来的好处

可以看到,使用这种方式,能够将异步的代码以同步的方式书写,譬如事件处理：

```C++
void loop(){
    while(true){
        auto event = wait incomeing_event();
        wait process_event(event);
    }
}
```

这个就是协程实现所要达成的效果.

## 示例

可以看看以下示例:

```C++
continuation f1(continuation && c) {
    std::cout << "f1: entered first time" << std::endl;//2
    c = c.resume();
    std::cout << "f1: entered second time" << std::endl;//4
    return std::move( c);
}

void run(){
    continuation c = callcc( f1);//1
    std::cout << "f1: returned first time" << std::endl;//3
    c = c.resume();
    std::cout << "f1: returned second time" << std::endl;//5
    std::cout << "main: done" << std::endl;
}
```

先执行步骤1,进入到步骤2,当执行到`c.resume()`时又切换回步骤3,再一次执行`c.resume()`又返回并执行步骤4,之后f1执行完成,进入步骤5.

可以看到,通过`c.resume()`可以暂停当前流程,去执行其它流程,当其它流程执行完成或者暂停,就返回到现在流程继续执行,虽然是多任务的代码,却可以以正常的函数流程书写。

## 总结

`call/cc`直译就是带后续动作的上下文切换,可以释放当前的CPU供其它流程使用,然后还能够再返回回来;`call/cc`也是实现`fiber`以及`coroutine`所用到的底层原语,而该标准提案的作者就是`Boost.Context`、`Boost.Fibers`以及`Boost.Coroutine2`的作者;后续将会继续解读涉及这些库的标准提案,以及应用场景。

## 其它

Boost.Fiber实现用到了[Boost.Context](https://www.boost.org/doc/libs/1_68_0/libs/context/doc/html/index.html),在Boost.Context的文档[Context switching with call/cc](https://www.boost.org/doc/libs/1_68_0/libs/context/doc/html/context/cc.html)讲到`call/cc`是Boost.Context核心部分,并已经有相关标准提案P0534R3,而且Boost.Context中提到了关于fibers的标准提案[P0876R0 - fibers without scheduler](http://www.open-std.org/jtc1/sc22/wg21/docs/papers/2018/p0876r0.pdf).

在[Event-Driven Program](https://www.boost.org/doc/libs/1_68_0/libs/fiber/doc/html/fiber/integration/event_driven_program.html)中提到了fiber在事件驱动中的使用。

有一些关于fiber的参考资料：

- [纤程](https://blog.codingnow.com/2005/10/fiber.html)
- [Fiber (computer science)](https://en.wikipedia.org/wiki/Fiber_(computer_science))
- [《Windows via C/C++》学习笔记 —— 纤程（Fiber）](https://www.cnblogs.com/wz19860913/archive/2008/08/26/1276816.html)