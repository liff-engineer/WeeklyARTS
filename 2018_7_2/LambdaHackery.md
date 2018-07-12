# 递归Recursive

举个阶乘的例子：
```C++
int factorial(int i){
    return (i==0)? 1:i*factorial(i-1);
}
```

如果用`lambda`表达式怎么写:
```C++
std::function<int(int)> factorial=[&factorial](int i){
    return (i==0)? 1:i*factorial(i-1);
};
```
`std::function`与`lambda`不一样,会有运行时损耗,所以可以用另外一种方案:
```C++
auto factorial =[](auto self,int i)-> int {
    return (i==0)? 1:i*self(self,i-1);
};
```
通用版`template`加持:
```C++
template<typename F>
struct recursive
{
    template<typename... Ts>
    decltype(auto) operator()(Ts&&... ts) const {
        return f(*this,std::forward<Ts>(ts)...);
    }
    F f;
};

auto const make_recursive = [](auto f){
    return recursive<decltype<f>>{std::move(f)};
};
```
这样再需要递归`lambda`就可以这些写:
```C++
auto factorial = make_recursive([](auto& self,int i)->int{
    return (i==0)? 1:i*self(i-1);
});
```
C++17之后有了[user-defined deduction guides](http://en.cppreference.com/w/cpp/language/class_template_argument_deduction),那么就可以这么写:
```C++
template<typename F>
recursive(F) -> recursive<F>;

auto factorial = recursive([](auto& self,int i)->int{
    return (i==0)? 1:i*self(i-1);
});
```

# 重载Overload
> 重载Lambda/函数在根据类型分发时非常有用,可以用来实现Visitor设计模式
>


普通的函数重载画风类似这样:
```C++
void print(int){std::cout<<__PRETTY_FUNCTION__ <<std::endl;};
void print(std::string){std::cout<<__PRETTY_FUNCTION__ <<std::endl;};
```
在C++17加入了[std::variant](http://en.cppreference.com/w/cpp/utility/variant)这种类型安全`union`后,需要有方法来访问其值,毕竟类型动态变化的,这时候就用到了[std::visit](http://en.cppreference.com/w/cpp/utility/variant/visit),例如：
```C++
using var_t = std::variant<int,std::string>;

struct print{
    void operator()(int){
        std::cout<<__PRETTY_FUNCTION__ <<std::endl;
    }
    void operator()(std::string){
        std::cout<<__PRETTY_FUNCTION__ <<std::endl;
    }
};

void example(var_t var){
    std::visit(print{},v);    
}
```
那么如何实现`Lambda`的`Overload`呢？假设`F1`是如下类型的`Lambda`：
```C++
auto f1 = [](int){ std::cout<<__PRETTY_FUNCTION__ <<std::endl; };
```
`F2`是如下类型的`Lambda`：
```C++
auto f1 = [](std::string){ std::cout<<__PRETTY_FUNCTION__ <<std::endl; };
```
那么可以声明如下形式的结构体来保存两种类型:
```C++
template<typename F1,typename F2>
struct overloaded:F1,F2
{
    overload(F1&& f1_arg,F2&& f2_arg)
        :F1(std::move(f1_arg)),F2(std::move(f2_arg)){};
};

template<typename F1,typename F2>
overloaded(F1&&,F2&&) -> overloaded<F1,F2>;

void example(){
     auto dispatcher = overload([](int){},[](std::string){});
     dispatcher(1);
     dispatcher(std::string("Hello,World"));
}
```
但是上述代码在有些编译器上有点儿问题,找不到重载的`operator()`,需要调整一下：
```C++
template<typename F1,typename F2>
struct overloaded:F1,F2
{
    using F1::operator();
    overloaded(F1&& f1_arg,F2&& f2_arg)
        :F1(std::move(f1_arg)),F2(std::move(f2_arg)){};
};
```
使用可变参数模板与统一初始化语法的形式：
```C++

template<typename Fs>
struct overloaded:Fs...
{
    using Fs::operator()...;
};

template<typename Fs...>
overloaded(Fs...) -> overloaded<Fs...>;
```

这时,之前的`std::visit`就可以写成如下形式:
```C++
using var_t = std::variant<int,std::string>;

struct print{
    void operator()(int){
        std::cout<<__PRETTY_FUNCTION__ <<std::endl;
    }
    void operator()(std::string){
        std::cout<<__PRETTY_FUNCTION__ <<std::endl;
    }
};

void example(var_t var){
    std::visit(overloaded{
        [](int){  std::cout<<__PRETTY_FUNCTION__ <<std::endl; },
        [](std::string){std::cout<<__PRETTY_FUNCTION__ <<std::endl;}
    },v);    
}
```
在有些时候,希望满足特定条件的类型都进入某个`Lambda`,这时可以使用`SFINAE`:
```C++
void example(var_t var){
    std::visit(overloaded{
        [](auto arg) -> std::enable_if_t<std::is_integral<decltype(arg)>:value>{  std::cout<<__PRETTY_FUNCTION__ <<std::endl; },
        [](auto arg) -> std::enable_if_t<!std::is_integral<decltype(arg)>:value>{std::cout<<__PRETTY_FUNCTION__ <<std::endl;}
    },v);    
}
```

# 参考
- [That `overloaded` Trick: Overloading Lambdas in C++17](https://dev.to/tmr232/that-overloaded-trick-overloading-lambdas-in-c17)
- [Lambda: Overloading and Recursive](http://jamboree.github.io/cout/tricks/2014/07/25/lambda-overloading-and-recursive.html)
- [Lambda hackery: Overloading, SFINAE and copyrights](https://ngathanasiou.wordpress.com/2015/10/20/lambda-hackery-overloading-sfinae-and-copyrights/)






