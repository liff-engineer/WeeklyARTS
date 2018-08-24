# 如何获取类型的字符串表示

在一些使用模板、`decltype`、`auto`等的场景下,需要获取类型的字符串表示来进行调试或者使用,那么如何获取类型的字符串表示呢?

## 使用宏

在`preC++11`时代,宏应该是最直接的思路,譬如[C++ Get name of type in template](https://stackoverflow.com/questions/1055452/c-get-name-of-type-in-template)

```C++
template<typename T>
struct TypeParseTraits;

#define REGISTER_PARSE_TYPE(X) template <> struct TypeParseTraits<X> \
    { static const char* name; } ; const char* TypeParseTraits<X>::name = #X

REGISTER_PARSE_TYPE(int);
REGISTER_PARSE_TYPE(double);
REGISTER_PARSE_TYPE(FooClass);
```

## RTTI

在有`RTTI`的情况下可以使用`typeid(v).name()`来获取`v`的类型,譬如[typeid operator](https://en.cppreference.com/w/cpp/language/typeid)

```C++
int myint = 50;
std::string mystr = "string";
double *mydoubleptr = nullptr;

std::cout << "myint has type: " << typeid(myint).name() << '\n'
            << "mystr has type: " << typeid(mystr).name() << '\n'
            << "mydoubleptr has type: " << typeid(mydoubleptr).name() << '\n';
```

## 函数签名的妙用

我们知道编译期会提供一些预设的宏用来获取编译期信息,譬如assert的实现：

```C++
#define assert(cond)    \
    if(!(cond)) \
        printf("%s:%d",__FILE__,__LINE__)
```

编译期也提供了获取函数签名字符串形式的宏,举个简单的例子：

```C++
template<typename T>
void f(){
    puts(__FUNCSIG__);
}

#define EXPLORE(expr) \
    printf("decltype(" #expr ") is ... ");\
    f<decltype(expr)>();

void example(){
    auto x = 5;
    auto&& y = 5;
    decltype(auto) z = 5;

    EXPLORE(x);
}
```

在Visual Studio上运行结果为:

```CMD
decltype(x) is... void __cdecl f<int>(void)
```

那么,是否可以通过截取函数签名的片段来获取对应类型?

## 比较优雅的实现

通过对`__FUNCSIG__`输出信息的分析,可以提取局部的字符串来得到参数类型：

```C++
template<typename>
std::string type_name(){
    std::string result=__FUNCSIG__;
    return std::string(result.data()+106,result.size()-106-7);
}
```

`type_name`函数签名的函数签名形式为`class std::basic_string<char,struct std::char_traits<char>,class std::allocator<char> > __cdecl type_name<TYPE_NAME>(void)`,在`TYPE_NAME`之前有106个字符,之后有7个字符。

通过这种形式,就可以获得相应类型的字符串表示。

## 编译期实现(C++17)

编译期实现需要解决如何存储结果的问题,可以参考`std::string_view`自行实现编译期的`string_view`,如果有C++17的编译器,实现起来相对简单:

```C++
template<typename T>
constexpr std::string_view type_name() {
    std::string_view r = __FUNCSIG__;
    return std::string_view(r.data() + 84, r.size() - 84 - 7);
}
```

## 注意事项

以上代码运行环境均为Visual Studio,如果要在其它编译器上运行,则需要将`__FUNCSIG__`替换成`__PRETTY_FUNCTION__`,并且萃取类型信息的区域会发生变化,具体可以实际尝试或者参考[Exploring C++ types with puts(__PRETTY_FUNCTION__)](https://quuxplusone.github.io/blog/2018/08/22/puts-pretty-function/)中的演示。

## 参考资料

- [Is it possible to print a variable's type in standard C++?](https://stackoverflow.com/questions/81870/is-it-possible-to-print-a-variables-type-in-standard-c)
- [Getting the type of a template argument as string – without RTTI](https://blog.molecular-matters.com/2015/12/11/getting-the-type-of-a-template-argument-as-string-without-rtti/)
- [Exploring C++ types with puts(__PRETTY_FUNCTION__)](https://quuxplusone.github.io/blog/2018/08/22/puts-pretty-function/)
