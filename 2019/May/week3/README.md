# Weekly ARTS

- 什么是 Mixin
- C++编译期字符串常量哈希
- 你是如何看待别人的意见及建议的?

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

## Share 你是如何看待别人的意见及建议的?

最近要把去年做的一个专项拿出去给公司其他部门讲,过程之中也接收到很多人的反馈,意见建议均有,从中发现了自己看待问题的思路有些偏差,还有事物的描述和表达方面,收益良多.

回想起自己之前,或者说与其他同事处事,感觉很明显的就是:如何去看到别人的意见及建议.

当我们接收到别人的意见和建议,通常的第一反应就是解释,譬如,别人说你这个设计哪里不太合理,我的本能反应就是,我要给你解释,这个问题是这样的,所以才会这样设计. 于是,我们浪费了大量时间在沟通之上,却忘记去消化和理解别人所说的问题,这些意见和建议的价值就这样被忽视了.

虽然说,被误解是表达者的宿命,但是我们总能从别人的意见和建议中得到启发.即使是被误解,至少表明我们尝试表达的内容并没有真正传递给对方,我们可以调整表达的方式、方法,来改善这种情况. 如果有不同的见解和看法,是我们之前所没有想过的,我们可以从这些角度看一看问题是否是这样,消化吸收,使得自己的想法更加完善.

而不可取的方式是,把自己放在"评委"的角度,别人的意见和建议不去思考,转而说这些意见和建议有什么样的问题,在目前的场景中是不合适的.

能够得到别人的意见和建议等反馈,是一件对自己有莫大益处的事情.

## TODO

- [We’re joining Unity to help democratize data-oriented programming](https://blogs.unity3d.com/2017/11/08/were-joining-unity-to-help-democratize-data-oriented-programming/)
- [Why Entity Component Systems matter?](https://www.namekdev.net/2017/03/why-entity-component-systems-matter/)
- [Nomad Game Engine: Part 2 — ECS](https://medium.com/@savas/nomad-game-engine-part-2-ecs-9132829188e5)
- [The Entity-Component-System - An awesome game-design pattern in C++ (Part 1)](https://www.gamasutra.com/blogs/TobiasStein/20171122/310172/The_EntityComponentSystem__An_awesome_gamedesign_pattern_in_C_Part_1.php)
