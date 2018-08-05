# Weekly ARTS

## Algorithm [238. Product of Array Except Self](ProductOfArrayExceptSelf.md)

这次做的题目比较有意思,让我萌生了再读一读《怎样解题-数学思维的新方法》的想法。

## Reivew [Code Quality – Cyclomatic Complexity](https://blog.feabhas.com/2018/07/code-quality-cyclomatic-complexity/)

之前读类似`Clean Code`之类的书籍,总会聊些函数不应该超过多少行等等问题,还有些替换`switch`的写法。一般依赖于程序员学习了解实践、还有就是代码审查中提出问题,那么有没有一些量化的方法来衡量代码复杂性,进而提醒程序员去简化实现呢?

本文就通过一些示例描述了代码复杂度衡量的方法与工具,譬如：

![函数复杂度](https://i2.wp.com/blog.feabhas.com/wp-content/uploads/2018/07/graph-1.png)

将每个语句块作为图中的节点,通过有向图来表达整个函数,然后再使用`v(G)=e-n+2`,即图中边的个数-节点个数+2,即可得到量化的函数复杂度。

在《Code Complete》书中，给出了如下复杂度指导：

![函数复杂度判断](https://i2.wp.com/blog.feabhas.com/wp-content/uploads/2018/07/table2.png)

可以设定相应的复杂度限制整合到CI中,从而阻止有人提及过于复杂的实现。

## Technique [Elementary string conversions](P0067R5.md)

在C++17中 [P0067R5 Elementary string conversions](http://www.open-std.org/jtc1/sc22/wg21/docs/papers/2016/p0067r5.html)提供了标准化的整数、浮点数与字符串之间转换的方法,能够满足如下要求:

- no runtime parsing of format strings
- no dynamic memory allcoation inherently required by the interface
- 不考虑locale
- 不需要通过函数指针等方式
- 防止缓冲区溢出
- 当解析字符串时,如果无效可以得到错误信息
- 当解析字符串时,空格等不会被默认忽略

最重要的是有性能上的保证。

## Share [尽信书不如无书](AboutEffectiveCppItem36.md)

《Effect C++》中说到:
>Item 36: Never redefine an inherited non-virtual function.

这是我们在使用中都应当遵循的原则么? 我的答案：是，但是要分情况。

针对指南、原则等等需要去深入了解,不应该在使用过程中一概而论,因为在一些场景中这些内容可能并不适用。