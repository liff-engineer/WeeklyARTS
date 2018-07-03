# Why?
Herb Sutter的 [Trip report: Summer ISO C++ standards meeting (Rapperswil)](https://herbsutter.com/2018/07/02/trip-report-summer-iso-c-standards-meeting-rapperswil/)中说到这次的头条新闻就是:
>
> [Contracts (Gabriel Dos Reis, J. Daniel Garcia, John Lakos, Alisdair Meredith, Nathan Myers, Bjarne Stroustrup)](https://wg21.link/p0542) was formally adopted for C++20.
>

在文中,Herb Sutter声称 **Contracts** 能够为正确性和性能带来巨大提升,这吸引了我的注意力,之前关注最新的C++标准,主要集中在Module、Network等方面,从未关注过Contracts。

Contracts到底是什么?为何能够为正确性及性能带来巨大提升?

老套路,阅读一下标准提案来看看吧。

# 阅读材料

1. [Support for contract based programming in C++](http://www.open-std.org/jtc1/sc22/wg21/docs/papers/2018/p0542r4.html)
> 其中描述该提案是基于P0380

2. [P0380R1 - A Contract Design](http://www.open-std.org/jtc1/sc22/wg21/docs/papers/2016/p0380r1.pdf)
> 该提案大概看了下还是比较偏向语法等内容,根据参考资料,查阅其参考来源,看看那些参考源内容会比较倾向于解释性内容。

3. [N4319 - Contracts for C++: What Are the Choices?](http://www.open-std.org/JTC1/SC22/WG21/docs/papers/2014/n4319.pdf)
> 该文档中声称其基于N4135提案进行探讨

4. [N4135 - Language Support for Runtime Contract Validation (Revision 8)](http://www.open-std.org/JTC1/SC22/WG21/docs/papers/2014/n4135.pdf)
> 浏览了一下该标准提案,基本上将`contract`的来龙去脉讲得比较清楚

根据上述资料反向阅读,应该能够搞清楚`contract`的内容。

# TODO
学习了解一下`contract`,以及其能够带来的改变,是否真的如Herb Sutter所说那样：
> In my opinion, contracts is the most impactful feature of C++20 so far, and arguably the most impactful feature we have added to C++ since C++11. 



