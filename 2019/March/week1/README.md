# Weekly ARTS

- 不要使用`using namespace std`
- 使用 Modern CMake 构建 SDK
- "编程"不应该这么难

## Algorithm [962. Maximum Width Ramp](https://leetcode.com/problems/maximum-width-ramp/)

题目要求给定整数数组`A`,针对索引对`i`和`j`,满足`i<j`且`A[i] <= A[j]`,定义其宽度为`j-i`.求出满足条件的索引对中最大宽度是多少.如果没有找到返回`0`.

老规矩,先解题.两层循环查找最大宽度:

```C++
int maxWidthRamp(vector<int>& A) {
    if (A.empty()) return 0;

    int result = 0;
    for (int j = A.size() - 1; j >= 0; j--)
    {
        for (int i = 0; i < j; i++)
        {
            if (A[j] >= A[i])
            {
                result = std::max(result, j - i);
            }
        }
    }
    return result;
}
```

跑了一遍结果都正确,一提交超时了...... 那就修改控制条件,使其提前退出,避免无用功:

```C++
int maxWidthRamp(vector<int>& A) {
    if (A.empty()) return 0;

    int result = 0;
    for (int j = A.size() - 1; (j >= 0)&&(j>result); j--)
    {
        for (int i = 0; (i < j) && (j-i > result); i++)
        {
            if (A[j] >= A[i])
            {
                result = std::max(result, j - i);
            }
        }
    }
    return result;
}
```

这次提交确实通过了,但是运行速度在所有已`accept`的提交中在最差的那`15%`里.也就是说这个问题有高效的算法,采用目前这种方式算是"投机取巧",为了通过而已.

直觉告诉我,有方法可以遍历一遍数组,然后记录下来索引/值的顺序,然后再来一遍遍历就可以找到结果.至于怎么记录,可采用`std::vector<std::pair<int,int>>`,然后实现排序动作.但是具体实现发现不是那么回事.

后来查阅了`Discuss`,才明白自己欠缺的点还是非常多的.具体的思路如下:

1. 使用`stack`从大到小记录下对应的索引
2. 反向遍历,在满足条件的过程中一直从栈顶弹出,并记录过程结果.

这种方式,`stack`记录了索引值,而且已经排好了顺序;反向遍历时,在尝试弹出栈顶的过程中一直找的是满足条件的最大值/最小索引.具体实现如下:

```C++
int maxWidthRamp(vector<int>& A) {
    if (A.empty()) return 0;

    //栈内保存的值越来越小
    std::stack<int> v;
    v.push(0);
    for (auto i = 1ul; i < A.size(); i++)
    {
        if (A[v.top()] > A[i])
            v.push(i);
    }

    int result = 0;
    for (int i = A.size() - 1; i > result; i--)
    {
        while (A[v.top()] <= A[i])
        {
            result = std::max(result, i - v.top());
            v.pop();
            if(v.empty())
                return result;
        }
    }

    return result;
}
```

看来我这不仅算法欠缺,数据结构的基础也是非常差,路漫漫其修远兮......

## Review [不要使用`using namespace std`](https://akrzemi1.wordpress.com/2019/03/14/not-using-namespace-std/)

```C++
using namespace std;
```
这个被称为`using directive`.在需要工作多年的代码中使用它并不是一个好的实践.

有时别人会建议你直接使用`using namespace std`,这样标准库里的所有东西都可以很简单地使用,不需要再添加`std::`前缀了.当你刚开始学习`C++`,或者要写一些示例,或者写小型的私人项目,可以采用这种方式.因为对于这些程序,如果你更换了编译器或者语言版本之后编译不过并不是大问题.

`using namespace std;`使得所有定义在`std`命名空间的所有符号在全局命名空间可用,不需要`std::`.你不需要知道`std`命名空间有多少`名称`,以及其含义.如果你升级到新的`C++`版本,有更大的标准库,将会有更多的`名称`注册到全局命名空间:或许有一些`名称`你已经在你自己的程序中声明过了.


假设你用C++14编写的程序,你在程序中使用了`using namespace std;`,而你又在全局命名空间中定义了自己的类型,`byte`.也可能你定义了这样的函数.当然,你可能不会将它声明到全局命名空间,你将其声明到`my_namespace`,然后使用了`using namespace my_namespace;`.这时可以在程序中以很简洁的方式使用:

```C++
#include <string>
using namespace std;
 
class byte {};
 
int main()
{
  byte b;
  // ...
}
```

然后,过了一段时间,你将程序所用的C++版本升级到了C++17.你可能不知道在C++17在`std`命名空间定义了枚举类型`byte`,或许你没想到它在`<string>`中.但是突然之间,名称`byte`变得含混不清,你有两种`byte`能够在全局命名空间找到.如果这种情况出现在大型项目的很多文件中,修复这个问题就会变得复杂.

这是因为`using namespace std;`不仅仅意味着"注入所有定义在`std`中的名称,即使是我不知道的",同时也意味着,"无论未来有什么名称添加到`std`,即使它们与我的定义冲突,也要注入到全局命名空间".

作为`using namespace std;`的替代品,这里建议要么将所有的标准库组件使用都添加上`std::`,或者针对你要使用的标准库组件用`using declaration`注入:

```C++
#include <string>
using std::string;
```

事实上,这个建议适用于任何你无法控制的命名空间,不仅仅是`std`.

## Technique [使用 Modern CMake 构建 SDK](ModernCMakeforSDK.md)

## Share "编程"不应该这么难

最近在项目组中换`Modern CMake`,比较艰难,因为 C++的构建涉及比较多的内容,工程物理结构,编译、链接、安装、导出,第三方库的使用,打包,等等等等.每一步都是坎儿,譬如:

- 在`Modern CMake`里如何使用`Qt`
- 怎么组织工程的物理结构
- 现有的第三方库如何以`Modern CMake`方式使用
- 动态库依赖如何复制到输出目录
- 资源文件,工具等如何打包
- 并行编译、预编译头、联机编译
- 怎么正确导出自己构建的库
- 怎么导出`SDK`-大量动态库的构建与输出

即使是`Modern CMake`已经很简单了,依然有很多语焉不详,或者说没有形成完整实践的内容.

同样的,`Modern C++`该如何学习?新手如何入门,如何成长,都是说不清楚的事情.

哪怕是以简单著称的`Python`,我在使用`pybind11`为 C++模块提供`Python`语言接口时,也面临到如何构建的问题.确实无法苛责`pybind11`的开发者门,但是我知道要扩展`setuptools`,可是没有文档说明该如何扩展啊,使用`setuptools`打包的过程何曾有过描述? 只能在`stackoverflow`上找到一些零零碎碎的解答: [Extending setuptools extension to use CMake in setup.py?](https://stackoverflow.com/questions/42585210/extending-setuptools-extension-to-use-cmake-in-setup-py)

之前看`Kate Gregory`的 `Oh The Humanity`演讲,再回头看看目前我面临的这些状态,就能深切体会到`Kate Gregory`所说的代码中的`emotion`:

- 恐惧
- 傲慢
- 自私
- 懒惰

诚然,确实编程在一些方面比较难,但是是不是有一些艰难的场景就是我们自身造成的? 我们出于什么样的`emotion`,将生态环境搞得如此艰难.或许你可以去问一问哪些"新手",他们感受到的是什么.
