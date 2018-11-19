# 模板元编程应用之结构体与数据库记录直接映射

通常数据库会被拆分成表、字段、记录等,而在应用程序中,经常会将其转换为结构体,来表达业务模型.

而使用结构体对数据库执行读写操作的代码是重复性非常高的,能否使用模板元编程技术自动完成?

## 问题分析

数据库的接口一般可以从记录读取某个字段值,几个字段拼出结构体,如果要以模板形式实现结构体到记录的映射,首先要调整数据库的接口,使得能够以类型+字段名形式读写记录的某字段值,例如：

```C++
class record
{
public:
    template<typename T>
    T   get(std::string const& field);
    template<typename T>
    void set(std::string const& field,T&& v);
};
```

这样就可以遍历结构体成员,根据其类型和数据库记录字段名将结构体成员填充完成,写入的时候也一样.

那么对于结构体的要求呢?需要从结构体获取成员的类型及数据库字段名:

```C++
struct member
{
    using type = void;
    const char* db_field_name = "";
};

template<typename T>
struct adapter
{
    std::vector<member> members;
};
```

也就是说,如果想要实现结构体到数据库的直接映射,则需要完成以下内容:

- 调整数据库接口,使其支持编译期展开
- 提供结构体适配数据,使得编译期能够正确处理成员变量与记录字段
- 提供编译期遍历操作

## 调整数据库接口

由于数据库API的字段类型是有限的,最简单的方式就是使用`tag dispatch`,如果是`C++17`则可以利用`if constexpr`来实现,这里提供一个演示用的数据库表API包裹:

```C++
//数据库表
struct table
{
    using type = std::variant<std::monostate, int,double, std::string>;

    std::vector<std::string> fields;//字段名
    std::vector<std::vector<std::variant<std::monostate, int, double, std::string>>> records;

    //新增记录
    std::size_t add_record() noexcept {
        records.push_back(std::vector<type>(fields.size(), type{}));
        return records.size() - 1;
    }

    //提供写入接口
    template<typename T>
    void    set(std::size_t idx, std::string field, T&& v) noexcept {
        if (records.size() <= idx) return;

        auto it = std::find(std::begin(fields), std::end(fields), field);
        if (it == fields.end()) return;

        auto location = static_cast<std::size_t>(std::distance(fields.begin(), it));
        auto& record = records.at(idx).at(location);

        records[idx][location] = v;
    }

    //提供访问接口
    template<typename T>
    std::optional<std::decay_t<T>> get(std::size_t idx, std::string field) const noexcept
    {
        //不存在的
        if (records.size() <= idx) return {};

        auto it = std::find(std::begin(fields), std::end(fields), field);
        if (it == fields.end()) return {};

        auto location = static_cast<std::size_t>(std::distance(fields.begin(), it));
        const auto& record = records.at(idx).at(location);

        using R = std::decay_t<T>;
        //access int
        if constexpr (std::is_same_v<R, int>) {
            if (auto r = std::get_if<int>(&record)) {
                return *r;
            }
        }
        //access double
        if constexpr (std::is_same_v<R, double>) {
            if (auto r = std::get_if<double>(&record)) {
                return *r;
            }
        }
        //access std::string
        if constexpr (std::is_same_v<R, std::string>) {
            if (auto r = std::get_if<std::string>(&record)) {
                return *r;
            }
        }
        return {};
    }
};
```

上述数据库表实现提供了统一的模板接口,使得后续遍历成员获取值变得可能.

## 提供结构体适配数据

如果要能够完成对数据库记录的直接映射,直接的结构体信息是不足的,由于C++不支持反射,很多信息需要自行提供,而且要求能够进行编译期操作.

对于字段名,可以采用`std::array`,因为其编译期可用,能够编译期展开,而对于结构体成员变量则相对比较复杂.

### 结构体成员变量的读写

譬如如下结构体:

```C++
struct man
{
    std::string name;
    int  age{ 18 };
    double weight;
    double height;
};
```

对结构体的读写操作都是通过`man.name`等进行操作的,譬如:

