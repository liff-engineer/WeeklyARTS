# Weekly ARTS

- `Concepts`简介
- Flip Model 设计模式
- 关于`Standard Ranges`引发的讨论

## Algorithm

## Review [`Concepts`简介](concepts.md)

## Technique [Flip Model 设计模式](FlipModel.md)

## Share 关于`Standard Ranges`引发的讨论

[range-v3](https://github.com/ericniebler/range-v3)的作者在 2018 年的 12 月 4 日发布了一篇博文[Standard Ranges](http://ericniebler.com/2018/12/05/standard-ranges/),然后经过两三周的发酵,酿成了一场大范围的讨论,详见:

- 主要"战场":["Modern" C++ Lamentations](http://aras-p.info/blog/2018/12/28/Modern-C-Lamentations/)及[twitter](https://twitter.com/aras_p/status/1078682464602726400)
- [Reddit 讨论](https://www.reddit.com/r/programming/comments/aac4hg/modern_c_lamentations/)
- [Hacker News 讨论](https://news.ycombinator.com/item?id=18777735)
- 还有知乎如何评价体[如何评价 "Modern" C++ Lamentations ？](https://www.zhihu.com/question/307348605/answer/562411756)

由于[Standard Ranges](http://ericniebler.com/2018/12/05/standard-ranges/)这篇博文刚一发出我就研读了两遍,没有在 C++社群上看到对其的大规模讨论,看到 InfoQ 的推送也在微信群里"狡辩"了几句,直到假期回来才发现 Twitter 上讨论"疯了".

所以,争论的焦点在哪里?

1. 写法
1. 编译时间
1. 非优化版本运行性能

源头是写法,C++标准委员会倾向于不增加语言特性,而是以库形式实现.而`range-v3`的作者在文中所举的示例确实很难懂,比较糟糕.但是后续的焦点不在这里.

由于 C++语言以及模板实现机制的原因,编译时间对于很多稍大点儿的项目都是比较不能接受的.即使是预编译头、并行编译、联机编译这些手段都加上,编译时间也比较可怕.

然后是非优化版本运行性能,C++号称`zero-overhead abstraction`,基本上是内敛等各种优化手段,需要开启编译器优化,而针对调试版本或者非优化版本,与优化版本相比,运行性能实在是低到可怕,这严重影响了软件调试和 BUG 分析等,在我实际工作之中,哪怕工作环境也都是拿`Release`版本进行调试.

争论的问题确实存在,也确实如争论文章所言,C++在这些方面的表现实在是糟糕.更别说语言复杂度了.

所以,我对这个事情的看法是,短期内不会发生改变,你可以"弃坑",也可以采用 C++的子集来实现你的应用.

而对于那些"被迫"使用 C++的开发者,我对这个事情有不同看法:语言的设计有其考量和平衡,我们选择和使用语言也有其目的和侧重点.

关注的重点是什么?能不能达到目的.

有问题?可以得到解决或者缓解.譬如 Python,性能为人诟病,依然挡不住大家喜爱,性能不够 C/C++来凑.

没必要去唱衰,甚至于义愤填膺.
