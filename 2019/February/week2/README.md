# Weekly ARTS

- 使用 constexpr 进行编译期编程
- CMake Generator expressions
- 传播"Modern C++"的一种思路

## Algorithm [990. Satisfiability of Equality Equations](https://leetcode.com/problems/satisfiability-of-equality-equations/)

题目要求给定一组方程式`equations`,来表达变量之间的关系,变量名称取自`a-z`这 26 个小写字母,关系只有两种:`==`和`!=`.求是否有对应整数能够满足这组方程式.

可以从两个步骤来看这个问题:

1. 变量关系为`==`时,将其视为染色问题,将其染成同样的颜色,
2. 变量关系为`!=`时,判定两者的颜色关系,如果颜色一样,则不满足互斥条件.

首先最多共 26 种颜色:

```C++
std::array<int, 26> colors;
std::iota(colors.begin(), colors.end(), 0);//染成自己的颜色
```

然后是染色实现:

```C++
int color(std::array<int, 26> &colors, int v)
{
    if (v != colors[v])
        colors[v] = color(colors, colors[v]);
    return colors[v];
}
```

如果颜色不是自己原始的颜色,则需要调整成其目标颜色.

染色过程如下:

```C++
for (auto &&v : equations)
{
    if (v[1] == '=')
    {
        colors[color(colors, v[0] - 'a')] = color(colors, v[3] - 'a');
    }
}
```

完整实现如下:

```C++
int color(std::array<int, 26> &colors, int v)
{
    if (v != colors[v])
        colors[v] = color(colors, colors[v]);
    return colors[v];
}

bool equationsPossible(vector<string>& equations) {
    std::array<int, 26> colors;
    std::iota(colors.begin(), colors.end(), 0);

    for (auto &&v : equations)
    {
        if (v[1] == '=')
        {
            colors[color(colors, v[0] - 'a')] = color(colors, v[3] - 'a');
        }
    }

    for (auto &&v : equations)
    {
        if (v[1] == '!')
        {
            if (color(colors, v[0] - 'a') == color(colors, v[3] - 'a'))
                return false;
        }
    }

    return true;
}
```

## Review [使用 constexpr 进行编译期编程](constexpr.md)

## Technique [CMake Generator expressions](generator_expr.md)

## Share 传播"Modern C++"的一种思路

针对有 C++经验的开发者,如何向其传播"Modern C++"?

很多资料、教程、书籍都是拿新特性,按照分类去讲,不免沦为参考手册,让开发者惆怅于 C++又复杂了,学不会不学了.我觉得这不是一种好的思路.

在我看来,"Modern C++"有其背后的设计哲学存在,从而延伸到新特性的取舍,而这些特性有转而驱动更好的编码实现和应用.

如果要向有 C++经验的开发者传播"Modern C++",需要有清晰的脉络,有主线有目标地传播,新特性也需要有所取舍.

譬如我关注的核心为：现代 C++为开发带来的改变,那么就应当围绕着现代 C++能够带来什么,如何去做,来进行讲述.

- 现代 C++为开发带来的改变
  - 点题
    - C++设计哲学及我的看法
    - 对软件开发由表及里的变换
  - 表达式怎么书写
    - 统一初始化
    - AAA
  - 如何表意
    - 什么应该进入 C++语言/标准库
    - 词汇类型
    - STL 容器及算法
  - 改变的开始
    - RAII
    - Rule of Zero
    - 类型系统
  - 设计模式
    - 工厂模式
    - 监听模式
    - ......
  - 思维方式
    - 模板元编程的应用案例
  - 给开发者带来的价值
  - C++的未来

C++虽然是个复杂的语言,但是语言设计者在考虑时会有一些理念在里面,这些包含了无数开发者的反复思考,更何况现在已经感觉像一门新的语言.在进行传播时不仅要传递特性,更要传递对理念的思考,这样不仅能够有实操,更能引发思考,来达到更好的效果.

## TODO

- [C++ Core Guidelines: Programming at Compile Time with constexpr](https://www.modernescpp.com/index.php/c-core-guidelines-programming-at-compile-time-with-constexpr)
- [Keynote at @cpponsea by @gregcons is really touching](https://twitter.com/pati_gallardo/status/1092355295622426624)
- [CMake and VisualStudio: Group files in solution explorer](https://stackoverflow.com/questions/41078807/cmake-and-visualstudio-group-files-in-solution-explorer/41081377#41081377)
- [C++ idiom of the day: arrow_proxy](https://quuxplusone.github.io/blog/2019/02/06/arrow-proxy/)
- [Build me a LISP — kirit.com](https://kirit.com/Build%20me%20a%20LISP)
- [How to Define A Variadic Number of Arguments of the Same Type - Part 3 - Fluent C++](https://www.fluentcpp.com/2019/02/05/how-to-define-a-variadic-number-of-arguments-of-the-same-type-part-3/)
