# Weekly ARTS

- 如何检查类型 `T` 是否在模板参数包 `Ts...`中

## Algorithm

## Review

## Technique [如何检查类型 `T` 是否在模板参数包 `Ts...`中](https://stackoverflow.com/questions/56720024/how-can-i-check-type-t-is-among-parameter-pack-ts-in-c)

C++11 有了可变参数模板支持,使用时就会有这样的需求,判定类型`T`是否在`Ts...`中.我们的直觉是使用可变参数函数模板:

```C++
template<typename T,typename... Ts>
bool is_one_of<T,Ts...>();
```

使用递归遍历类型,检查类型是否相同,不同则继续下一个,直到到达终止条件:

```C++
template<typename T,typename U>
bool is_one_of<T,U>(){
    return std::is_same<T,U>;
}

template<typename T,typename U,typename... Ts>
bool is_one_of<T,U,Ts...>(){
    if(std::is_same<T,U>){
        return true;
    }
    else {
        return is_one_of<T,Ts...>();
    }
}
```

想法是挺好,但是 C++是不支持函数模板的偏特化的.

编译期表达常量,譬如布尔值,可以使用`std::true_type`以及`std::false_type`,这里可以使用类模板及其偏特化来实现:

```C++
template<typename...>
struct is_one_of: std::false_type{
};

template<typename T,typename U>
struct is_one_of<T,U>: std::is_same<T,U>{
};

template<typename T,typename U,typename... Ts>
struct is_one_of<T,U,Ts...>: std::conditional_t<std::is_same_v<T,U>,std::is_same<T,U>,is_one_of<T,Ts...>>{
};
```

默认`is_one_of`为`std::false_type`,指定终止条件`is_one_of<T,U>`为`std::is_same<T,U>`,然后使用`is_one_of<T,U,Ts...>`遍历`Ts...`.

C++模板编程需要转换观念,很多书写方式与普通的写代码不一样.不过后续的 C++标准一直在增强/简化模板编程,在 C++17 中使用`fold expression`就可以避免用类型及递归的方式实现,譬如:

```C++
template<typename T,typename... Ts>
constexpr bool is_one_of() noexcept {
    return (std::is_same_v<T,Ts>|| ...);
}
```

`fold expression`会将可变参数操作展开,针对`is_one_of<int,int,double,bool>`会被展开成如下形式:

```C++
return (std::is_same_v<int,int> || std::is_same_v<int,double> || std::is_same_v<int,boool> );
```

## Share
