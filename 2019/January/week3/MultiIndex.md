# Boost.MultiIndex 的 C++17 实现

## 模型类

```C++
struct Person {
    std::string firstName;
    std::string lastName;
    int age;
    int birthYear() const;
    std::string fullName() const;
    void setAge(int arg);
};
```

## 内存数据库接口

```C++
template<typename Model,typename... Indexes>
struct Table{
    std::map<int,Model> data;
    std::tuple<Indexes...> indices;

    int insert(Model const& model){
        ;//...实现
    }
};
```

是否可以采用如下方式实现`Table::insert`:

```C++
template<typename Model,typename... Indexes>
struct Table{
    int insert(Model const& model){
        int id = generateID();
        data.insert(std::pair(id,model));
        for_each(indices,[&](auto index){
            index.insert(index.extractKey(model),id);
        });
    }
};
```

模板索引类:

```C++
template<typename Key>
struct Index {
    std::map<Key,int> index_data;

    void insert(Key const& key,int id){
        index_data.insert(std::pair(key,id));
    }
};
```

那么就需要实现`extractKey`:

```C++
class ByNameIndex:public Index<std::string>
{
static std::string extractKey(Person const& p){
    return p.name;
}
};
```

如果能实现这样的:

```C++
Index<&Person::firstName> myFirstNameIndex;
```

也就是说:

```C++
template<auto pMember>
struct Index{
    using Key = ???;
    using Model = ???;
    std::map<Key,int> data;
    static Key extractKey(Model const& model){
        return model.*pMember;
    }
};
```

## 定义类型抽取类

```C++
template<typename>
struct TypeExtractor;
```

## 根据成员指针(变量或者函数)抽取类型

```C++
template<typename Key,typename Model>
struct TypeExtractor<Key Model::*> {
    using Model_t = Model;
    using Key_t = std::decay_t<std::invoke_result_t<Key Model::*,Model>>;
};
```

使用别名模板获取具体类型:

```C++
template<auto pMember>
using Key_t = typename TypeExtractor<decltype(pMember)>::Key_t;

template<auto pMember>
using Model_t = typename TypeExtractor<decltype(pMember)>::Model_t;
```

## 如何处理普通函数

上述的`TypeExtractor`处理成员指针,那么普通的函数怎么办?

可以么?自然是可以,但是需要特化

```C++

template<typename Key,typename Model>
struct TypeExtractor<Key (*)(Model const&)> {
    using Model_t = Model;
    using Key_t = Key;
};
```

## 修改`extractKey`实现

```C++
template<auto pMember>
struct Index{
    using Key = Key_t<pMember>;
    using Model = Model_t<pMember>;
    std::map<Key,int> data;
    static Key extractKey(Model const& model){
        return std::invoke(pMember,model);
    }
};
```

## 这时

```C++
int yearsToRetirement(Person const& person){
    return 65-person.age;
}
```

针对成员变量,成员函数,普通函数,`Index`均可正常工作:

```C++
//成员变量
Index<&Person::age>;
//成员函数
Index<&Person::birthYear>;
//单独的函数
Index<yearsToRetirement>;
```

## 多字段的索引实现

如何实现`Index<&Person::age,&Persion::fullname>`:

```C++

struct AgeAndFullNameIndex: public Index<std::tuple<int,std::string>,Person>
{
    static auto extractKey(Person const& p){
        return std::make_tuple(p.age,p.fullName());
    }
}
```

首先是前置声明:

```C++
template<auto...>
struct model_type;
```

然后是无参版:

```C++
template<>
struct model_type<>{
    static constexpr bool value = true;
    using type = void;
};
```

之后是一个参数的:

```C++
template<auto V1>
struct model_type<V1> {
    static constexpr bool value = true;
    using type = Model_t<V1>;
};
```

两个参数:

```C++
template<auto V1,auto V2>
struct model_type<V1,V2> {
    static constexpr bool value = std::is_same_v<Model_t<V1>,Model_t<V2>>;
    using type = Model_t<V1>;
};
```

多参数版本:

```C++
template<auto V1,auto V2,auto V3,auto... Vn>
struct model_type<V1,V2,V3,Vn...> {
    static constexpr bool value = std::is_same_v<Model_t<V1>,Model_t<V2>> && model_type<V2,V3,Vn...>::value;
    using type = Model_t<V1>;
};
```

然后是`Key`的实现:

```C++
template<auto...>
struct key_type;

template<auto V1>
struct key_type<V1> {
    using type = Key_t<V1>;
};

template<auto V1,auto... Vn>
struct key_type<V1,Vn...> {
    using type = std::tuple<Key_t<V1>,Key_t<Vn>...>;
};
```

使用模板别名简化:

```C++
template<auto... Values>
using model_type_t = typename model_type<Values...>::type;

template<auto... Values>
using key_type_t = typename key_type<Values...>::type;
```

这时`Index`该如何实现?

```C++
template<auto... Extractors>
struct Index {
    using Model = model_type_t<Extractors...>;
    using Key =  key_type_t<Extractors...>;
    std::map<Key,int> data;

    static auto extractKey(Model const& model){
        if constexpr (sizeof...(Extractors) == 1)
            return  std::invoke(Extractors...,model);
        else
            return  std::make_tuple( std::invoke(Extractors,model)...);
    }
};
```

## 总结

## 参考

- [Alice's Adventures in Template Land](https://meetingcpp.com/2018/Talks/items/Alice_s_Adventures_in_Template_Land.html)
- [How do I create specializations of alias templates using class template specialization?](https://stackoverflow.com/questions/47060448/how-do-i-create-specializations-of-alias-templates-using-class-template-speciali)
