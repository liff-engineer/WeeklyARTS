# 代理与修饰模式

假设你有一个数据库,存储了多个表,每个表的记录都对应了某个`Entity`的信息,其`ID`是个整数,那么你会如何实现对应的结构呢?

你可以采用 C 的方式,各种函数外加参数来完成你的`API`.也可以将不同的`Entity`类型封装成不同的类.

第一种方法自然不是我们想要看到的.而将不同的`Entity`封装成类也存在问题.譬如我们有两个表`person`和`address`.

那么封装成类形式可能是这样的:

```C++
class person
{
public:
    int iD() const;
    std::string name() const;
};

class address
{
public:
    int iD() const;
    std::string zipcode() const;
};
```

而`person`和`address`之间是有关联的,那么怎么建立关联? 你可能会想到指针:

```C++
class person
{
    std::vector<address*>  address_list() const;
};

class address
{
public:
    person* owner();
};
```

那么问题来了,`address*`和`person*`的生命周期该如何处理?

又或者如果我只是想知道它有多少个地址,结果却导致了我必须从数据库加载所有的地址对象,抑或为`person`专门提供个接口?

我认为可以提供这样的方案来缓解这些问题:

1. 将`ID`和数据库表等特定信息封装成类型,作为`proxy class`-访问代理
2. 使用`decorator`来提供具体信息.

实现类似如下:

```C++
#include <iostream>
#include <string>
#include <tuple>

template<typename Tag, typename... Ts>
class holder
{
public:
    template<typename... Args>
    explicit holder(long long iD, Args&&... args)
        :m_iD(iD), m_tuple(std::forward<Args>(args)...) {};

    long long iD() const { return m_iD; }

    template<typename T, typename... Args>
    T  as(Args&& ... args)
    {
        return T{ args...,m_iD,m_tuple };
    }
protected:
    long long m_iD{ -1 };
    std::tuple<Ts ...> m_tuple;
};

struct string_tag {};

class name :public holder<string_tag, std::string>
{
public:
    template<typename... Args>
    explicit name(Args&&... args)
        :holder<string_tag, std::string>{ std::forward<Args>(args)... }
    {};

    std::string get_name() const
    {
        return std::get<0>(m_tuple);
    }
private:
};


int main(int argc, char** argv)
{
    holder<string_tag, std::string> v{-1,"string_tag"};

    auto my = v.as<name>();
    std::cout << "name:" << my.get_name();
    auto old = my.as<holder<string_tag, std::string>>();
    return 0;
}
```

这时回到最初的问题:

```C++
class table;
struct person_tag{};
struct address_tag{};
using person_t = holder<person_tag,table*>;
using address_t = holder<address_tag,table*>;

class person:pubic person_t
{
    std::vector<address_t> address_list()const;
};

class address:public address_t
{
    person_t  owner();
};
```

这时,所有接口返回的其它关联数据都是整数加上`table*`,不使用`person*`和`address*`.而如果获取具体的信息,则可以如下操作：

```C++

auto list = person.address_list();
for(const auto& item:list)
{
    auto addr = item.as<address>();
    //addr为address类型,可以访问各种信息
}
```
