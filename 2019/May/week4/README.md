# Weekly ARTS

- entt 中 Component 的存储实现
- Unix 编程艺术之紧凑性和正交性
- 《争论 C++前你应当知道什么》读后感

## Algorithm [128. Longest Consecutive Sequence](https://leetcode.com/problems/longest-consecutive-sequence/)

题目要求给定未排序的整数数组,求出最长连续整数序列的长度.并且算法复杂度在`O(n)`.例如`nums={100,4,200,1,3,2}`,其中最长连续整数序列为`1,2,3,4`,即结果为`4`.

这种题目的解决思路是`Union-Find`.这里我们以`unordered_map<int,int> m`来存储元素以及对应的序列长度.则可以得出以下四种情况:

1. `m[v-1]`和`m[v+1]`都不存在,那么`m[v]`只能为`1`
2. 只有`m[v-1]`存在,则`m[v]=m[v-1]+1`,而序列左侧边界`m[v-m[v-1]`需要同步更新,即`m[v-m[v-1]]=m[v]`.
3. 只有`m[v+1]`存在,则`m[v]=m[v+1]+1`,而序列右侧边界`m[v+m[v+1]`需要同步更新,即`m[v+m[v+1]=m[v]`
4. 如果都存在,则`m[v]=m[v-1]+m[v+1]+1`,序列两侧边界均需要扩展.

根据上述情况,实现如下:

```C++
int longestConsecutive(vector<int>& nums) {
    std::unordered_map<int,int> m;
    auto result = 0;
    for(auto v:nums){
        //已经被设置过值,无需计算
        if(m[v])
            continue;
        auto p = m[v-1];//前一个值
        auto n = m[v+1];//后一个值
        if(p+n ==0) //前后都没有值
        {
            m[v]=1;
        }
        else if(p>0 && n > 0)//前后都有值
        {
            //连接起来
            m[v]=p+n+1;
            //左边界
            m[v-p]=m[v];
            //右边界
            m[v+n]=m[v];
        }
        else if(p > 0) //前一个有值
        {
            m[v]=p+1;
            //左边界
            m[v-p]=m[v];
        }
        else if(n > 0) //后一个有值
        {
            m[v]=n+1;
            m[v+n]=m[v];
        }
        result = std::max(result,m[v]);
    }
    return result;
}
```

可以将以上四种情况全部合并,得到实现为:

```C++
int longestConsecutive(vector<int>& nums) {
    std::unordered_map<int,int> m;
    auto result = 0;
    for(auto v:nums){
        //已经被设置过值,无需计算
        if(m[v])
            continue;
        result=std::max(result,m[v]=m[v-m[v-1]]=m[v+m[v+1]]=m[v-1]+m[v+1]+1);
    }
    return result;
}
```

## Review [Unix 编程艺术之紧凑性和正交性](orthogonality.md)

[Chapter 4. Modularity : Compactness and Orthogonality](http://www.faqs.org/docs/artu/ch04s02.html)

## Technique [entt 中 Component 的存储实现](entt_component_storage.md)

## Share 《争论 C++前你应当知道什么》读后感

不知道翻阅什么资料看到了刘未鹏写的[争论 C++前你应当知道什么](https://blog.csdn.net/pongba/article/details/1732055),深有感触,这与我最近这些年关注 C++社区及标准的一些感受比较一致.

如果经常关注 C++的标准,或者说目前各种 C++相关会议的内容,会发现很多都是挖掘语言的某些细节,演讲者谈论其对某些特性的理解,而真正的实践比较少见.我们这些学 C++的貌似都以自己能掌握更多的语言特性,更为奇怪的场景为荣,不少人还热衷于读 STL 等库的源码,貌似只有这样才算会 C++,这是不太好的风气.

C++目前已经发展到 C++20,为什么大家提起 C++就会说很复杂,学习成本太高? 我认为是跟学习 C++的风气有关的.目前 C++发生了"天翻地覆"的变化,而开发者并没有感受到,他们对 C++的印象还是停留在 20 年前.譬如项目组有人还在用 C 的方式用 C++,甚至于 STL 这种东西,有人都觉得复杂,不如用 Qt 容器.要知道 Qt 自身都在逐步将内部代码从 Qt 容器替换为 STL 容器.

我们去讲 C++,给别人"安利"C++,可能并没有站在开发者角度来去思考,C++是如何解决开发者所面临的问题的.编程语言是实现开发者想法的工具,如何将其想法转换成代码,以更简单、表达力更强的方式,这可能才是我们所要讲的重点.

C++标准,或者说标准委员会,考虑的更多是为库开发者提供更好的语言层面的基础设施,让库开发者能够尽最大可能发挥其能力,开发者可以使用这些库以更简洁、更快速、效率更高的方式构建自己的应用程序.我们是有必要去钻研 C++那些复杂的特性,在我们尝试为别人提供更好的基础设施时,这将成为我们强有力的武器.对于广大开发者,则会更关注于使用.

同时,对于我们来讲,我们更应该关注于场景,注重设计,而不是沉迷于"炫技".当你确定了设计方向,然后就可以发挥编程语言最大的潜力了.譬如游戏行业目前流行的 Data Oriented Design,以及其实践架构 Entity Component System,当设计思路确定,就可以利用 C++等语言的各种特性来"秀肌肉",我在阅读 entt 源代码时有这种强烈的感觉,entt 针对应用场景应用各种 C++特性尽可能地保持易用性,追求更高的效率. 而 ECS 这种架构,以及 entt 的实现技术是否能应用到目前的工作之中,则需要打一个大大的问号.

总之,我们应当根据具体的应用场景来考量,用 C++等编程语言来解决问题,让编程语言回归价值,而非观念或者"信仰".

## TODO

- [Software Architecture and Design](<https://docs.microsoft.com/en-us/previous-versions/msp-n-p/ee658093(v%3dpandp.10)>)
- [Data-Oriented Design - Links and Thoughts](http://www.asawicki.info/news_1422_data-oriented_design_-_links_and_thoughts.html)
- [Application Design: Data-driven vs Domain-driven](https://passwork.me/info/blog/applicationdesign)
- [Union-Find Algorithms](https://www.cs.princeton.edu/~rs/AlgsDS07/01UnionFind.pdf)
