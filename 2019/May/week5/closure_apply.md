# C++闭包及 TEPS 的一种应用

TEPS 的概念和实现参见[C++中如何模拟实现多态](https://github.com/liff-engineer/WeeklyARTS/blob/master/2019/May/week2/polymorphic_ducks.md).

在 C++11 引入的 lambda 使得我们可以实现一些闭包.

这里我将展示一种混合应用的示例来看这两者是如何以更好的方式解决现实问题的.

## 场景

我们可能面临从多种数据源读取数据的场景,譬如从数据库、文件、网络等读取几种特定的数据.而在使用时我们希望使用统一的接口.例如,我们要从数据源根据`key/field`获取对应的值,接口类似如下:

```cpp
class block_reader
{
public:
    virtual ~block_reader()=default;

    bool get_boolean(const wchar_t* field) const = 0;
    int get_integer(const wchar_t* field) const = 0;
    double get_double(const wchar_t* field) const = 0;
};
```

数据的类型可能会扩展,数据源也会扩展.那么面向对象/动态多态的方式如何解决这个问题?

## 动态多态-可扩展数据类型

由于数据类型可以扩展,我们首先要解决这个问题,按照面向对象的思维模式,则会首先为数据抽象成统一的基类:

```C++
class value_object
{
public:
    virtual ~value_object()=default;
};

class boolean_object:public value_object{};
class int_object:public value_object{};
class double_object:public value_object{};
```

这样接口就变成了:

```C++
class block_reader
{
public:
    virtual ~block_reader()=default;

    std::unique_ptr<value_object> get(const wchar_t* field) const = 0;
};
```

而使用时,我们需要如下操作:

```C++
block_reader *reader;
auto obj = reader->get(field);

//获取整数
if(int_object* obj= dynamic_cast<int_object*>(obj.get())){
    int v = obj.value();
}
//获取浮点数
if(double_object* obj= dynamic_cast<double_object*>(obj.get())){
    double v = obj.value();
}
```

## 动态多态-可扩展数据源

如果需要扩展数据源,则需要继承自`block_reader`:

```C++
class db_block_reader:public block_reader
{};
class file_block_reader:public block_reader
{};
class network_block_reader:public block_reader
{};
```

使用时依然要利用到指针:

```C++
block_reader* reader = new db_block_reader{};
block_reader* reader = new file_block_reader{};
block_reader* reader = new network_block_reader{};
```

如果是现存的数据源,需要实现对应的适配器.

## 动态多态的问题

1. 无法以很自然的方式获取对应的数据类型
2. 耦合于接口`block_reader`
3. 大量的指针使用,再加上虚函数,性能和健壮性都面临挑战.

具体可以看一看[Sean Parent 的系列演讲](https://sean-parent.stlab.cc/papers-and-presentations/),譬如[Inheritance Is The Base Class of Evil](https://sean-parent.stlab.cc/papers-and-presentations/#inheritance-is-the-base-class-of-evil).

## 如何解决数据类型扩展的问题

那么,以 C++"专家"的视角,这个问题该如何解决呢? 自然不是 OO 那一套,这就利用到了 lambda 的闭源特性.

针对某个数据源,数据的读取实现是不相同的,数据源的生命周期也需要控制.譬如如果是数据库的方式:

1. 从存储分页中加载数据块
2. 从数据库读取数据
3. 释放数据块

可能的接口及用法如下:

```C++
class dbrecord
{
public:
    bool get_boolean(const wchar_t* field) const;
    int get_integer(const wchar_t* field) const;
    double get_double(const wchar_t* field) const;
};

class dbtable{};

dbtable table;
auto record = table.load(addr);
auto v = record->get_integer(field);
delete record;
```

而如果是内存数据,则可能就没有生命周期困扰:

```C++
struct record
{
    std::map<int,std::any> values;
    std::map<std::wstring,int> fieldindexs;
};
```

我们的核心目标是获取某种数据,在这种场景下,我们可以用闭包包裹数据源,提供出数据访问函数,例如:

```C++
struct data_source
{
    std::function<bool(const wchar_t*)> bool_read_fn;
    std::function<int(const wchar_t*)> int_read_fn;
    std::function<double(const wchar_t*)> double_read_fn;
};
```

这样只需要使用 lambda 表达式包裹数据源及对应的数据访问接口,后续可以直接使用`fn`读取到数据:

```C++
struct data_source
{
    data_source()
    {
        bool_read_fn=[=](const wchar_t* field)->bool{
            return this->get_boolean(field);
        };
        int_read_fn=[=](const wchar_t* field)->int{
            return this->get_integer(field);
        };
        double_read_fn=[=](const wchar_t* field)->double{
            return this->get_double(field);
        };
    }

    std::function<bool(const wchar_t*)> bool_read_fn;
    std::function<int(const wchar_t*)> int_read_fn;
    std::function<double(const wchar_t*)> double_read_fn;
};
```

使用方式如下:

```C++
data_source ds;

auto bv = ds.bool_read_fn(field);
auto iv = ds.int_read_fn(field);
auto dv = ds.double_read_fn(field);
```

现在,借用`tuple`以及一些模板,即可完成我们的数据类型扩展模型:

```c++

//泛型版本的读取函数
template<typename T>
struct reader {
    using type = std::function<T(const wchar_t*)>;
};

template<typename T>
using reader_t = typename reader<T>::type;

//可变参数版本的数据类型读取扩展
template<typename... Ts>
struct readers
{
    using type = std::tuple<reader_t<Ts>...>;
};
template<typename... Ts>
using readers_t = typename readers<Ts...>::type;
```

如果我们需要数据源支持`bool`、`int`、`double`类型,则只要它包含以下内容即可:

```C++
struct data_source
{

    readers_t<bool,int,double> readers;
};
```

借用一些模板技巧,我们可以从数据源提供统一接口来访问数据源的内容:

```C++
struct data_source
{
    template<typename T>
    T value(const wchar_t* field) const {
        return std::get<reader_t<T>>(readers)(field);
    }

    readers_t<bool,int,double> readers;
};
```

然后我们就可以以如下方式使用数据源了:

```C++
data_source ds;

auto bv = ds.value<bool>(field);
auto iv = ds.value<int>(field);
auto dv = ds.value<double>(field);
```

如果要扩展数据源的数据类型,调整`readers`的类型列表即可.

假设数据源还提供了`std::vector<char>`,但是只有特定场景会使用,我们是没有必要将其引入到`data_source`的,可以基于`data_source`扩展:

```C++
struct extend_data_source: public data_source
{


    readers_t<bool,int,double,std::vector<char>> readers;
};
```

需要注意的是,基类初始化的是自身的`readers`,构造时需要处理下.

## 如何解决数据源扩展

前面说过,最终我们只需要数据源提供对应的`readers`即可,但是生命周期还是`data_source`控制的,我们还需要将数据源以某种形式存储,并且不会影响到外部接口.

这就利用到开头提到的模拟多态,我们定义数据源概念如下:

```C++
template<typename... Ts>
class block_reader
{
    struct concept_t {
        virtual ~concept_t() = default;
        virtual const detail::readers_t<Ts...>& readers() const = 0;
    };
};
```

数据源概念`concept_t`提供虚接口用来访问数据源的`readers`.

然后实现数据源模型,这里假设数据源必然包含`readers`:

```C++
template<typename T>
struct model_t final :public concept_t {
    T obj;

    model_t() = default;
    model_t(const T& v) :obj{ v } {};
    model_t(T&& v) :obj{ std::move(v) } {};
    const detail::readers_t<Ts...>& readers() const override
    {
        return obj.readers;//直接约束成员变量及名称
    }
};
```

现在,我们将这些组装起来,并提供出数据访问接口:

```C++
template<typename... Ts>
class block_reader
{
    //...
    std::unique_ptr<concept_t> impl;
public:
    block_reader() = default;
    block_reader(const block_reader&) = delete;
    block_reader& operator=(const block_reader&) = delete;
    block_reader(block_reader&&) = default;
    block_reader& operator=(block_reader&&) = default;

    template<typename T>
    block_reader(T&& impl)
        :impl(new model_t<std::decay_t<T>>(std::forward<T>(impl))) {};

    template<typename T>
    block_reader& operator=(T&& impl)
    {
        impl.reset(new model_t<std::decay_t<T>>(std::forward<T>(impl)));
        return *this;
    }

    template<typename T>
    T value(const wchar_t* field) const {
        return std::get<detail::reader_t<T>>(impl->readers())(field);
    }

    explicit operator bool() const {
        return impl != nullptr;
    }
};
```

现在,任何能够提供如下成员变量的类型均可以作为数据源供`block_reader<Ts...>`使用:

```C++
struct data_source_type
{
    //实现
    readers_t<Ts...> readers;
};
```

## 示例

提供如下两种形式的数据源:

```C++
struct variant
{
    int iv{1024};
    double dv{3.1415926};
    bool bv{true};

    detail::readers_t<int, double, bool> readers;
    variant()
    {
        std::get<detail::reader_t<int>>(readers) = [=](const wchar_t*)->int {
            return this->iv;
        };
        std::get<detail::reader_t<double>>(readers) = [=](const wchar_t*)->double {
            return this->dv;
        };
        std::get<detail::reader_t<bool>>(readers) = [=](const wchar_t*)->bool {
            return this->bv;
        };
    }
};

struct variant_literal
{
    detail::readers_t<int, double, bool> readers;
    variant_literal()
    {
        std::get<detail::reader_t<int>>(readers) = [=](const wchar_t*)->int {
            return 1023;
        };
        std::get<detail::reader_t<double>>(readers) = [=](const wchar_t*)->double {
            return 1.414;
        };
        std::get<detail::reader_t<bool>>(readers) = [=](const wchar_t*)->bool {
            return false;
        };
    }
};
```

测试程序如下:

```C++
void report(const block_reader<int, double, bool>& reader)
{
    std::cout << "int value:" << reader.value<int>(L"") << "\n";
    std::cout << "double value:" << reader.value<double>(L"") << "\n";
    std::cout << "bool value:" << reader.value<bool>(L"") << "\n";
}

void example()
{
    report(variant{});
    report(variant_literal{});
}
```

## 总结

利用闭包和 TEPS 两种技术,可以充分发挥 C++类型及模板的能力,在现实场景下,可以避开传统 OOP 方式存在的各种问题,提供更好的实现.

## 源码

```C++
#include <functional>
#include <tuple>
#include <memory>

namespace detail
{
    template<typename T>
    struct reader {
        using type = std::function<T(const wchar_t*)>;
    };

    template<typename T>
    using reader_t = typename reader<T>::type;

    //在Visual Studio 2017中可以这样操作
    //template<typename... Ts>
    //using readers_t = std::tuple<reader_t<Ts>...>;

    template<typename... Ts>
    struct readers
    {
        using type = std::tuple<reader_t<Ts>...>;
    };
    template<typename... Ts>
    using readers_t = typename readers<Ts...>::type;
}

template<typename... Ts>
class block_reader
{
    struct concept_t {
        virtual ~concept_t() = default;
        virtual const detail::readers_t<Ts...>& readers() const = 0;
    };

    template<typename T>
    struct model_t final :public concept_t {
        T obj;

        model_t() = default;
        model_t(const T& v) :obj{ v } {};
        model_t(T&& v) :obj{ std::move(v) } {};
        const detail::readers_t<Ts...>& readers() const override
        {
            return obj.readers;//直接约束成员变量及名称
        }
    };

    std::unique_ptr<concept_t> impl;
public:
    block_reader() = default;
    block_reader(const block_reader&) = delete;
    block_reader& operator=(const block_reader&) = delete;
    block_reader(block_reader&&) = default;
    block_reader& operator=(block_reader&&) = default;

    template<typename T>
    block_reader(T&& impl)
        :impl(new model_t<std::decay_t<T>>(std::forward<T>(impl))) {};

    template<typename T>
    block_reader& operator=(T&& impl)
    {
        impl.reset(new model_t<std::decay_t<T>>(std::forward<T>(impl)));
        return *this;
    }

    template<typename T>
    T value(const wchar_t* field) const {
        return std::get<detail::reader_t<T>>(impl->readers())(field);
    }

    explicit operator bool() const {
        return impl != nullptr;
    }
};
```