```C++
man myself;
myself.age = 32;

std::cout<<myself.age<<'\n';
```

那么如何实现通用的结构体读写操作呢?这就涉及到成员指针的概念,譬如如下模板:

```C++
template<typename T,typename R>
using member_pointer = R T::*;
```

其中`member_pointer`代表了类型`T`的成员指针,而成员指针的指向类型为`R`,譬如`man`的身高和体重都是类型`member_pointer<man,double>`,那么如何使用呢?

```C++
member_pointer<man,double> fn_weight = &man::weight;
member_pointer<man,double> fn_height = &man::height;

man myself;

myself.*fn_weight = 77;
myself.*fn_height = 177;

std::cout<<myself.*fn_weight<<'\n';
std::cout<<myself.*fn_height<<'\n';
```

也就是说,如果要对结构体进行操作,可以记录结构体成员指针,然后通过`.*`来操作,但是访问某个成员是需要知道其类型的,否则从记录读取接口无法运行,这里可以使用`decltype`来实现:

```C++
template<typename T,typename R>
R member_result_extract(member_pointer<T, R>);

template<auto member_pointer>
using member_t = decltype(member_result_extract(member_pointer));
```

因而,可以使用如下结构保存成员原始信息:

```C++
template<typename T,typename R>
using member_pointer = R T::*;

template<typename T,typename R>
R member_result_extract(member_pointer<T, R>);

template<auto member_address>
struct member
{
    using type = decltype(member_result_extract(member_address));
    static constexpr decltype(member_address) fn = member_address;
};  
```

这样就可以完成通用的结构体成员读写操作了:

```C++
template<typename T,auto member_address>
struct adapter:member<member_address>
{
    static void set(T&& t,type&& v){
        t.*fn = v;
    }

    static type get(T&& t){
        return t.*fn;
    }
};

```

那么如何存储结构体所有成员的读写信息呢?使用`std::tuple`:

```C++

template<typename T>
struct adapter_meta
{
    using type = std::tuple<>;
    static constexpr std::size_t n = std::tuple_size<type>::value;
};
```

针对特定的结构体,使用模板偏特化:

```C++
template<>
struct adapter_meta<man>
{
    using type = std::tuple<member<&man::name>,member<&man::age>, member<&man::weight>,member<&man::height>>;
    static constexpr std::size_t n = std::tuple_size<type>::value;
};
```

为了简化书写,提供如下模板别名:

```C++
template<typename T, auto... Args>
using adapter_members = std::tuple<member<Args>...>;
```

之前的书写形式变为:

```C++
template<>
struct  adapter_meta<man>
{
    using type = adapter_members<man, &man::name, &man::age, &man::weight,&man::height>;
    static constexpr std::size_t n = std::tuple_size<type>::value;
};
```

这时已经将结构体读写保存成为`tuple`来支持遍历操作,还需要字段名配置,不过这里会新增个`Tag`来限制其配置是给什么来使用的,毕竟不一定只有数据库需要去映射,增加一个`Tag`可以支持其特定场景的扩展,譬如说从`json`文件中读取结构体:

```C++
struct  adapter_meta_tag {};
template<typename Tag,typename T>
struct  adapter_meta
{
    using type = std::tuple<>;
    static constexpr std::size_t n = std::tuple_size<type>::value;
    static constexpr std::array<const char*, n> fields = {};
};

template<typename Tag, typename T>
using adapter_meta_t =typename adapter_meta<Tag,T>::type;

template<typename T, auto... Args>
using adapter_members = std::tuple<detail::member<Args>...>;

//示例
template<typename Tag>
struct  adapter_meta<Tag, man>
{
    using type = adapter_members<man, &man::name, &man::age, &man::weight,&man::height>;
    static constexpr std::size_t n = std::tuple_size<type>::value;
    static constexpr std::array<const char*, n> fields = { "name","age","weight","height" };
};
```

## 如何编译期遍历`std::tuple`

