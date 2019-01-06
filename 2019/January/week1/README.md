# Weekly ARTS

- `416. Partition Equal Subset Sum` 的实现解读
- 现代 CMake 简介
- C++中的 Visitor 模式的实现方式
- 你知道`itoa`的涵义么

## Algorithm [416. Partition Equal Subset Sum 的实现解读](leetcode416.md)

一个动态规划问题的实现解读,以及其采用位运算的解法分析.

## Review [现代 CMake 简介](ModernCMakeIntro.md)

针对现代 CMake 的一些文章的理解和简单汇总.

## Technique [C++中的 Visitor 模式的实现方式](CxxVisitor.md)

如何使用 C++实现`Visitor`模式.

## Share 你知道`itoa`的涵义么

`range-v3`的作者 Eric Niebler 发表的文章[Standard Ranges](http://ericniebler.com/2018/12/05/standard-ranges/)后来在 Twitter 上引起广泛的后续讨论,之后开始了各种劝退 C++20 等等之类的探讨,以至于 Sean Parent 也做出了回应["Modern" C++ Ruminations](https://sean-parent.stlab.cc/2018/12/30/cpp-ruminations.html).

> Not knowing the history of iota() should not be something to be proud of, but an embarrassment.

读了 Sean Parent 的文章,对上面这句话印象颇深.

据我所知,现在不少用 C++的软件工程师,STL 算法在工作中也比较少使用,他们都倾向于直接用`for`循环,更遑论`itoa`这个相对生僻的算法.

那么在现在软件开发门槛越来越低的趋势下,要求 C++开发者能够使用甚至于最基本的看懂 STL 算法,是否是比较高的要求?

同样的问题也适用于新的语言特性等等.大家都在"抱怨"C++越来越复杂,纷纷表示弃坑时,有没有想过,开发者是否应当给自己提出"更高"的要求,而不是抱着算法没什么用,语言大同小异,拿 Java 的方式写 C++,用 C++只用 C 和类,连个代码都不琢磨一下怎么写得够好?

在我看来 STL 算法只是 C++开发者的基本要求,在 C++20 出现之后`ranges`也应当列入基本要求,任何一个声称熟悉 C++语言的开发者都应当能够熟练应用`ranges`,学习成本是有,但是这是必须要付出的,而且是能够带来很大收益的.任何有追求的开发者都应当去适应变化,而不是延续着旧思维,觉得`for`循环已经足够.

为什么? 去看一看 Sean Parent 的`No Raws loop`演讲,去体会一下算法带来好处.或者来探讨一下标准库的意义.

什么样的语言特性/库应当进入 C++标准?反过来说,为什么需要这些标准?

编码是为了人与人之间的沟通,这个涉及到表达意图,每个人都有自己的表达方式,如果需要高效地表达意图,譬如实现排序动作,手写各种排序算法总没有`std::sort`函数族表意能力更强吧? 标准/标准库就是用来提供一些大家共同使用的"语言要素",以此来清晰、高效地表达代码意图,增强代码的可维护性.

我们有 STL 算法来表达意图,为什么把所有内容都写到`for`循环中来增加别人的理解成本?

再举个例子,由于不是科班出身,我一直对 UML 不太感兴趣,做设计也不做类图之类的东西,可是随着时间的推移,我的看法也发生着改变,使用 UML 并不是说它有多好,而是你用 UML 来表达,别人能够看得懂!

不明白`itoa`的涵义,不会画`UML`,学不会 C++所以弃坑,没有什么可以骄傲的.对于软件工程师来讲,有些东西是你需要去掌握的,而不能因为自己努力不够去堂而皇之地排斥它,diss 它,甚至因此去`Judge`别人.

## TODO

- [图说设计模式](https://design-patterns.readthedocs.io/zh_CN/latest/index.html)
- [Don’t use wrapper](https://schneide.blog/2019/01/03/dont-use-wrapper/)

关于表述,智能指针是`Proxy`模式,`PIMPL`是`Adapter`模式,不应当什么都使用`wrapper`.还有一些修饰器什么的,多使用通用语言.

- [Installing and Using Packages Example: SQLite](https://github.com/Microsoft/vcpkg/blob/master/docs/examples/installing-and-using-packages.md)

现代 CMake 实践.
