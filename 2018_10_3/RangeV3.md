# [Range-v3 入门](https://slides.com/filipsajdak-1/range-v3-how-to-start)

很早就听说了[Range-v3](https://ericniebler.github.io/range-v3/),但是由于主要工作环境在Visual Studio上,并且文档支持实在是比较尴尬,一直无法入门,直到最近看到了[Range-v3 how to start and learn it](https://slides.com/filipsajdak-1/range-v3-how-to-start),终于算是拨开云雾见青天了,下面就来跟随作者的讲述来学习学习`Range-v3`.

## 准备工作

由于Visual Studio目前即使是2017版本也不能支持原始的`Range-v3`,因而选择在线编译器来运行过程中的示例,为了能够看到输出效果,这里使用[Wandbox](https://wandbox.org/)

## 快速起步

先简单理解一下`Range-v3`里的概念:View和Action,View可以暂时理解为针对一对迭代器的封装,Action则可以理解为作用于容器或者View上的算法.

那么以下代码可以用来输出容器里的所有内容：

```C++
#include <range/v3/all.hpp>
#include <vector>
#include <iostream>

using namespace ranges;
int main(){
    auto v = std::vector{1,4,7,3,8,5};
    std::cout<<view::all(v)<<std::endl;
}
```

输出为:

```CMD
[1,4,7,3,8,5]
```

然后在其中添加个排序的action,如下:

```C++
auto v = std::vector{1,4,7,3,8,5};
action::sort(v);
std::cout<<view::all(v)<<std::endl;
```

输出如下：

```CMD
[1,3,4,5,7,8]
```

如果要以现有C++操作方式来实现上述功能,则可能是如下形式:

```C++
auto v = std::vector{1,4,7,3,8,5};
std::sort(std::begin(v),std::end(v));

std::cout<<'[';
for(const auto& t:v){
    std::cout<<t<<',';
}
std::cout<<']'<<std::endl;
```

## actions

之前的STL算法经常要输入起始和结束位置,而且组合起来比较艰辛,譬如出了名的[erase-remove](https://en.wikipedia.org/wiki/Erase%E2%80%93remove_idiom),actions则试图解决这些问题,使得操作针对容器的操作更为便利,且支持组合操作。

譬如要完成`vector`中的排序及去重动作,现有C++操作如下:

```C++
auto v = std::vector{1,7,2,4,1,7,4,6,0,1};
std::sort(v.begin(), v.end());
v.erase(std::unique(v.begin(), v.end()), v.end());
```

而使用actions的写法为:

```C++
auto v = std::vector{1,7,2,4,1,7,4,6,0,1};
action::unique(action::sort(v));
```

actions的设计是类似管道操作的,另外一些书写形式如下:

```C++
v |= action::sort | action:unique;
v = std::move(v)|action::sort | action:unique;
v = v|move|action::sort | action:unique;
//或者直接如下操作
auto v=std::vector{1,7,2,4,1,7,4,6,0,1}|action::sort|action::unique;
```

之前操作中间数据需要大量的步骤和代码,使用actions不仅减少了代码量,也更为清晰,譬如读取数据、排序然后插入结果列表：

```C++
auto v = std::vector{123,321};
{//现有C++写法
    auto tmp = get_data();
    std::sort(tmp.begin(),temp.end());
    auto it = std::unique(tmp.begin(),tmp.end());
    std::move(tmp.begin(),it,std::back_inserter(v));
}
{//使用actions
    v|= action::push_back(get_data() | action::sort | action::unique);
}
```

又或者读取数据,排序,去重,求和后插入结果列表：

```C++
{
    auto tmp = get_data();
    std::sort(tmp.begin(), tmp.end());
    auto it = std::unique(tmp.begin(), tmp.end());
    v.push_back(std::accumulate(tmp.begin(), it, 0));
}
{
    v |=  action::push_back(accumulate(get_data()| action::sort | action::unique, 0));
}
```

可以看到,之前使用STL算法虽然也能表意,但是冗余代码(迭代器)相对繁琐,容易出错;使用actions就能够以最简洁易懂的代码表达/实现功能,也不容易出错。

## views

view最初是要提供更为smart的迭代器,简单理解为从特定视角看容器,譬如获取`vector`中所有的偶数,以现有C++的写法,实现可能如下:

```C++
const auto v = std::vector{1,7,2,4,1,7,4,6,0,1};
std::vector<int> result;
std::copy_if(v.begin(),v.end(),std::back_inserter(tmp),[](auto i){ return i%2 == 0; });
std::cout<<view::all(result)<<std::endl;
```

使用view则可以以如下方式书写:

```C++
auto result = v |view::filter([](auto i){ return i%2 == 0; });
```

如果要取出所有偶数然后求和:

```C++
auto result = accumulate(v |view::filter([](auto i){ return i%2 == 0; }),0);
```

取出所有偶数、平方然后求和:

```C++
auto result = accumulate(v |view::filter([](auto i){ return i%2 == 0; })
                            |view::transform([](auto i){ return i*i; }),0);
```

或者说将操作声明成view来组合或者复用:

```C++
const auto evens = view::filter([](auto i){ return i%2 == 0; });
const auto squared = view::transform([](auto i){ return i*i; });

auto result = accumulate(v | evens | squared,0);
```

从上述示例可以看到,views的操作是`Lazy`的,可以声明多种view操作,然后进行组合,只有最终执行时才应用。

例如,要计算从1到max范围内2的次方:

```C++
auto pow2(int max){
    std::vector<int> results;
    for(int i = i ; i < max ; i*=2){
        results.push_back(i);
    }
    return results;
}
```

以view的方式:

```C++
auto pow2(int max){
    return view::generate([i=1]()mutable{
        const int r = i;
        i*=2;
        return r;
    }) | view::take_while([max](auto i){ return i < max; });
}
```

生成2的次方然后一直`take`直到条件不满足。

`Range-v3`的view非常廉价,可以随意创建,而不用担心存在效率问题,如果采用现有的方式,则过程数据会频繁创建,无法与view相比。

同时`string`也可以作为view的目标进行操作,例如:

```C++
const auto csv = "11,12,13\n21,22,23";
auto res = view::c_str(csv)
         | view::split('\n')  
         | view::transform([](auto&& line) {  return line | view::split(',')});
```

从字符串创建view,按照回车拆分,然后拆出的每行再根据逗号拆分,最终结果如下:

```CMD
[[[1,1],[1,2],[1,3]],[[2,1],[2,2],[2,3]]]
```

## 总结

从以上一些简单的示例就可以感受到`Range-v3`的魅力所在,更具表达能力,不易出错,性能也不弱,这或许就是为什么其作者被资质来全职开发它的原因;希望C++20能够通过`range`提案,早日让开发者装备上这种"武器"。