由于需要根据结构体成员类型和对应的字段名从数据库读取值,这时就需要将之前存储的所有`member`进行遍历,也就是说要在编译期展开`members`,实现如下形式的操作:

```C++
man result;

for(auto [fn,field]:adapters<man>()){
    using type = member<fn>::type;//获取成员类型
    result.*fn = record.get<type>(field);//从数据库读取成员
}

//或者如下形式
auto f = [&](Fn fn,Field_Name field){};//有结构体的成员地址和字段名,循环调用f进行操作

for(auto member:members){
    f(member.fn,field);
}
```

注意这些都是编译期展开,首先实现一个`tuple`类型的编译期展开:

```C++
template<std::size_t... Is>
auto make_index_dispatcher(std::index_sequence<Is...>) {
    return [](auto&& f) { (f(std::integral_constant<std::size_t, Is>{}), ...); };
}

//构造编译期的0~N展开函数序列
template<std::size_t N>
auto make_index_dispatcher() {
    return make_index_dispatcher(std::make_index_sequence<N>{});
}

template<typename T,typename F>
void for_each(T&& t, F&& f) {
    constexpr auto n = std::tuple_size<T>::value;
    auto dispatcher = detail::make_index_dispatcher<n>();
    dispatcher([&f, &t](auto idx) {
        f(std::get<idx>(std::forward<T>(t)));
    });
}
```

如何使用?参加以下示例:

```C++
std::tuple result = {10,3.14,"what?"};

for_each(result,[](auto v){
    std::cout<<v<<'\n';
});
```

## 整合实现

对结构体适配进行一些调整,提供获取结构体第`i`项成员和成员字段名,从而支持针对结构体各个成员进行`for_each`操作:

```C++

//获取类型元数据
template<typename T, typename Tag, std::size_t I>
using member_meta =typename std::tuple_element_t<I, adapter_meta_t<Tag,T>>;

//获取结构体成员地址(可进行读写操作)
template<typename Tag, std::size_t I, typename T>
decltype(auto) element(T& v) noexcept {
    static constexpr auto fn = member_meta<std::decay_t<T>,Tag, I>::fn;
    return v.*fn;
}

//获取结构体成员个数
template<typename Tag,typename T>
constexpr auto element_number() noexcept {
    return adapter_meta<Tag,std::decay_t<T>>::n;
}

//针对结构体每个字段进行循环操作
template<typename Tag = adapter_meta_tag, typename T, typename F>
void for_each_field(T&& t, F&& f) {
    constexpr auto n = detail::element_number<Tag, std::decay_t<T>>();
    constexpr auto fields = adapter_meta<Tag, std::decay_t<T>>::fields;
    auto dispatcher = detail::make_index_dispatcher<n>();
    dispatcher([&f, &t, &fields](auto idx) {
        f(detail::element<Tag, idx>(std::forward<T>(t)), std::get<idx>(fields));
    });
}

```

完成了上述操作后,接下来实现测试的`print`,来实验下`for_each_field`能否正确工作:

```C++
template<typename Tag = adapter_meta_tag,typename T>
void print(T&& v) {
    for_each_field<Tag>(v, [](auto v, auto field) {
        std::cout << field << ":" << v << '\n';
    });
}

struct foo
{
    int key{0};
    double value{0.0};
    std::string addon;
};
template<typename Tag>
struct  adapter_meta<Tag,foo>
{
    using type = adapter_members<foo,&foo::key,&foo::value,&foo::addon>;
    static constexpr std::size_t n = std::tuple_size<type>::value;
    static constexpr std::array<const char*, n> fields = {"key","value","addon"};
};


foo r1{1,100.0,""};
r1.addon = "liff.engineer@gmail.com";
print<>(r1);
```

其中`v`为结构体成员值,`field`为字段名.

那么接下来实现以下数据库的写入,新增记录,然后遍历结构体各个成员,根据结构体值及字段名写入:

```C++
template<typename T>
void db_write(table& t, T&& v)
{
    auto idx = t.add_record();
    for_each_field<>(v, [&](auto v, auto field) {
        t.set(idx, field, v);
    });
}
```

