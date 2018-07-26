# [std::string_view](https://en.cppreference.com/w/cpp/header/string_view)

在C语言中,对于字符串的支持是以`\0`结束的字符数组,C++中延续了这一做法,但是在标准库中提供了`std::string`来简化字符串操作,从而也带来了性能问题,而`C++17`中的`std::string_view`既能够提供`std::string`的便捷操作,也不会带来性能方面的损耗。

## 现状

无论是出于历史原因,还是性能方面的考量,在`C++`中存在非常多表示字符串的方式：

- `const char *`
- `const wchar_t*`
- `std::string`
- `ATL CString`
- `MFC CString`
- `Platform::String`
- `wxString`
- `WTF::CString`
- `QString`
- `folly::fbstring`
- ......

涉及到字符串处理也存在一些惯用法和议题：

- SSO:小字符串优化
- Cow:写时复制
- 线程安全
- char traits
- 自定义`allocator`

作为使用者,自然是希望有统一的标准来解决C++中字符串的处理,而`std::string`并不是答案的全部,因为它存在的最严重问题就是：内存性能;`std::string`会引发内存申请动作,在使用过程中非常容易制造出大量的`std::string`实例,很多情况下并不不要,并且频繁且少量的内存申请会引发内存碎片问题,内存申请也相对成本较高。

因而在目前的编码实践中,一般会采用`const char*`或者`const std::string&`来避免不必要的`std::string`实例,而如果是衔接底层或者其它字符串类型的API,又会导致接口增加:

- `void foo(const char*)`
- `void foo(const std::string&)`
- `void bar(const char*,const char*)`
- `void bar(const std::string&,const std::string&)`
- `void bar(const char*,const std::string&)`
- `void bar(const std::string&,const char*)`
- ......

## `std::string_view`

`std::string_view`自身并不持有字符串,它只是作为字符串的“引用”存在,在实现时通常也采用记录字符串的位置和长度的策略,自身可以作为一个普通的数值类型使用,而不需要写成`const std::string_view&`,其构造和复制等操作对比`std::string`都相对廉价,不会引起内存申请。

### 在API中的使用

有了`std::string_view`之后,涉及到字符串的接口,只要对字符串自身不做修改动作,均可以替换成`std::string_view`：

- `void foo(std::string_view)`
- `void bar(std::string_view,std::string_view)`

### 性能方面的问题-内存

在具体应用中,即使恰当使用了`const std::string&`,也会在一些细微的角落出现问题,可以阅读[C++17 string_view](https://skebanga.github.io/string-view/)中的示例：

```C++
#include <iostream>

void* operator new(std::size_t n)
{
    std::cout << "[allocating " << n << " bytes]\n";
    return malloc(n);
}

bool compare(const std::string& s1, const std::string& s2)
{
    if (s1 == s2)
        return true;
    std::cout << '\"' << s1 << "\" does not match \"" << s2 << "\"\n";
    return false;
}

int main()
{
    std::string str = "this is my input string";

    compare(str, "this is the first test string");
    compare(str, "this is the second test string");
    compare(str, "this is the third test string");

    return 0;
}
```

输出结果是:

```Cmd
[allocating 24 bytes]
[allocating 30 bytes]
"this is my input string" does not match "this is the first test string"
[allocating 31 bytes]
"this is my input string" does not match "this is the second test string"
[allocating 30 bytes]
"this is my input string" does not match "this is the third test string"
```

而替换成`std::string_view`的版本:

```C++
bool compare(std::experimental::string_view s1, std::experimental::string_view s2)
{
    if (s1 == s2)
        return true;
    std::cout << '\"' << s1 << "\" does not match \"" << s2 << "\"\n";
    return false;
}
```

输出结果是:

```Cmd
[allocating 24 bytes]
"this is my input string" does not match "this is the first test string"
"this is my input string" does not match "this is the second test string"
"this is my input string" does not match "this is the third test string"
```

### 性能方面的问题-效率

或许会有人提出`const char*`也挺好,但是以`const char*`来表示字符串会有一个性能方面的问题,如果要获取字符串长度(实际上很多情况需要这个长度),`const char*`必须逐个字节查询`\0`来确认字符串长度,而使用`std::string_view`则没有这种困扰,相对来讲存在的问题是：根据`const char*`构造`std::string_view`而不提供字符串长度,则会在构造时执行一个获取字符串长度的操作。

## `std::string_view`并不是“灵丹妙药”

由于`std::string_view`并不持有字符串,在使用过程中必须保证字符串生命周期,否则会出现问题,这个是要特别注意的;

生命周期的问题也导致了`AAA`-`Almost Always Auto`在对应场景中不能使用;

而在一些容器使用中,`std::string_view`并不能应用到其API中,譬如`std::map<std::string,object_t>`,在根据`key`查询值时,不能用`std::string_view`.

## 参考资料

- [string_view: a non-owning reference to a string](http://www.open-std.org/jtc1/sc22/wg21/docs/papers/2014/n3921.html)
- [Enough string_view to hang ourselves](http://cppconf.ru/talks/day-1/track-a/5.pdf)
- [std::string_view is a borrow type](https://quuxplusone.github.io/blog/2018/03/27/string-view-is-a-borrow-type/)
- [C++17 - Avoid Copying with std::string_view](http://www.modernescpp.com/index.php/c-17-avoid-copying-with-std-string-view)
