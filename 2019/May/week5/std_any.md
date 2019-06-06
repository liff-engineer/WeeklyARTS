# [关于 std::any 你所需要知道的](https://www.bfilipek.com/2018/06/any.html)

使用`std::optional`你可以表示一些类型或者什么都没有.使用`std::variant`你可以将一些类型包含到一个实体.C++17 也给了我们另外一种包裹类型:`std::any`可以以类型安全的方式持有任何内容.

## 基本知识

在目前为止的 C++标准中,如果你要在某个变量中保存可变类型,你并没有很多选择.当然,你可以使用`void*`,但这很不安全.

`void*`可以与类型识别信息包裹在一个类中:

```C++
class MyAny
{
    void* _value;
    TypeInfo _typeInfo;
};
```

可以看到,我们已经有类型的基本形式,但是还需要一些代码来保证`MyAny`是类型安全的.这就是为什么最好使用标准库而不是自己来实现.

而这就是 C++17 中`std::any`的基本形式.它给了你机会来在对象中存储任意值.当你尝试着访问其中没包含的类型是就会报出错误(或者抛出异常).

以下是使用示例:

```C++
std::any a(12);

// set any value:
a = std::string("Hello!");
a = 16;
// reading a value:

// we can read it as int
std::cout << std::any_cast<int>(a) << '\n';

// but not as string:
try
{
    std::cout << std::any_cast<std::string>(a) << '\n';
}
catch(const std::bad_any_cast& e)
{
    std::cout << e.what() << '\n';
}

// reset and check if it contains any value:
a.reset();
if (!a.has_value())
{
    std::cout << "a is empty!" << "\n";
}

// you can use it in a container:
std::map<std::string, std::any> m;
m["integer"] = 10;
m["string"] = std::string("Hello World");
m["float"] = 1.0f;

for (auto &[key, val] : m)
{
    if (val.type() == typeid(int))
        std::cout << "int: " << std::any_cast<int>(val) << "\n";
    else if (val.type() == typeid(std::string))
        std::cout << "string: " << std::any_cast<std::string>(val) << "\n";
    else if (val.type() == typeid(float))
        std::cout << "float: " << std::any_cast<float>(val) << "\n";
}
```

输出结果如下:

```cmd
16
bad any_cast
a is empty!
float: 1
int: 10
string: Hello World
```

从上述示例中可以看到几点信息:

- `std::any`并不是模板类,这和`std::optional`,`std::variant`不一样
- 默认情况下不包含值,这个可以通过`.has_value()`检查
- 你可以通过`.reset()`来重置它
- 它适用于`decayed`类型,在赋值、初始化、放置时,类型使用`std::decay`转换.
- 当使用不同类型的值进行赋值操作时,目前存储的类型值会被销毁
- 你可以使用`std::any_cast<T>`来访问值,如果当前的值类型不是`T`,则会抛出`bad_any_cast`.
- 你可以通过`.type()`获取当前值类型的`std::type_info`信息.

上述示例看起来令人印象深刻 - C++中真正的可变类型!. 如果你喜欢 JavaScript,你甚至可以使你的变量都是`std::any`类型,然后像 JavaScript 一样使用 C++ :).

但是,是否有一些应用场景?

### 何时使用

我认为`void*`是一种非常不安全的模式,只有一些有限的使用场景,`std::any`添加了类型安全特性,这就是为什么它有一些真实的应用场景.

一些可能应用:

- 在库中使用 - 当库类型必须持有或者传递任意值,并且不知道其可能的可变类型
- 解析文件 - 如果你无法指定到底支持哪些类型
- 消息传递
- 与脚本语言绑定
- 实现脚本语言的解释器
- 用户界面 - 控件可能持有任何值
- 编辑器中的实体

我相信很多场景下我们可以限制支持的类型,这就是为什么`std::variant`是更好的选择.当然,当你要实现库,但是最终应用不明确时 - 你是无法知道可能存储到对象中的值类型的.

上述示例展示了一些基本知识,后续章节,你会发现`std::any`的更多细节.

## 创建`std::any`

创建`std::any`有以下几种方式:

