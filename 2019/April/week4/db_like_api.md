# C++中数据按类型访问接口的一种实现

在 C++中,尤其是数据库接口,我们通常会以如下方式设计数据访问接口:

```cpp

class Record
{
public:
    std::string getString(const char* field);
    int  getInteger(const char* field);
    double getDouble(const char* field);
    bool   getBool(const char* field);
    std::vector<char> getStream(const char* field);

    void  setString(const char* field,const string& v);
    void  setInteger(const char* field,int v);
    void  setDouble(const char* field,double v);
    void  setBool(const char* field,bool v);
    void  setStream(const char* field,const std::vector<char>& v);
};
```

然后如果我们定义了一种新的结构类型,在数据库中存储方式是以`std::string`或者`std::vector<char>`方式存储,那么我们就要设计辅助类来进行使用,或者使用面向对象的`Data Access Object`方式:

```cpp

struct object
{
    //方式1
    std::string to_string() const;
    bool  from_string(const std::string& v);
};

//方式2
class object_db_helper
{
    object get(Record& record,const char* field);
    void set(Record& record,const char* field,object const& obj);
};
```

让我们来看一看怎么来以另一种方式设计这样的 API.

## 统一接口

将`set`和`get`的接口全部统一,使得使用者以如下方式使用:

```c++

auto int_v =record.get<int>(field);
auto double_v = record.get<double>(field);
record.set(field,string_v);
record.set(field,vector_v);
```

如何实现? 这里使用到`tag dispatch`技术:

```c++

template<typename T>
struct type_tag{};

class Record
{
public:
    template<typename T>
    decltype(auto) get(const char* field)
    {
        return get(field,type_tag<T>{});
    }

    template<typename T>
    decltype(auto) set(const char* field,T&& v)
    {
        return set(field,std::forward<T>(v));
    }
private:

    std::string get(const char* field, type_tag<std::string>)
    {
        return getString(field);
    }

    void  set(const char* field,std::string const& v)
    {
        return setString(field,v);
    }
    //int,double,std::vector<char>,bool等实现
};
```

## 支持扩展类型

通过之前的操作,我们已经可以将接口设计成泛型,通过一些技巧就可以实现一样的接口支持扩展类型,譬如之前的示例:

```c++

auto object_v = record.get<object>(field);
```

不需要借助于辅助类或者多余代码:

```c++

template<typename T>
struct record_adapter
{
    using type = void;
    template<typename U>
    static T as(U&&);
}

template<typename T>
using record_adapter_t = typename record_adapter<T>::type;

class Record
{
    template<typename T>
    decltype(auto) get(const char* field)
    {
        if constexpr(std::is_same_v<record_adapter_t<T>,void>){
            return get(field,type_tag<T>{});
        }
        else {
            return record_adapter<T>::as(get(field,type_tag<record_adapter_t<T>>{}));
        }
    }
};
```

这样,只需要为扩展类型定义`record_adapter`的偏特化即可:

```c++
struct record_adapter<object>
{
    using type = std::string;
    static object as(std::string const&)
    {
        //从字符串构造object
    }
};

auto obj = record.get<object>(field);//实际上先调用了get<std::string>,然后将其转换成object
```

## 更好的易用性

如果我们只是从`record`获取某个值,使用`auto`和`get<value_type>`即可.但是如果我们要用获取到的值填充某个已有变量,那么`get`的`value_type`就显得没有必要了.是否可以省掉这个步骤?

这里我们使用 C++的[user-defined conversion](https://en.cppreference.com/w/cpp/language/cast_operator)来完成这个操作:

```C++

class Record
{
public:
    struct record_field
    {
        record* owner;
        const char* field;
        template<typename T>
        operator T() const{
            return owner->get<std::decay_t<T>>(field);
        }
    };

    record_field get(const char* field){
        return record_field{const_cast<Record*>(this),field};
    }
};
```

使用`get`接口时返回的是包装类`record_field`,包装类定义了类型转换操作`operator T()`.通过上述操作,我们就可以以如下方式使用了:

```c++

double dv = 0.0;
bool   bv = false;


dv = record.get(field);
bv = record.get(field);
```

## 总结

通过以上操作,我们可以实现基于类型的 API,方便开发者使用及扩展,同时尽可能避免显式的`API`及类型依赖.灵感来源于[JSON for Modern C++](https://github.com/nlohmann/json)这个接口非常好用的`json`库,感兴趣的可以去了解一下实现.
