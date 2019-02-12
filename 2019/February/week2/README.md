# Weekly ARTS

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

## Technique

## Share

## TODO

- [C++ Core Guidelines: Programming at Compile Time with constexpr](https://www.modernescpp.com/index.php/c-core-guidelines-programming-at-compile-time-with-constexpr)
- [Keynote at @cpponsea by @gregcons is really touching](https://twitter.com/pati_gallardo/status/1092355295622426624)
- [CMake and VisualStudio: Group files in solution explorer](https://stackoverflow.com/questions/41078807/cmake-and-visualstudio-group-files-in-solution-explorer/41081377#41081377)
- [C++ idiom of the day: arrow_proxy](https://quuxplusone.github.io/blog/2019/02/06/arrow-proxy/)
- [Build me a LISP — kirit.com](https://kirit.com/Build%20me%20a%20LISP)
- [How to Define A Variadic Number of Arguments of the Same Type - Part 3 - Fluent C++](https://www.fluentcpp.com/2019/02/05/how-to-define-a-variadic-number-of-arguments-of-the-same-type-part-3/)
