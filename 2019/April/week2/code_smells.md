# [10 种静态分析可以识别的代码味道](https://www.fluentcpp.com/2019/03/26/10-code-smells-a-static-analyser-can-locate-in-a-codebase/)

注,这虽然是一篇"硬广告",其中包含的信息也值得我们惊醒.

静态代码分析不仅仅能够来查找 BUG,也能够用来查找那些能够降低代码可读性、可维护性、容易引起 BUG 的情况.静态代码分析可以用来处理代码的其它信息:

- 代码度量: 例如包含太多循环、`if`、`else`、`switch`、`case`的方法,最终变得无法理解,导致无法维护.通过代码度量循环复杂度能够判断出来方法是否变得太复杂.

- 依赖: 如果你程序中的类纠缠在一起,代码中任何修改造成的影响将会无法预测.静态代码分析能够帮助你判断类与组件是否互相纠缠.

- 不变性: 被多个线程并发使用的类型需要是不可变的,否则你需要使用复杂的锁定策略来保护状态的读写访问,最终导致无法维护.静态代码分析可以确保某些类是保持不可变的.

- 死代码: 死代码是那些可以安全地益处的代码,因为其在运行期不会被使用.不仅是它可以被移除,而且它应当被移除,这些代码只会增加程序不必要的复杂度.静态代码分析可以找到程序中大量的死代码.

- 破坏 API 的改变:如果你为客户提供了 API,很容易出现你移除了一个公共方法但是没有注意,导致破坏了客户的代码.静态代码分析可以对比两个版本的代码来帮助你发现这些问题.

代码味道可以认为是容易出现 BUG 的场景,让我们看一看静态代码分析工具如何帮助你检测代码坏味道.

## 代码味道

下面是维基百科中对于代码坏味道的定义:

> In computer programming, code smell, (or bad smell) is any symptom in the source code of a program that possibly indicates a deeper problem. According to Martin Fowler, “a code smell is a surface indication that usually corresponds to a deeper problem in the system”. Another way to look at smells is with respect to principles and quality: “smells are certain structures in the code that indicate violation of fundamental design principles and negatively impact design quality”.

代码坏味道通常不是 BUG,他们不是技术错误,不会导致程序功能不正常.相反,他们表示设计中存在弱点可能会降低开发速度,或者增加未来 BUG 出现的风险.代码坏味道可以视为导致技术债的因素指示.

有很多有趣的工具用来检测你 C++代码中的 BUG,譬如 cppcheck、clang-tidy 和 visual studio analyzer. 但是针对那些容易出 BUG 的场景检测呢?

如果静态分析工具创建者可以决定哪些情况下视为错误,这不是代码味道的情况下取决于开发团队的选择.例如一个团队可以认为一个方法有超过 20 行代码味道,另一个团队可以设置它的限制到 30.如果一个工具提供了代码的检测气味,它也必须提供定制它的可能性.

## 代码作为数据来检测代码味道

静态分析的想法是分析源代码的各种属性,并报告这些属性,但它也是,更普遍的想法是将代码作为数据进行分析.

这个对于我们这些应用程序开发者来说听起来可能比较奇怪,我们通常的想法是源代码,是指令、过程、算法.

这个想法是为了分析源代码文件,提取其 AST 和生成一个模型包含大量的相关数据的代码.这样我们就可以通过类似于 SQL 的代码查询语言来进行查询.

CppDepend 提供了代码查询语言-CQLinq 用来像操作数据库一样查询代码.开发者,设计师和架构师可以定义他们自己的查询语句来查找容易出 BUG 的场景.

使用 CQlinq 我们可以结合代码度量的数据,依赖,API 的使用和其他模型相匹配的数据定义复杂的查询一些易出错的情况.

以下是一个用来检测大多数复杂方法的 CQLinq 查询:

