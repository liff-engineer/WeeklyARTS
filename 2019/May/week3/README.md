# Weekly ARTS

- 什么是 Mixin
- C++编译期字符串常量哈希

## Algorithm [771. Jewels and Stones](https://leetcode.com/problems/jewels-and-stones/description/)

题目要求给定两个字符串`J`和`S`,`J`中字符串只包含字母,且大小写敏感,`J`中的字母代表是宝石,计算`S`中包含的宝石个数.

这个题目非常简单,鉴于宝石的类型有限,这里将其存储到`bitset`中,通过遍历`J`指定宝石,然后遍历`S`检测宝石.

```C++
int numJewelsInStones(string J, string S) {
    constexpr std::size_t N = 'z' - 'A' + 1;
    std::bitset<N> jewels{0};
    for (auto ch : J)
    {
        jewels.set(ch - 'A');
    }

    int number = 0;
    for (auto ch : S)
    {
        if (jewels.test(ch - 'A'))
            number++;
    }
    return number;
}
```

最终运行结果比双层循环的方案要差,不明白为什么.

## Review [什么是 Mixin](mixins.md)

## Technique [C++编译期字符串常量哈希](compile_string_hash.md)

## Share

## TODO

- [We’re joining Unity to help democratize data-oriented programming](https://blogs.unity3d.com/2017/11/08/were-joining-unity-to-help-democratize-data-oriented-programming/)
- [Why Entity Component Systems matter?](https://www.namekdev.net/2017/03/why-entity-component-systems-matter/)
- [Nomad Game Engine: Part 2 — ECS](https://medium.com/@savas/nomad-game-engine-part-2-ecs-9132829188e5)
- [The Entity-Component-System - An awesome game-design pattern in C++ (Part 1)](https://www.gamasutra.com/blogs/TobiasStein/20171122/310172/The_EntityComponentSystem__An_awesome_gamedesign_pattern_in_C_Part_1.php)
