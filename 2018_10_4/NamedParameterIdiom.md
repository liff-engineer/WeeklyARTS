# [Named Parameter](https://en.wikibooks.org/wiki/More_C%2B%2B_Idioms/Named_Parameter)

什么是`Named Parameter`? 来个例子就明白了:

```C++
class configs {
    std::string server;
    std::string protocol;
public:
    configs& set_server(std::string const& s);
    configs& set_protocol(std::string const& s);
};

void example(){
    start_server(configs().set_server("localhost").set_protocol("https"));
}
```

基本上就是提供流式参数设置来构造对象的思路,关键技术就是每个接口返回原始对象来支持链式的书写方式.

但是不同的函数重载有不同的效果:

```C++
configs& set_server(std::string const& s){
    server = s;
    return *this;
};

configs set_server(std::string const& s) const{
    configs temp(*this);
    temp.server = s;
    return temp;
};
```

第一种实现是修改原有对象,第二种实现是复制原有对象并修改,不过还有第三种方式:

```C++
configs set_server(std::string const& s)&&{
    server = s;
    return *this;
};
```

这种方式在C++11后需要实现,用来支持move操作,但是这种写法面临重复构造析构的问题,正确的书写方式是:

```C++
configs&& set_server(std::string const& s)&&{
    server = s;
    return std::move(*this);
};
```

需要关注的是,在C++11之后,成员函数的声明变得更为复杂,`&&`以及`&`可以前置也可以后置,[C++Now 2018: Titus Winters “Modern C++ API Design: From Rvalue-References to Type Design”](https://www.youtube.com/watch?v=2UmDvg5xv1U)中有展开叙述,可以看看.