- 默认初始化 - 这时对象是空的
- 使用值或者对象直接初始化
- 使用`std::in_place_type`就地初始化
- 通过`std::make_any`

以下是示例:

```C++
// 默认初始化
std::any a;
assert(!a.has_value());

// 使用对象初始化
std::any a2(10); // int
std::any a3(MyType(10, 11));

// 就地初始化
std::any a4(std::in_place_type<MyType>, 10, 11);
std::any a5{std::in_place_type<std::string>, "Hello World"};

// make_any
std::any a6 = std::make_any<std::string>("Hello World");
```

## 改变值

如果你希望改变`std::any`中目前存储的值,你有两个选择:使用`emplace`或者赋值:

```C++
std::any a;

a = MyType(10, 11);
a = std::string("Hello");

a.emplace<float>(100.5f);
a.emplace<std::vector<int>>({10, 11, 12, 13});
a.emplace<MyType>(10, 11);
```

### 对象生命周期

对于`std::any`来说,达成安全的关键是不泄露任何资源.为了达到这一点,在赋新值时`std::any`会销毁目前存储的值.

```C++
std::any var = std::make_any<MyType>();
var = 100.0f;
std::cout << std::any_cast<float>(var) << "\n";
```

输出信息如下:

```cmd
MyType::MyType
MyType::~MyType
100
```

对象使用`MyType`初始化,但是在为其设置新的值(100.0f)时,调用了`MyType`的析构.

## 访问存储的值

为了读取当前存储在`std::any`中的值,你几乎只有一个选项:`std::any_cast`.该函数会返回请求类型的值,如果存储在其中的值是这种类型的话.

但是,这个函数模板非常强大,因为它有很多种使用方法:

- 返回值的拷贝,失败时抛出`std::bad_any_cast`
- 返回引用(同时是可写的),失败时抛出`std::bad_any_cast`
- 返回值的指针,失败时返回`nullptr`

示例如下:

```C++
struct MyType
{
    int a, b;

    MyType(int x, int y) : a(x), b(y) { }

    void Print() { std::cout << a << ", " << b << "\n"; }
};

int main()
{
    std::any var = std::make_any<MyType>(10, 10);
    try
    {
        std::any_cast<MyType&>(var).Print();
        std::any_cast<MyType&>(var).a = 11; // read/write
        std::any_cast<MyType&>(var).Print();
        std::any_cast<int>(var); // throw!
    }
    catch(const std::bad_any_cast& e)
    {
        std::cout << e.what() << '\n';
    }

    int* p = std::any_cast<int>(&var);
    std::cout << (p ? "contains int... \n" : "doesn't contain an int...\n");

    MyType* pt = std::any_cast<MyType>(&var);
    if (pt)
    {
        pt->a = 12;
        std::any_cast<MyType&>(var).Print();
    }
}
```

可以看到,你有两种方式来处理错误:通过异常或者返回指针.返回指针的函数重载被标示为`noexcept`.

## 性能与内存考量

`std::any`看起来非常强大,你可能会使用它来持有不同类型的变量... 但是你可能会问,获得这样灵活性的代价是什么?

主要的问题是:额外的动态内存申请

`std::variant`和`std::optional`因为知道对象中要存储的值类型,所以它们不需要额外的内存申请.`std::any`无法知晓,这就是为什么它可能会使用一些堆内存.

这个是总是发生,还是说有些场景下会? 规则是什么?如果只是简单的`int`类型呢?

让我们看以看标准中是如何说的:

> Implementations should avoid the use of dynamically allocated memory for a small contained value. Example: where the object constructed is holding only an int. Such small-object optimization shall only be applied to types `T` for which `is_nothrow_move_constructible_v<T>` is true.

总的来说,标准鼓励使用小对象优化来实现.这也需要付出代价:它会使得类型更大,来适应缓存.

让我们看一看以下三种编译器的`std::any`大小:

| 编译器                  | sizeof(any) |
| ----------------------- | ----------- |
| GCC 8.1                 | 16          |
| Clang 7.0.0             | 32          |
| MSVC 2017 15.7.0 32-bit | 40          |
| MSVC 2017 15.7.0 64-bit | 64          |

如你所见,`std::any`不是个简单的类型,它带来了大量的`overhead`.它并不小,由于 SBO,它需要 16 或者 32 字节,甚至更大.

