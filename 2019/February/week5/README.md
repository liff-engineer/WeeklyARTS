# Weekly ARTS

- Oh The Humanity! - Kate Gregory [C++ on Sea 2019]
- 为现有二进制库提供 `Modern CMake` 适配
- 沟通的基础

## Algorithm [150. Evaluate Reverse Polish Notation](https://leetcode.com/problems/evaluate-reverse-polish-notation/)

上周做了一个表达式计算器的题目,最终虽然 accept 了,但是效率和内存占用都比较高,然后想着这周看一看怎么提高效率.看了下 discuss,发现都是"手写"的代码,根据题目要求来做.之前做含变量表达式计算器,就知道这种东西应用时是分几步的,首先是 token,然后使用调度场算法转换为逆波兰表达式,逆波兰表达式已经移除掉了`(`、`)`等.并且根据表达式优先级调整好了顺序.只需要执行逆波兰表达式运算即可.

这次的题目就是运算逆波兰表达式.运算逆波兰表达式,需要使用栈,运算方式如下:

- 判断是否是运算符,如果是则从结果栈中取参数运算,然后压栈
- 如果不是运算符,则将其转换成整数压栈
- 运算符需要左右两个操作数时,右侧操作符在栈顶,左侧操作符在其下面

搞清楚这个规则之后,运算就非常简单了:

```C++
int evalRPN(vector<string>& tokens) {
    std::stack<int> evals;
    for(auto&& token:tokens)
    {
        if(token == "+" || token =="-" || token =="*" || token =="/")
        {
            auto rhs = evals.top();
            evals.pop();
            auto lhs = evals.top();
            evals.pop();

            if(token =="+")
            {
                evals.push(lhs+rhs);
            }
            else if(token =="-")
            {
                evals.push(lhs-rhs);
            }
            else if(token =="*")
            {
                evals.push(lhs*rhs);
            }
            else if(token =="/")
            {
                evals.push(lhs/rhs);
            }
        }
        else
        {
                evals.push(std::stoi(token));
        }
    }
    return evals.top();
}
```

为什么我没有分析我之前实现的效率问题? 因为既然是算法练习,学的就是算法,为了追求效率根据题目的假设,硬写分析,可能偏离了原先的初衷.

## Review [KEYNOTE: Oh The Humanity! - Kate Gregory [C++ on Sea 2019]](https://www.youtube.com/watch?v=SzoquBerhUc)

两周之前在 Twitter 上, C++ on Sea 刷屏时就看到了 Kate Gregory 的 Keynote 一部分截图,大受触动,在 Youtube 上线视频后第一时间观看,后来才有了原始的 ppt.

我按照我的理解,使用 google 翻译把主要内容的部分提供了中文,就在"Kate Gregory - Oh The Humanity.pptx"中.

这个演讲让我想起了一句话,"明事理、懂人性".引发了我对于自身的反思,从代码中反映的个人情绪(部分情况下人性更为准确?):恐惧、傲慢、自私、懒惰,我自己是否也有这样的情绪?需要不需要改变?

## Technique [为现有二进制库提供 `Modern CMake` 适配](ModernCMakeAdapter.md)

## Share 沟通的基础

最近不是很愉快,工作中跟同事讲了一些方案,发现效果非常差,不得已就自己动手去做了.

过后反思一下,发现问题还是出在我这里,在沟通过程中没有注重方式方法.

通常在沟通过程中,我们会明确目的,但是却忽略了最大的未知问题,就是彼此沟通的基础在哪里?

譬如我希望你去做写某个软件模块,我给你讲解模块是怎么设计,如何实现的.那么彼此沟通的基础,应该是对方已经会进行软件开发,他有能力去完成这个工作.

换一种说法,沟通,需要找到大家这方面认知的"最大公约数".这个就是彼此沟通的基础.我们应当以此为基础来调整我们的沟通内容和方式.

举个工作中的例子,我给大家讲解`Modern CMake`,如果是对 C++的构建有所了解,譬如使用过 Visual Studio,自己创建过静态库、动态库,进行过工程配置.那么我们沟通的基础就是,大家已经知道 C++该如何构建了,那么如果使用`Modern CMake`,该如何去做;而如果对方没有接触过 C++的构建,只是写过`exe`,甚至于没有使用过第三方库,那么沟通的基础就是,他只有编程的基础概念,不知道软件构建流程,这时候就需要从 C++的编译、链接讲起,从而引入头文件、库依赖等问题,然后展示`Modern CMake`如何处理这些问题.

沟通需要技术,认知也要调整,否则达不成我们想要的目的.
