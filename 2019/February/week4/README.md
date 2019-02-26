# Weekly ARTS

- "224. Basic Calculator" - 基本计算器的实现
- 一些模板元编程的测试/调试技巧
- 应用 Modern CMake
- C++20 特性完成了

## Algorithm [224. Basic Calculator](calculator.md)

## Review [一些模板元编程的测试/调试技巧](TMPDebugTricks.md)

[DDD vs Clean architecture: hosting the business logic](http://objectcode101.com/ddd-vs-clean-architecture-hosting-the-business-logic/)

## Technique [应用 Modern CMake](ModernCMakeApply.md)

## Share C++20 特性完成了

2 月 24 日,C++标准委员会会议冻结了 C++20 的新特性,基本上之前讨论较多的大型特性都将进入 C++20 标准,这意味着应该今年下半年就可以用上 concept、module、contract、range、增强版 constexpr、协程等等.

2 月 26 日,clang 已经可以在 C++2a 标准模式下支持协程.

今年关于 C++的会议新增了好几个,其中 cpponsea 在 twitter 上刷屏,演讲质量都很高.

这两天还有个 C++的 json 解析库发布,simdjson,使用 simd 解析 json,号称解析速度能够达到每秒上 GB 级别.

在 C++包管理方便,Conan、Vcpkg 都在迅速发展,软件构建方面,build2 已经到 0.9.0,CMake 更是频频在各大 C++会议中出现,从传统 CMake 到`Modern CMake`,现在发展到`More Modern CMake`.

能感到 C++社区前所未有的活力,但是天朝的环境却比较尴尬.更多的人弃坑 C++,还有人评论 simdjson,不用,就因为是 C++.

在有很多人努力让这个"世界"变得更好,而你,是不是其中一个?
