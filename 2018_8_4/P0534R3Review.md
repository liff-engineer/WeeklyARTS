# [call/cc (call-with-current-continuation): A low-level API for stackful context switching](http://www.open-std.org/jtc1/sc22/wg21/docs/papers/2017/p0534r3.pdf)

Boost.Fiber实现用到了[Boost.Context](https://www.boost.org/doc/libs/1_68_0/libs/context/doc/html/index.html),在Boost.Context的文档[Context switching with call/cc](https://www.boost.org/doc/libs/1_68_0/libs/context/doc/html/context/cc.html)讲到`call/cc`是Boost.Context核心部分,并已经有相关标准提案P0534R3,而且Boost.Context中提到了关于fibers的标准提案[P0876R0 - fibers without scheduler](http://www.open-std.org/jtc1/sc22/wg21/docs/papers/2018/p0876r0.pdf).

在[Event-Driven Program](https://www.boost.org/doc/libs/1_68_0/libs/fiber/doc/html/fiber/integration/event_driven_program.html)中提到了fiber在事件驱动中的使用。

有一些关于fiber的参考资料：

- [纤程](https://blog.codingnow.com/2005/10/fiber.html)
- [Fiber (computer science)](https://en.wikipedia.org/wiki/Fiber_(computer_science))
- [《Windows via C/C++》学习笔记 —— 纤程（Fiber）](https://www.cnblogs.com/wz19860913/archive/2008/08/26/1276816.html)