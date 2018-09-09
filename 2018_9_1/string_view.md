# [std::string_view: The Duct Tape of String Types](https://blogs.msdn.microsoft.com/vcblog/2018/08/21/stdstring_view-the-duct-tape-of-string-types/)

## 从内容角度看这篇文章

### 概述

std::string_view并不是更好的`const char*`或者`const std::string&`,而是作为通用的`glue`-胶水:用来描述读取字符串数据时提供最小通用接口的类型。

### 能够解决的问题

我们知道如果一个接口接收`const char*`或者`const std::string&`,那么使用另外的类型传递参数时必须调整成所需参数,而`std::string_view`就是要解决这个问题,接口接收`std::string_view`,那么`const char*`和`const std::string&`可无需调整就能使用.

示例如下:

```C++
void f(std::wstring_view); //接口

std::wstring& s; f(s);//std::wstring可直接使用

wchar_t* ns = ""; f(ns); //null结尾的const char* 可直接使用

wchar_t* cs,size_t len;  f({cs,len});//字符串数组+长度可用

winrt::hstring hs; f(hs);  //WinRT字符串类型可用
```

可以看到,无需重载、模板即可一个接口接收所有可能的字符串类型。

### 应用

1. 作为通用的字符串参数

2. 对字符串操作时作为便捷存储

如果比较在意性能,解析字符串时会将其以字符串数组对待,需要谨慎处理;而std::string_view既有字符串数组的性能,也有std::string的便利。

### 陷阱

1. std::string_view不持有数据或者扩展数据的生命周期

2. 类型推导和隐式转换

这个涉及到如何想要提供模板来接受`std::basic_string_view`,从而可以接收`std::string_view`和`std::wstring_view`时,需要阻止类型推导和隐式转换,否则编译无法通过.譬如:

```C++
template<typename TChar>
auto f(std::basic_string_view<TChar> sv);

void example(){
    std::wstring string;
    f(string);//无法通过编译
    f(std::wstring_view{string});//可以
}
```

### 调试支持

std::string_view不持有数据,如果使用不恰当可能会出现问题,MSVC为我们提供了调试支持来检测可能出现错误的情况。

## 从书写方式上看这篇文章

从文章整体结构来看:

- 首先是总体介绍,说明std::string_view是什么
- 然后是“一句话”总结,以文字配示例讲解std::string_view使用方法
- 之后对std::string_view进行详细讲解
- 提供两个std::string_view应用示例
- 提醒读者MSVC对std::string_view的"特殊"支持
- 告知读者使用std::string_view的注意事项
- 总结收尾

从中学到的:

- 技术文章要有整体结构
- 不要一上来就陷入细节,给出"大局",让读者可以迅速抓住重点
- 根据内容类型提供各个方面的讲解
    - 使用方法+应用示例
    - 特殊支持
    - 存在的问题

个人认为这篇文章有个问题就是MSVC对std::string_view的调试支持应当放到std::string_view存在的问题之后讲解,因为只有说明问题,才需要给解决方案。