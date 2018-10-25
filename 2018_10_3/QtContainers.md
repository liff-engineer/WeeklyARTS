# [探索Qt容器](https://www.cleanqt.io/blog/exploring-qt-containers)

当项目中使用到Qt时,就会有个问题暴露出来:优先使用Qt容器还是STL容器?

在这篇文章中,作者对比了Qt提供的容器及其对应的STL容器,分析其API、性能及其实现细节,目标就是来确定更适合用哪个库。

## 第一个问题

为什么有STL容器,Qt还要提供自己的容器?

- 历史原因,Qt项目诞生于STL之前
- Qt支持的平台之上没有提供STL
- Qt不想从其ABI中暴露STL符号

毕竟Qt作为一个成熟的框架,是需要支持向后兼容的,确实有其考虑,不过自从Qt5开始,倾向于使用对应的STL版本,详见[Effective Qt (2017 edition)](https://www.youtube.com/watch?v=uZ68dX1-sVc).

## 容器类型

容器可以分为以下类型:序列容器、容器适配器、管理容器、容器行为类。

### 序列容器

| Qt | STL |
|--- | --- |
| - | std::array |
| QVector | std::vector |
| - | std::deque |
| QLinkedList | std::list |
| QList | - |
| - | std::forward_list |

算法复杂度

| 类型 | 随机访问 | 插入 | 前插 |追加 |
| --- | ---- | ---- | --- | --- |
| QLinkedList | O(n) | O(1) | O(1) | O(1) |
| QList | O(1) | Q(n) | Amortised O(1) | Amortised O(1)|
| QVector | O(1) |O(n) | O(n) |Amortised O(1)|

相应的STL容器具有一致的复杂度。

这个没啥说的,能用QVector就不要用QList,和STL中的指导一致:

> QVector should be your default first choice. QVector will usually give better performance than QList, because QVector always stores its items sequentially in memory, where QList will allocate its items on the heap...

### 容器适配器

| Qt | STL |
| -- |--|
| QStack | std::stack |
| QQueue | std::queue |
| - | std::priority_queue |

- QStack继承自QVector,而std::stack底层容器可以是任何满足需求的容器,默认情况下使用std::queue
- QQueue继承自QList,std::queue和std::priority_queue对于底层容器的要求和std::stack一致,只要满足其需求即可,默认情况下std::queue的底层容器是std::deque,std::priority_queue使用std::vector

### 关联容器

| Qt | STL |
| -- | -- |
| -  | std::set |
| QSet | std::unordered_set |
| -  | std::multiset |
| -  | std::unordered_multiset|
|QMap | std::map|
|QMultiMap | std::multimap |
|QHash | std::unordered_map |
|QMultiHash | std::unordered_multimap|

需要注意QSet对应的是STL里的std::unordered_set.

算法复杂度:

| 类型   |键访问平均| 键访问最坏情况|插入平均|插入最坏情况|
|-- |-- |-- |-- |--|
| QMap | O(log n)| O(log n) | O(log n) | O(log n)|
|QMutiMap|  O(log n)| O(log n) | O(log n) | O(log n)|
| QHash | Amortised O(1)|O(n)|Amortised O(1)|O(n)
| QSet| Amortised O(1)|O(n)|Amortised O(1)|O(n)

相应的STL容器具有一致的复杂度。

### 容器行为类

以下三个模板类提供了容器行为,但是没有使用隐式共享 

- QVarLengthArray
- QCache
- QContiguousCache

#### QVarLengthArray

QVarLengthArray容器是个可变长度的底层数组,用来做内存优化.当构造时在栈上预先申请特定长度的数组,如果元素超过该长度,则自动将转到堆内存,这时的行为就与QVector类似。

其典型的应用场景是临时数组需要构造多次,但是元素个数是可变的。

#### QCache与QContiguousCache

QCache与QHash类似,也是用来做内存优化.QCache获取了元素的Ownership,当达到最大大小时会自动将其删除.当新增元素后达到容器最大限制,最后被使用的元素将被删除。

而QContiguousCache与QCache类似,不同之处在于其内部内存连续,内存效率更高。

## API

Qt容器包含了两套API:Qt风格和STL兼容风格.而且提供了两种迭代器:java风格的迭代器和STL风格的迭代器。

虽然Qt风格的API相对易用,但是STL风格API可以与STL算法等配合使用,而且相比STL容器,Qt容器缺少一些功能：

- 范围构造与范围插入
- 无法使用自定义的allocator
- C++11及以上的特性或者API
- 异常处理
- 如果要在Qt容器中使用,该类型必须实现默认构造、拷贝构造和赋值操作
- 因为隐式共享,move-only的类型不会被Qt容器支持

## 隐式共享

Qt容器为最大化内存使用,采用了隐式数据共享,也就是说容器内部使用了引用计数和copy-on-write,当Qt容器被复制,只是浅复制。

虽然带来了低内存使用和避免不必要的数据复制,但是也极易出现一些很难发现的BUG,同时在使用range-for时会导致不必要的深拷贝操作。

## 所以...STL还是Qt?

作者建议使用STL容器作为默认的容器选项,原因如下：

- Qt自身也在替换内部的容器为STL容器
- 正如之前提到的,Qt容器不仅仅是C++11及以上特性没有被实现,一些C++98容器特性还有确实
- 隐式共享会制造出一些难以发现和调试的BUG
- STL容器通常是由实现C++编译器的开发者实现的,相对来讲能够获得更好的优化。

Qt容器并不比对应的STL容器差,如果一些Qt的API返回了对应的Qt容器,这时候还是直接使用,不要将其替换成对应的STL容器。

## 总结

使用Qt容器还是STL容器?这是个问题.个人采用的策略是UI相关的还是使用Qt容器,而与UI无关的代码还是使用STL容器.当然在现有STL还不甚便利的情况下,有一些Qt容器还是相当好用的。