## 从`boost::any`迁移

Boost 的 Any 于 2001 年引入.其作者 Kevlin Henney 同样也是`std::any`提案的作者.所以两个存在着很强的关系,STL 版本基本上是基于其前身的.

以下是主要变化:

| 特性                 | Boost.Any(1.67.0) | std::any |
| -------------------- | ----------------- | -------- |
| 额外内存申请         | 是                | 是       |
| SBO                  | 否                | 是       |
| emplace              | 否                | 是       |
| in_place_type_t 构造 | 否                | 是       |

主要差别在于`boost.any`没有使用 SBO,所以是比较小的类型,但是带来的问题是即使是对于哪些非常简单的类型,例如`int`,也会申请内存.

## 示例应用

`std::any`的核心在于灵活性.因此,在下面的示例中,你可以看到一些想法(或者具体实现),采用保持可变类型可以使应用程序更为简单.

### 解析文件

在`std::variant`的[示例](https://www.bfilipek.com/2018/06/variant.html#examples-of-stdvariant)中你可以看到使如何解析配置文件并保存结果的.然而,如果你写一个非常通用的解决方案 - 可能作为某个库的一部分,那么你可能不知道所有可能的类型.

从性能角度来说,存储`std::any`作为值的属性,其表现足够好,并且能够给你灵活性.

### 消息传递

在 WIndows 的 API 中,消息传递系统,使用带有两个可选参数的消息 ID 来存储消息值.基于该机制,你可以实现 WndProc 来处理传递给窗体/控件的消息:

```C++
LRESULT CALLBACK WindowProc(
  _In_ HWND   hwnd,
  _In_ UINT   uMsg,
  _In_ WPARAM wParam,
  _In_ LPARAM lParam
);
```

这里的技巧是存储在`wParam`和`lParam`中的值是存在多种形式的.有些时候你只需要使用几个字节的`wParam`...

如果我们将这个系统使用`std::any`,这样可以通过消息传递任意值给处理方法?

```C++
class Message
{
public:
    enum class Type
    {
        Init,
        Closing,
        ShowWindow,
        DrawWindow
    };

public:
    explicit Message(Type type, std::any param) :
        mType(type),
        mParam(param)
    {   }
    explicit Message(Type type) :
        mType(type)
    {   }

    Type mType;
    std::any mParam;
};

class Window
{
public:
    virtual void HandleMessage(const Message& msg) = 0;
};
```

例如你可以传递消息给窗体:

```C++
Message m(Message::Type::ShowWindow, std::make_pair(10, 11));
yourWindow.HandleMessage(m);
```

这时窗体能够以如下方式响应消息:

```C++
switch (msg.mType) {
// ...
case Message::Type::ShowWindow:
    {
    auto pos = std::any_cast<std::pair<int, int>>(msg.mParam);
    std::cout << "ShowWidow: "
              << pos.first << ", "
              << pos.second << "\n";
    break;
    }
}
```

### 属性

在向 C++标准引入 any 的原始提案,[N1939](http://www.open-std.org/jtc1/sc22/wg21/docs/papers/2006/n1939.html)展示了属性类的示例:

```C++
struct property
{
    property();
    property(const std::string &, const std::any &);

    std::string name;
    std::any value;
};

typedef std::vector<property> properties;
```

`properties`对象看起来非常强大,它可以持有很多不同类型.我首先能想到的使用场景是通用 UI 管理器,或者游戏编辑器.

## 跨越边界传递

前段时间在 reddit 的 cpp 频道上有个讨论:[为什么 std::any 被添加到 C++17](https://www.reddit.com/r/cpp/comments/7l3i19/why_was_stdany_added_to_c17/).里面的一个评论很好低总结了合适应该使用这个类型. 评论是这样说的:

> The general gist is that `std::any` allows passing ownership of arbitrary values across boundaries that don’t know about those types.

我之前提到的所有都与这个想法比较接近:

- 在 UI 库中:你不知道客户会使用什么类型
- 消息传递:同样的想法,你希望为客户提供灵活性
- 解析文件:为了支持自定义类型,真正可变的类型非常有用