![imag2](https://www.fluentcpp.com/wp-content/uploads/2019/03/image2.png)

让我们看看 10 种常见的代码味道,以及如何使用 CQLinq 检测他们:

### 太庞大的类型

类型实现使用了太多行对于维护来讲是负担.如果你认为 200 行是合适的限制,你可以使用`NbLinesOfCode`定位那些超过 200 行的类型:

![imag3](https://www.fluentcpp.com/wp-content/uploads/2019/03/image3.png)

这里是一些重构建议:

- 目标是将类拆分成较小的类,这些较小的类可以是扩展类或者私有类,被包裹到原有类中,原有类实例变成较小的类实例的组合.
- 针对较小的类的划分应当以不同职责来进行.识别这些职责,可以通过查看与字段的子集紧密耦合的方法子集.
- 如果类的定义逻辑多余状态,你可以定义一个或者多个全局函数.
- 尝试维护类的接口和委托调用新提取的类,最终,类应该只是个 facade,没有自己的逻辑.然后你可以为了方便保留它或者移除它,并开始使用新类.
- 单元测试可以提供帮助:为每个方法提供测试来保证你抽取过程中不会破坏功能.

### 包含太多方法的类型

另一个类型复杂度度量是方法的个数.如果类型包含太多方法,这表明类型有太多职责需要实现.

以下是检测这种情况对应的 CQLinq:

![imag1](https://www.fluentcpp.com/wp-content/uploads/2019/03/image1.png)

### 包含太多成员的类型

与包含太多方法的情况类似,包含太多成员可能表示类型有太多职责.

以下是检测有太多成员的类型的 CQLinq:

![imag5](https://www.fluentcpp.com/wp-content/uploads/2019/03/image5.png)

### 长方法

包含太多行的方法不容易维护和理解.以下是检测超过 60 行长的方法的实例:

![imag4](https://www.fluentcpp.com/wp-content/uploads/2019/03/image4.png)

上述示例是检测的 Unreal 引擎代码,整个代码包含超过 15 万方法,也就是不到 1%的方法被视为太大(如果限制是 60 行).

### 方法包含太多参数

包含太多参数的方法比较难以理解,因为作为人类,我们同时追踪过多对象是非常艰难的.

这里是检测方法包含超过 7 个参数的示例:

![imag7](https://www.fluentcpp.com/wp-content/uploads/2019/03/image7.png)

以上是检测虚幻引擎代码的结果,可以看到只有 0.5%的方法有 8 个及以上的参数,大部分是泛型,来模拟可变参数函数.

### 方法包含太多局部变量

局部变量越多,你为了理解整个函数就需要跟踪越多东西.

以下是检测方法超过 20 个变量的示例:

![imag6](https://www.fluentcpp.com/wp-content/uploads/2019/03/image6.png)

### 太复杂的方法

这里有一些其它度量来检测复杂方法：

- 循环复杂度
- 嵌套深度
- 最大嵌套循环

这些度量的最大可容忍值取决于团队选择,没有标准值.

让我们试着在虚幻引擎代码中查找那些太复杂的方法:

![imag8](https://www.fluentcpp.com/wp-content/uploads/2019/03/image8.png)

### 方法有太多重载

通常"太多重载"的情况出现于算法需要获取不同设置的参数集合.有一部分重载使用起来相对便利,但是太多重载就会引起困惑.

还有种"太多重载"的情况是因为使用了`visitor`设计模式导致的,这种情况下不需要调整.

以下是检测这种情况的示例:

![imag11](https://www.fluentcpp.com/wp-content/uploads/2019/03/image11.png)

### 耦合

低耦合是我们所希望的,因为应用程序中一部分的变更会引起比较少的变化,从长期来看,低耦合在修改或者添加新特性时节省了大量时间,努力,与代价.

C++提供了多种方法来减少使用多态带来的耦合.例如抽象类、泛型.

让我们来查询以下虚幻引擎中的所有抽象类:

![imag9](https://www.fluentcpp.com/wp-content/uploads/2019/03/image9.png)

只有很少的类型被声明为抽象类.低耦合更多是通过使用泛型类和泛型方法来做的.

这里是检测包含至少一个泛型方法的方法示例:

![imag10](https://www.fluentcpp.com/wp-content/uploads/2019/03/image10.png)

我们看到很多方法使用了泛型,低耦合是通过函数模板参数来保证的.

### 内聚

正如 Robert Martin 指出的,单一职责原则表现为"一个类只有在一种情况下才需要改变".这种类可以被称为内聚:所有的成员都是为某个职责服务的.

为了测量类的内聚,可以使用 LCOM 作为指标.LCOM 意为缺乏内聚的方法(Lack of Cohesion of Methods),即高 LCOM 值意味着类内聚程度差.

注:太复杂了,详情阅读原文.

LCOM 值大于 1 应当考虑,让我们测试一下虚幻引擎中超过 10 个成员、10 个成员方法、LCOM 值大于 1 的类:

![imag13](https://www.fluentcpp.com/wp-content/uploads/2019/03/image12.png)

只有很少的类型被视为太多且不内聚.

## 试试你的代码

上面的查询都运行在虚幻引擎代码上,但这不意味着只能用于它上面.很多情况也适用于你的代码.他们会帮助你找到热点和修复,提高代码的质量和表现力.
