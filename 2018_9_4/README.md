# Weekly ARTS

- 何时用`auto`
- 如何整合3D内容到Qt Graphics View
- 自我学习太累太苦效率太低

## Algorithm [413. Arithmetic Slices](https://leetcode.com/problems/arithmetic-slices/description/)

题目给定数`num`,要求依次输出从`0`到`num`的所有数二进制表示中的`1`的个数。

### 解决思路

使用动态规划的算法来计算,其子问题关系如下：

 v(n) = v(n/2) + ((n%2==0)? 0:1)

某个数n的`1`个数由除以`2`剩余的整数,以及除以`2`的余数来决定。

从大到小计算除各个数的`1`个数,记录下来供后续使用,避免重复计算.

### 原始实现

从大到小计算,并记录过程中的值：

```C++
int count_bit(std::vector<int>& results, int v)
{
    if (results.at(v) != -1) return results.at(v);
    int r = count_bit(results, v / 2) + (v % 2 == 0 ? 0 : 1);
    results[v] = r;
    return r;
}
vector<int> countBits(int num) {
    std::vector<int> results(num + 1, -1);
    results[0] = 0;
    for (int i = num; i > 0; i--) {
        count_bit(results, i);
    }
    return results;
}
```

### 更为简洁清晰的实现

换个角度从小到大计算,能够使得实现简单许多:

```C++
vector<int> countBits(int num) {
    std::vector<int> results(num + 1, 0);
    for (int i = 0; i <= num; i++) {
        results[i] = results[i >> 1] + (i & 1);
    }
    return results;
}
```

## Reivew [“auto to stick” and Changing Your Style](https://www.fluentcpp.com/2018/09/28/auto-stick-changing-style/)

何时用`auto`?这是一个问题。

### `auto`是否被滥用

文中举了个例子：

```C++
Widget myWidget{42}; //1
auto myWidget = Widget{42};//2
```

作者在做代码审查时发现同事对代码做了类似上述的修改,内心几乎是`What the fuck!`了,然后询问同事这是否是对`auto`的滥用.然而同事的回复震惊了作者,当然也震惊了我...

这种写法来源于[`Herb Sutter`的一个演讲](https://youtu.be/xnqTKD8uD64).而这种`auto`的用法被称为`auto to stick`.

### `auto`的两种应用场景

`auto`有两种用法:

- `auto to track`
- `auto to stick`

大家应该都很熟悉`auto to track`,几乎谈起`auto`都会举类似如下的例子：

```C++
td::vector<Widget> widgets = {1, 2, 3, 4, 5};
auto first = begin(widgets);
```

使用`auto`可以避免写出`std::vector<Widget>::iterator`这么一长串代码,用来自动推导出`first`的类型,这时的`auto`是用来"追踪"的.

而`auto to stick`则相对少见:

```C++
auto name = std::string{"Arthur"};
```

按照作者的解释,这时的`auto`是用来提交类型(*commit to a type*)的。

### 为什么`auto to stick`不是滥用

有以下原因或者说解释：

- 一致性

C++的语法是"从左到右",`auto to stick`也是这样的模式

- 初始化问题

`auto to stick`能够保证变量被初始化,示例如下:

```C++
int i; //通过编译但是存在隐患
int i = 0;//要保证正确初始化

auto i; //无法通过编译
auto i = int;//无法通过编译
auto i = int{};//初始化为0
```

- 非narrow转换

使用`auto`能够避免隐式转换:

```C++
float x = 42.0;//从双精度浮点数转换为单精度

auto x = 42.0;//x为double类型
auto x = 42.0f;//x为所要的float类型
```

- 几乎对性能无影响

可能有人会说`auto to stick`这种写法会有一次构造+一次拷贝赋值,从而有性能问题;而这个问题也不必过多担心,因为编译器会进行优化,譬如RVO。

### 总结

还是要多学习啊,全是知识点。

## Technique [如何整合3D内容到Qt Graphics View](Mixin2D&3DinQt.md)

学习了在Qt中如何以3D模型为底,在其上实现2D场景的方法。

## Share 自我学习太累太苦效率太低

最近在处理2D/3D模型整合显示的问题,之前都是用公司开发的平台处理3D显示问题,而我结合自身经验开始做整合显示时遇到了重重困难,折腾了两天才找到问题原因,又浪费了一天半夜找寻解决方案,精疲力尽。

这让我回想起刚开始学编程时被错误支配的恐惧,那时拿了本C#的书边抄代码边学习,而书中无法详细记载操作的每个步骤,又没有源代码等可以直接运行,经常会被一些编译错误等折腾得无法继续下去,甚至不得不中止。

从开始到现在编程这门技艺全是自学出来的,有时候回想起来完全不知道自己时如何学会的,过程中走过多少弯路,有过多少坎儿.也养成了一些习惯,什么东西都觉得自己能学会,不愿意去沟通,借力解决,不喜欢跟人请教自己不清楚的技术.个中辛苦只有自己知道.

自我学习实在是太累太苦效率太低,多希望有人带路,有人教,有人探讨;给我带来的思考就是,培训班是有必要的,要去好的公司,相信专业人士。