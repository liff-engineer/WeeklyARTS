# [std::any: How, when, and why](https://blogs.msdn.microsoft.com/vcblog/2018/10/04/stdany-how-when-and-why/)

Visual C++ Team发布了一系列博客来介绍C++相关内容,之前读过对于C++17中`std::string_view`的介绍,今天再来看一看对于`std::any`的介绍。

## 需求:存储任意类型的数据

在一些场景下需要存储任意类型的数据,那么在之前会如何实现?

### 使用`void*`

使用C语言的话会使用`void*`来存储任意类型的数据,譬如:

```C++
struct day {
  // ...things...
  void* user_data;
};

struct month {
  std::vector<day> days;
  void* user_data;
};
```

但是这种方案存在一些问题:

- 可以转换成其他任意类型

由于`void*`可以转换成任意类型,如果要存储的内容是`std::string`,而使用者将其转换成`double`等其他类型,编译不会出现问题,运行时会出现意想不到的情况.

- 需要手动管理生存周期

使用者申请特定类型数据存储到`void*`之中,到底何时释放,何时能够正常访问,都需要明确说明,增加使用者负担且易出错.

- 库无法对这些数据进行复制

只有使用者知道如何对这些数据进行操作,也就是说库无法对其进行通用的操作,譬如复制等等.

### 智能指针版`void*`

将`void*`替换成智能指针可以解决生存周期的问题:

```C++
struct day {
  // ...things...
  std::shared_ptr<void> user_data;
};

struct month {
  std::vector<day> days;
  std::shared_ptr<void> user_data;
};
```

但是类型安全依然无法得到保障,也无法检测其类型,即使只是存储个整数也需要申请内存。

## `std::any`

`std::any`比`void*`或者`shared_ptr<void>`要智能,可以使用任何`copyable`类型的值来初始化`std::any`:

```C++
std::any a0;
std::any a1 = 42;
std::any a2 = month{"October"};
```

`std::any`知道在自身析构时如何`destroy`内部的值,同时也知道如何复制内部的值,譬如:

```C++
std::any a3 = a0; // Copies the empty any from the previous snippet
std::any a4 = a1; // Copies the "int"-containing any
a4 = a0;          // copy assignment works, and properly destroys the old value
```

而且使用`typeid`比较即可检查内部的值类型,以及值是否存在:

```C++
assert(!a0.has_value());            // a0 is still empty
assert(a1.type() == typeid(int));
assert(a2.type() == typeid(month));
assert(a4.type() == typeid(void));  // type() returns typeid(void) when empty
```

使用`std::any_cast`可以访问其内部的值,即使是获取引用也能够正确处理:

```C++
assert(std::any_cast<int&>(a1) == 42);             // succeeds
std::string str = std::any_cast<std::string&>(a1); // throws bad_any_cast since
                                                   // a1 holds int, not string
assert(std::any_cast<month&>(a2).days.size() == 0);
std::any_cast<month&>(a2).days.push_back(some_day);
```

不过`std::any_cast`在转换类型不支持时会抛出异常,如果你既想要检测值类型又希望获取其值,可以将其转换成指针,譬如:

```C++
if (auto ptr = std::any_cast<int>(&a1)) {
  assert(*ptr == 42); // runs since a1 contains an int, and succeeds
}
if (auto ptr = std::any_cast<std::string>(&a1)) {
  assert(false);      // never runs: any_cast returns nullptr since
                      // a1 doesn't contain a string
}
```

而且MSVC针对其进行了小对象优化,譬如`std::any`中存储了`double`等小对象,则不会从堆上申请内存。

## 面对各种词汇类型如何选择

`std::any`有其明确的使用场景,在以下一些场景中可以选择其他词汇类型：

- 如果能够确定类型,可以使用`std::optional`
- 如果要存储确定签名的函数对象,可以使用`std::function`
- 如果要存储的类型有多种但是编译期就能确定,可以使用`std::variant`

## 存在的问题

- 在`std::any`中存储智能指针,能否正确处理?
- 调试时内部信息无法查看
