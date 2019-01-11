# 动态、静态 visitor 实现

```C++
#include <typeinfo>

template<typename T>
void report(const T* v);

template<typename... Ts>
struct type_list{};

template<typename... Ts>
constexpr bool visit(const void* ptr,const std::type_info& type,type_list<Ts...>);

template<>
constexpr bool visit(const void* ptr,const std::type_info& type,type_list<>){
    return false;
}

template <typename T, typename... Rs>
constexpr bool visit(const void* ptr,const std::type_info& type,type_list<T,Rs...>){
    if(typeid(T)==type){
        report(reinterpret_cast<const T*>(ptr));
        return true;
    }
    return visit(ptr,type,type_list<Rs...>{});
}

int main(){
    double v = 100;
    visit(&v,typeid(double),type_list<int,bool,char,double>{});
    return 0;
}
```

使用`const void* ptr`来存储对象,使用`const std::type_info& type`来记录类型信息,运行时比对与分发.支持多种类型信息抽取,实际上是对以下代码的抽象:

```C++

if(type == typeid(int)){
    call(reinterpret_cast<int*>(ptr))
}
else if(type == typeid(double)){
    call(reinterpret_cast<double*>(ptr))
}
else if(type == typeid(bool)){
    call(reinterpret_cast<bool*>(ptr))
}
else if(type == typeid(char)){
    call(reinterpret_cast<char*>(ptr))
}
```
