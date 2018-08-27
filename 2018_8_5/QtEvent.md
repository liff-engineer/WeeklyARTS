# [Another Look at Events](https://doc.qt.io/archives/qq/qq11-events.html)

最近要做很多UI相关的工作,拾起了Qt,在阅读QGraphicsView相关源代码时,需要拦截一些鼠标事件,这时发现自己对Qt的Event System还不是很清楚,所以Review一下这篇文章感受一下。

## 概述

我对Qt的Event System理解是其可以看作消息总线,"生产者"将消息发送到消息总线上,从而提供给"消费者"处理,能够解除"生产者"和"消费者"的耦合关系,更容易扩展,而且有更多的玩法,譬如：

- 消息合并与压缩
- 拦截/监控某种类型的消息
- 拦截/监控发送给某个对象的消息
- 根据消息制造其它不同的消息发送给"消费者"

## Qt中事件的类型

Qt中有以下三种事件：

1. 自发事件:由窗体系统产生,会被放到系统队列通过事件循环一个个处理
2. 发布事件:由Qt或者应用程序产生,发送到Qt队列通过事件循环处理
3. 发送事件:由Qt或者应用程序产生,直接发送给目标对象

而这三种事件在Qt事件循环中的处理顺序是:发布事件、自发事件、发布事件(由自发事件产生的发布事件)。

## 对事件的操作

- 合成事件

可以构造出特定的事件通过`QApplication::postEvent()`或者`QApplication::sendEvent()`发送出去,需要注意的是使用`postEvent`时事件需要`new`,Qt在事件处理完成后自动删除掉;而使用`sendEvent`时必须要在栈上构造,来保证其正确析构。

- 自定义事件

通过指定`QCustomEvent`的类型或者继承自`QCustomEvent`即可自定义事件。

- 事件处理与过滤

Qt中事件可以在以下5个不同的层次来处理:

    - 重新实现特定的事件处理Handler,譬如paintEvent、closeEvent等
    - 重新实现`QObject::event`,在`QObject`以及`QWidget`中通常是将事件分发给具体的事件处理Handler
    - 在`QObject`上注册事件filter,可以在事件到达`QObject`前处理
    - 在`QApplication/qApp`上注册事件filter,可以监控`qApp`上所有发送到对象的事件
    - 重新实现`QApplicaion::notify`,Qt的事件循环和`sendEvent`都是调用`notify`来处理的,重新实现该函数可以最先处理所有事件。

需要注意的是,有些事件类型是可以传播的,如果当前目标没有处理这个事件,Qt会尝试查找新的处理者.

- 接受还是忽略

可以传播的事件有`accept`及`ignore`方法来控制是否接受或者忽视该事件,如果事件处理handler接受了该事件,则Qt会中止其传播。

## 总结

事件系统是一种非常好的设计,在QGraphicsView中就是通过事件系统与QGraphicsScene及其它对象进行沟通,可以在此基础上实现更多特定的需求,还是需要多多学习和领悟。