而数据库读取要注意,需要正确获取结构体成员值类型:

```C++
template<typename T>
std::optional<std::decay_t<T>> db_read(table& t, std::size_t idx)
{
    using R = std::decay_t<T>;
    R result{};
    for_each_field<>(result, [&](auto& v,auto field) {
        //获取正确的成员类型
        using DT = std::remove_reference_t<std::remove_cv_t<decltype(v)>>;
        if (auto r = t.get<DT>(idx, field)) {
            v = r.value();
        }
    });
    return result;
}
```

## 完整实现

```C++
#pragma once

#include <tuple>
#include <array>

struct  adapter_meta_tag {};
template<typename Tag,typename T>
struct  adapter_meta
{
    using type = std::tuple<>;
    static constexpr std::size_t n = std::tuple_size<type>::value;
    static constexpr std::array<const char*, n> fields = {};
};

template<typename Tag, typename T>
using adapter_meta_t =typename adapter_meta<Tag,T>::type;

namespace detail
{
    template<typename T,typename R>
    using member_pointer = R T::*;

    template<typename T,typename R>
    R member_result_extract(member_pointer<T, R>);

    template<auto member_address>
    struct member
    {
        using type = decltype(member_result_extract(member_address));
        static constexpr decltype(member_address) fn = member_address;
    };

    template<typename T, typename Tag, std::size_t I>
    using member_meta =typename std::tuple_element_t<I, adapter_meta_t<Tag,T>>;

    template<typename Tag, std::size_t I, typename T>
    decltype(auto) element(T& v) noexcept {
        static constexpr auto fn = member_meta<std::decay_t<T>,Tag, I>::fn;
        return v.*fn;
    }

    template<typename Tag,typename T>
    constexpr auto element_number() noexcept {
        return adapter_meta<Tag,std::decay_t<T>>::n;
    }

    template<std::size_t... Is>
    auto make_index_dispatcher(std::index_sequence<Is...>) {
        return [](auto&& f) { (f(std::integral_constant<std::size_t, Is>{}), ...); };
    }

    template<std::size_t N>
    auto make_index_dispatcher() {
        return make_index_dispatcher(std::make_index_sequence<N>{});
    }
}

template<typename T, auto... Args>
using adapter_members = std::tuple<detail::member<Args>...>;


template<typename Tag = adapter_meta_tag, typename T, typename F>
void for_each_field(T&& t, F&& f) {
    constexpr auto n = detail::element_number<Tag, std::decay_t<T>>();
    constexpr auto fields = adapter_meta<Tag, std::decay_t<T>>::fields;
    auto dispatcher = detail::make_index_dispatcher<n>();
    dispatcher([&f, &t, &fields](auto idx) {
        f(detail::element<Tag, idx>(std::forward<T>(t)), std::get<idx>(fields));
    });
}

struct foo
{
    int key{0};
    double value{0.0};
    std::string addon;
};

template<typename Tag>
struct  adapter_meta<Tag,foo>
{
    using type = adapter_members<foo,&foo::key,&foo::value,&foo::addon>;
    static constexpr std::size_t n = std::tuple_size<type>::value;
    static constexpr std::array<const char*, n> fields = {"key","value","addon"};
};

struct man
{
    std::string name;
    int  age{ 18 };
    double weight;
    double height;
};

template<typename Tag>
struct  adapter_meta<Tag, man>
{
    using type = adapter_members<man, &man::name, &man::age, &man::weight,&man::height>;
    static constexpr std::size_t n = std::tuple_size<type>::value;
    static constexpr std::array<const char*, n> fields = { "name","age","weight","height" };
};

#include <iostream>
#include <string>
#include <variant>
#include <vector>
#include <map>
#include <optional>

template<typename Tag = adapter_meta_tag,typename T>
void print(T&& v) {
    for_each_field<Tag>(v, [](auto v, auto field) {
        std::cout << field << ":" << v << '\n';
    });
}

//数据库表
struct table
{
    using type = std::variant<std::monostate, int,double, std::string>;

    std::vector<std::string> fields;//字段名
    std::vector<std::vector<std::variant<std::monostate, int, double, std::string>>> records;

    //新增记录
    std::size_t add_record() noexcept {
        records.push_back(std::vector<type>(fields.size(), type{}));
        return records.size() - 1;
    }

    //提供写入接口
    template<typename T>
    void    set(std::size_t idx, std::string field, T&& v) noexcept {
        if (records.size() <= idx) return;

        auto it = std::find(std::begin(fields), std::end(fields), field);
        if (it == fields.end()) return;

        auto location = static_cast<std::size_t>(std::distance(fields.begin(), it));
        auto& record = records.at(idx).at(location);
      
        records[idx][location] = v;
    }

    //提供访问接口
    template<typename T>
    std::optional<std::decay_t<T>> get(std::size_t idx, std::string field) const noexcept
    {
        //不存在的
        if (records.size() <= idx) return {};
        
        auto it = std::find(std::begin(fields), std::end(fields), field);
        if (it == fields.end()) return {};

        auto location = static_cast<std::size_t>(std::distance(fields.begin(), it));
        const auto& record = records.at(idx).at(location);

        using R = std::decay_t<T>;
        //access int
        if constexpr (std::is_same_v<R, int>) {
            if (auto r = std::get_if<int>(&record)) {
                return *r;
            }
        }
        //access double
        if constexpr (std::is_same_v<R, double>) {
            if (auto r = std::get_if<double>(&record)) {
                return *r;
            }
        }
        //access std::string
        if constexpr (std::is_same_v<R, std::string>) {
            if (auto r = std::get_if<std::string>(&record)) {
                return *r;
            }
        }
        return {};
    }
};


template<typename T>
std::optional<std::decay_t<T>> db_read(table& t, std::size_t idx)
{
    using R = std::decay_t<T>;
    R result{};
    //bool failed = false;
    for_each_field<>(result, [&](auto& v,auto field) {
        using DT = std::remove_reference_t<std::remove_cv_t<decltype(v)>>;
        if (auto r = t.get<DT>(idx, field)) {
            v = r.value();
        }
    });
    //if (failed) return {};
    return result;
}

template<typename T>
void db_write(table& t, T&& v)
{
    auto idx = t.add_record();
    for_each_field<>(v, [&](auto v, auto field) {
        //using DT = std::remove_reference_t<std::remove_cv_t<decltype(v)>>;
        t.set(idx, field, v);
    });
}


void user() {
    //foo r1{1,100.0,""};
    //r1.addon = "liff.engineer@gmail";
    ////print<>(r1);
    {
        table foos;
        foos.fields = { "key","value","addon" };

        //db_write(foos, r1);
        db_write(foos, foo{ 1024,3.1415926,"liff.engineer@gmail.com" });
        db_write(foos, foo{ 1025,3.1415927,"liff-b@glodon.com" });
        std::vector<foo> results;
        for (auto i = 0ul; i < foos.records.size(); i++) {
            if (auto r = db_read<foo>(foos, i)) {
                results.push_back(r.value());
            }
        }

        for (auto& v : results) {
            print<>(v);
        }

    }
    
    {
        table foos;
        foos.fields = { "name","age","weight","height" };

        db_write(foos, man{ "liff",32,78.0,177.0 });
        db_write(foos, man{ "konglz",33,75.0,180.0 });


        std::vector<man> results;
        for (auto i = 0ul; i < foos.records.size(); i++) {
            if (auto r = db_read<man>(foos, i)) {
                results.push_back(r.value());
            }
        }

        for (auto& v : results) {
            print<>(v);
        }
    }
}
```

## 总结

以上展示了一种结构体直接与数据库记录映射的实现,通过这种方式,只需要定义结构体,填充适配信息,即可完成数据库读写实现,减少了大量无必要的代码.

从中可以体会到元编程能够给开发者带来的价值,为编码实现提供更多可想象的空间.