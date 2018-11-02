# [Exploding tuples with fold expressions](https://blog.tartanllama.xyz/exploding-tuples-fold-expressions/)

接触到模板元编程,不可避免要用一下`std::tuple`,甚至有说法,自己实现了`std::tuple`就能够掌握模板元编程方方面面的知识.这次我们来看一看如何将`std::tuple`炸开分别操作.

譬如,想要实现如下的`for_each`能够循环`std::tuple`里的每个内容:

```C++
for_each(std::make_tuple(1,42.1,"hi"),[](auto&& v){ std::cout<<v<<'\n'; });
```

这段代码展开/执行的效果应该是:

```C++
template<typename T>
void lambda(T&& t){
    std::cout<<v<<'\n';
}

void for_each_impl( std::tuple<int,double,const char*> t){
    auto f = [](auto&& v){ std::cout<<v<<'\n'; };
    f(std::get<0>(t));
    f(std::get<1>(t));
    f(std::get<2>(t));
    //....
};
```

也就是说,需要将`std::tuple`中参数个数找出来,然后构造整数序列`0,1,2`,将其应用到`std::tuple`上,这也就是C++14引入的`std::index_sequence_for`的作用,根据参数列表构造索引序列,那么我们的`for_each`实现第一步如下:

```C++
template <typename... Args, typename Func>
void for_each(const std::tuple<Args...>& t, Func&& f) {
    for_each(t, f, std::index_sequence_for<Args...>{});
}
```

之后就要考虑如何展开了,这里使用到可变参数模板的展开:

```C++
template <typename... Args, typename Func, std::size_t... Idx>
void for_each(const std::tuple<Args...>& t, Func&& f, std::index_sequence<Idx...>) {
    f(std::get<Idx>(t))...;
}
```

使用`f(std::get<Idx>(t))...`将之前的调用展开成:

```C++
f(std::get<0>(t));
f(std::get<1>(t));
f(std::get<2>(t));
```

但是不幸的是,可变参数模板展开无法在函数上使用,需要借用一些技巧：

```C++
template <typename... Args, typename Func, std::size_t... Idx>
void for_each(const std::tuple& t, Func&& f, std::index_sequence<Idx...>) {
    (void)std::initializer_list<int> {
        (f(std::get<Idx>(t)), void(), 0)...
    };
}
```

使用初始化列表即可正常展开可变参数列表.

而在C++17中可以使用`fold expressions`来展开:

```C++
template <typename... Args, typename Func, std::size_t... Idx>
void for_each(const std::tuple<Args...>& t, Func&& f, std::index_sequence<Idx...>) {
    (f(std::get<Idx>(t)), ...);
}
```

让普通用户能够写出这样的代码还是有些困难的,毕竟非常难懂,那么可以实现辅助的`make_index_dispatcher`来使得普通用户也可以使用:

```C++
template <std::size_t... Idx>
auto make_index_dispatcher(std::index_sequence<Idx...>) {
    return [] (auto&& f) { (f(std::integral_constant<std::size_t,Idx>{}), ...); };
}
```

注意展开操作实现在`lambda`表达式里,并返回给调用者使用,这个`lambda`已经将将序列展开成如下形式:

```C++
f(0);
f(1);
f(2);
//......
```

有时候需要从参数个数来构造序列进行展开,那么实现如下:

```C++
template <std::size_t N>
auto make_index_dispatcher() {
    return make_index_dispatcher(std::make_index_sequence<N>{}); 
}
```

这时`for_each`实现如下:

```C++
template <typename... Args, typename Func>
void for_each(const std::tuple<Args...>& t, const Func& f) {
    auto dispatcher = make_index_dispatcher<sizeof...(Args)>();
    dispatcher([&](auto idx) { f(std::get<idx>(t)); });
}
```

注意如果要启用完美转发,获得更`generic`的版本,则可以这样写:

```C++
template <typename Tuple, typename Func>
void for_each(Tuple&& t, Func&& f) {
    constexpr auto n = std::tuple_size<std::decay_t<Tuple>>::value;
    auto dispatcher = make_index_dispatcher<n>();
    dispatcher([&f,&t](auto idx) { f(std::get<idx>(std::forward<Tuple>(t))); });
}
```

需要注意的是并不限制为`Tuple`,这个展开动作时编译期的,应用到`std::array`以及`std::pair`上也可以,`std::tuple_size<>`以及`std::get`均可以应用到`std::pair`、`std::array`、`std::tuple`上,如果自行实现的类型做一些适配动作也可以.


这个有什么作用?

假设你有一堆结构体需要从数据库中加载上来,结构体成员变量类型对应于数据库类型,或者需要转换,也就是说,可以将原有结构体定义转换成`std::tuple`,并提供`std::array<const char*,n>`来存储字段名,例如:

```C++
struct person
{
    std::string name;
    int age;
    double weight;
};
```

泛型版本为:

```C++
std::tuple<std::string,int,double> person_t;
std::array<const char*,3> person_fields={"name","age","weight"};
```

那么可以实现如下方式的泛型读写版本:

```C++
template<typename Result,typename Fields>
void read(database* db,int key,Result&& r,Fields&& fields){
    auto record = db->query(key);
    //遍历所有的字段,根据结果类型从数据库取对应类型
    for_each(r,fields,[&](auto&& m,auto&& identify ){
        m = record->get<decltype(m)>(identify);
    });
};
```

也就是说,为每个类型实现如下适配操作,即可完成从结构体到数据的映射:

```C++
struct person
{
    std::string name;
    int age;
    double weight;

    //告知数据库适配类型
    using db_types = std::tuple<std::string,int,double>;
    //告知数据库对应字段
    static auto  db_fields() -> std::array<const char*,std::tuple_size<db_types>::value>{
        return {"name","age","weight"};
    }
};
```

这种操作同样可以用来处理流化反流化。