# 在 C++中检测类型是否定义

最近刷 Twitter 看到一系列文章,翻阅了一下,感觉很是神奇,总觉得有用武之地,记录一下:

- [Detecting in C++ whether a type is defined, part 3: SFINAE and incomplete types](https://devblogs.microsoft.com/oldnewthing/20190710-00/?p=102678)
- [Detecting in C++ whether a type is defined, part 4: Predeclaring things you want to probe](https://devblogs.microsoft.com/oldnewthing/20190711-00/?p=102682)
- [Detecting in C++ whether a type is defined, part 5: Augmenting the basic pattern](https://devblogs.microsoft.com/oldnewthing/20190712-00/?p=102690)

## 基本原理及初步实现

熟悉 C++的都知道 C++中头文件的作用是什么,自然还有前置类声明,即[Incomplete type](https://en.cppreference.com/w/cpp/language/type#incomplete_type).可以有方法来检测是否类型是否是`Incomplete type`.

另外可以立即声明某个类型,譬如`struct my_type`.

假设我们定义变量模板`is_type_complete_v`:

```C++
template<typename, typename = void>
constexpr bool is_type_complete_v = false;
```

然后使用 SFINAE 技术,加上`sizeof`检测`Incomplete type`,实现如下:

```C++
template<typename T>
constexpr bool is_type_complete_v
    <T, std::void_t<decltype(sizeof(T))>> = true;
```

这样检测类型是否定义的雏形就可以以如下方式使用:

```C++
struct s; // incomplete type
bool val1 = is_type_complete_v<struct s>; // false
struct s {}; // now it's complete
bool val2 = is_type_complete_v<struct s>; // true
```

我们定义某个方法在存在某个类型定义时工作,否则什么事情都不做,可以定义如下辅助函数:

```C++
template<typename T, typename TLambda>
void call_if_defined(TLambda&& lambda)
{
  if constexpr (is_complete_type_v<T>) {
    lambda(static_cast<T*>(nullptr));
  }
}
```

使用方式如下:

```C++
void foo(Source source)
{
  call_if_defined<struct special>([&](auto* p)
  {
    using special = std::decay_t<decltype(*p)>;
    special::static_method();
    auto s = source.try_get<special>();
    if (s) s->something();
  });
}
```

但是这种方法有些问题,譬如:

```C++
// awesome.h
namespace awesome
{
  // might or might not contain
  struct special { ... };
}

// your code
namespace app
{
  using namespace awesome;

  void foo()
  {
    call_if_defined<struct special>([&](auto* p)
    {
       ...
    });
  }
}
```

如果`special`未定义,那么就会引入未完成类型`app::special`,我们是无法引入带有命名空间的类型的.

## 改进版

这项检测技术完整实现如下:

```C++
template<typename, typename = void>
constexpr bool is_type_complete_v = false;

template<typename T>
constexpr bool is_type_complete_v
    <T, std::void_t<decltype(sizeof(T))>> = true;

template<typename... T, typename TLambda>
void call_if_defined(TLambda&& lambda)
{
  if constexpr ((... && is_complete_type_v<T>)) {
    lambda(static_cast<T*>(nullptr)...);
  }
}
```

之前说过无法引入带有命名空间的类型,而且使用类型限制为`struct`,并且每次使用都要带上`struct`.

这些问题可以通过预定义类型到预期的命名空间来解决:

```C++
// awesome.h
namespace awesome
{
  // might or might not contain
  struct special { ... };
}

// your code

namespace awesome
{
  // ensure declarations for types we
  // conditionalize on.
  struct special;
}
```

我们通过模板`lambda`来声明可调用对象,处理调用问题:

```C++
void foo(Source const& source)
{
  call_if_defined<special, magic>(
    [&](auto* p1, auto* p2)//模板lambda
    {
      using special = std::decay_t<decltype(*p1)>;//获取传递来的对象
      using magic = std::decay_t<decltype(*p2)>;

      auto s = source.try_get<special>();
      if (s) magic::add_magic(s);
    });
}
```

## 扩展应用

之前的可以支持编译期,这里展示支持运行期的用法:

```C++
template<typename T, typename TLambda>
void call_if_supported(IInspectable const& source,
                       TLambda&& lambda)
{
  if constexpr (is_complete_type_v<T>) {
    auto t = source.try_as<T>();//如果能够获取到某类型
    if (t) lambda(std::move(t));//作为参数传递个lambda
  }
}
```

示例如下:

```C++
namespace winrt::Windows::UI::Xaml
{
  struct IUIElement5;
}

using namespace winrt::Windows::UI::Xaml;

//旧实现
void BringIntoViewIfPossible(UIElement const& e)
{
  call_if_defined<IUIElement5>([&](auto* p) {
    using IUIElement5 = std::decay_t<decltype(*p)>;

    auto el5 = e.try_as<IUIElement5>();//any or ?
    if (el5) {
      el5.StartBringIntoView();
    }
  });
}

//新实现
void BringIntoViewIfPossible(UIElement const& e)
{
  call_if_supported<IUIElement5>(e, [&](auto&& el5) {
    el5.StartBringIntoView();
  });
}
```

如果有完整的`IUIElement5`定义,就将`e`转换为`IUIElement5`,然后调用其方法`StartBringIntoView`.

还有另一种用法:

```C++
struct empty {};
template<typename T, typename = void>
struct type_if_defined
{
    using type = empty;
};

template<typename T>
struct type_if_defined<T, std::void_t<decltype(sizeof(T))>>
{
    using type = T;
};

template<typename T>
using type_if_defined = typename type_or_empty<T>::type;
```

这个和`call_if_defined`一起使用,来在两个调用之间传递类型对象:

```C++
type_if_defined<special> s;

call_if_defined<special>([&](auto *p)
{
  using special = std::decay_t<decltype(*p)>;

  s = special::get_current();
});

do_something();

call_if_defined<special>([&](auto *p)
{
  using special = std::decay_t<decltype(*p)>;

  special::set_current(s);
});
```

## 总结

作者在文中解释这种技术可以用在支持不同版本的`API`上.实际上可以看到应该还是有其它用途等待发掘.
