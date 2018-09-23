# Weekly ARTS

- "动态规划算法"练习
- 使用模板实现事件/消息处理的一种方法
- 正在"开发"中的Visual C++工程"零配置"方案
- 简单谈一谈我对C++模板应用的看法

## Algorithm - ["动态规划算法"练习](DP02.md)

本周练习了三个算法题目,比较坎坷,貌似被套路了。

## Reivew [使用模板实现事件/消息处理的一种方法](event_interface.md)

最近看了一篇C++模板的教程, [Dr. Strangetemplate - Or How I Learned to Stop Worrying and Love C++ Templates](https://github.com/MCGallaspy/dr_strangetemplate),里面有个示例很有意思,解读了一下。

## Technique - [VcUser - 如何实现指定规则的资源文件同步](VcUserP3.md)

正在"开发"中的Visual C++工程"零配置"方案:

- [VcUser - VcUser是什么](https://github.com/liff-engineer/WeeklyARTS/tree/master/2018_9_1/VcUserP0.md)
- [VcUser - 如何实现解决方案级配置](https://github.com/liff-engineer/WeeklyARTS/tree/master/2018_9_1/VcUserP1.md)
- [VcUser - 如何实现构建结果配置](https://github.com/liff-engineer/WeeklyARTS/blob/master/2018_9_2/VcUserP2.md)
- [VcUser - 如何实现指定规则的资源文件同步](VcUserP3.md)

## Share 简单谈一谈我对C++模板应用的看法

C++模板绝对是个很好的技术,除了平时工作中用到的STL,最近使用[JSON for Modern C++](https://github.com/nlohmann/json)来处理json,无比畅快,相见恨晚。

可问题是在工作之中很少见到可以把模板应用到相对层次较高的软件设计上,基本上都是作为库来使用,自身代码库上很少见,这次读了篇教程介绍模板的用法时给了个Use Case,粗看惊艳,实际上你要尝试用那种写法来替换常规的OO写法基本上困难重重,会面临各种问题。

究其原因,一方面我们已经广泛接受了OO的写法,对于这种代码能够自然而然地理解与书写;另外一方面模板自身,入门门槛略高,不容易掌握,要实现与OO对应设计同样的功能不仅需要考虑更多,而且在写法上困难重重,又有诸多限制。

在我看来,可能模板更适合来写个库使用,而不适合来搭建框架,构建整体设计;普通的开发能够理解和使用即可,无需对模板深入钻研。

另外,如果你追求更高的性能,更简洁的代码,推荐你付出精力钻研下。