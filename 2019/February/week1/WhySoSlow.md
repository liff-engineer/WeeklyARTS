# 在 MSVC 中如何分析构建效率

C++项目构建效率一直是个痛点,最近阅读到几篇文章,涉及到一些方式方法来具体分析其构建效率,从而为优化提供指导:

- [Best unknown MSVC flag: d2cgsummary](http://aras-p.info/blog/2017/10/23/Best-unknown-MSVC-flag-d2cgsummary/)
- [Another cool MSVC flag: /d1reportTime](http://aras-p.info/blog/2019/01/21/Another-cool-MSVC-flag-d1reportTime/)
- [Debug compile times in Unreal Engine & MSVC projetcs](https://github.com/Phyronnaz/UECompileTimesVisualizer)
- [Visual Studio 2017 Throughput Improvements and Advice](https://blogs.msdn.microsoft.com/vcblog/2018/01/04/visual-studio-2017-throughput-improvements-and-advice/)

## [编译选项`/Bt`、`/Bt+`](https://blogs.msdn.microsoft.com/vcblog/2010/04/01/vc-tip-get-detailed-build-throughput-diagnostics-using-msbuild-compiler-and-linker/)

为工程的编译器添加`/Bt`和`/Bt+`后,能够输出`c1xx`(前端编译器)和`c2`(后端编译器)分别的耗时.

使用 C++的开发者都知道如果添加了太多头文件会导致编译耗时增加,这个问题属于前端问题.但是优化器执行优化的过程耗时就属于后端问题了.通过定量分析就可以知道优化方向是什么.

## 编译器选项`/d2cgsummary`

为工程的编译器添加上`/d2cgsummary`选项后,会输出一些代码生成的统计信息.譬如代码生成耗时,生成函数数量,平均耗时,以及一些"异常编译时间",可以看到哪些函数编译耗费了相对较多的时间.

同时还会输出缓存统计信息,函数缓存,命中率等等.

## 编译器选项`/d1reportTime`

为工程的编译器添加上`/d1reportTime`选项后,编译器会输出以下信息:

- 哪些头文件被包含(层级显示),以及其处理耗时
- 哪些类被解析,以及其解析耗时
- 哪些函数被解析,以及其解析耗时

在每个内容后会列出耗时`Top N`.

## 链接器选项`/time`

为工程的链接器添加`/time`选项后,能够输出链接器在各个阶段的耗时.

## 分析工具支持

[Debug compile times in Unreal Engine & MSVC projetcs](https://github.com/Phyronnaz/UECompileTimesVisualizer)中提供了可视化的统计工具,用来快速分析定位问题.

同时 MSVC 的开发者在[Reddit](https://www.reddit.com/r/cpp/comments/agv34v/timetrace_timeline_flame_chart_profiler_for_clang/eegqevb/?st=jr6n23xf&sh=99d858e5)上声称其正在开发基于 ETW/WPA 的可视化构建耗时分析工具.

## 总结

在短时间内 C++工程构造慢这个问题不会得到根本性的解决,不过我们可以使用一些技术来缓解这种状况.其中[Visual Studio 2017 Throughput Improvements and Advice](https://blogs.msdn.microsoft.com/vcblog/2018/01/04/visual-studio-2017-throughput-improvements-and-advice/)值得读一读.
