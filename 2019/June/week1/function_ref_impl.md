# [`function_ref`实现技术解析](https://github.com/SuperV1234/Experiments/blob/master/function_ref.cpp)

针对`function_ref`的提案已经解析过了,这里根据示例实现来分析一下实现`function_ref`所用到的 C++技术.

## 从函数指针开始

虽然我们可以直接使用如下方式表示函数指针:

```C++
template<typename R,typename... Args>
using function_ref = R(*)(Args...);
```

但是考虑到要支持各种可调用对象,这里为其实现基本的结构形式如下:

```C++
template<typename R,typename... Args>
class function_ref
{
private:
    using Fn = R(*)(Args...);
    Fn fn;
public:
    constexpr function_ref(Fn arg)  noexcept
        :fn{ arg } {};

    function_ref(function_ref<R, Args...> const&) = default;
    function_ref<R, Args...>& operator=(Fn arg) noexcept {
        fn = arg;
        return *this;
    }
    function_ref<R, Args...>& operator=(function_ref<R, Args...> const&) = default;

    R operator()(Args... args)
    {
        return fn(std::forward<Args>(args)...);
    }
};
```

## 如何存储其它可调用对象

以上只能存储函数指针,为了支持仿函数以及 lambda,必须对其进行扩展.`function_ref`只是可调用对象的引用,这里我们可以选择将可调用对象的指针保存起来供后续调用指向,这里用到一些基础设施:

1. `void*` 用来储存可调用对象的指针/引用
2. `std::addressof`用来获取可调用对象地址
3. `std::invoke`用来执行可调用对象

那么我们可以以如下方式保存并执行可调用对象,假设可调用对象类型为`T`,实现思路如下:

- 保存可调用对象指针,使用`std::addressof`
- 构造可调用函数,使用无捕获 lambda
- 可调用函数使用`std::invoke`,从`void*`获取可调用对象指针,并转发调用参数

```C++

template<typename T>
constexpr std::pair<void*,Fn> do_construct(T&& obj) noexcept
{
    return std::make_pair(
        (void*)std::addressof(obj),
        [](void* ptr,Args... args) noexcept ->R{
            return std::invoke(
                *reinterpret_cast<std::add_pointer_t<T>>(ptr),
                std::forward<Args>(args)...
            );
        }
    );
}
```

需要注意的是,无捕获的 lambda 表达式与函数指针大小一致,一旦有捕获,则 lambda 表达式大小超过函数指针,会造成未定义行为.

于是我们的`function_ref`可以改造为:

```C++
template<typename R,typename... Args>
class function_ref
{
private:
    using Fn = R(*)(Args...);
    Fn fn;
    void* ptr;


    template<typename T>
    auto make_fn() noexcept {
        return  [](void* ptr, Args... args) noexcept ->R {
            return std::invoke(
                *reinterpret_cast<std::add_pointer_t<T>>(ptr),
                std::forward<Args>(args)...
            );
        }
    }
public:
    template<typename T>
    constexpr function_ref(T&& obj)  noexcept
        :ptr{ (void*)std::addressof(obj) },fn { make_fn <T>()}
    {};

    template<typename T>
    function_ref& operator=(T&& obj) noexcept {
        ptr = (void*)std::addressof(obj);
        fn = make_fn<T>();
        return *this;
    }

    function_ref(function_ref const&) noexcept = default;
    function_ref& operator=(function_ref const&) noexcept = default;

    constexpr void swap(function_ref&& other) noexcept
    {
        std::swap(ptr, other.ptr);
        std::swap(fn, other.fn);
    }

    R operator()(Args... args) const
    {
        return fn(ptr,std::forward<Args>(args)...);
    }
};
```

## 修复构造函数

可以看到我们有两个构造函数实现,从可调用对象类型`T`和从自身`function_ref`,这里需要区分一下,采用`std::enable_if_t`:

```C++
template<typename T,typename = std::enable_if_t<!std::is_same_v<std::decay_t<T>,function_ref>>>
constexpr function_ref(T&& obj)  noexcept
    :ptr{ (void*)std::addressof(obj) },fn { make_fn <T>()}
{};

template<typename T, typename = std::enable_if_t<!std::is_same_v<std::decay_t<T>, function_ref>>>
function_ref& operator=(T&& obj) noexcept {
    ptr = (void*)std::addressof(obj);
    fn = make_fn<T>();
    return *this;
}
```

## 总结

经过上述操作就可以实现最初版本的`function_ref`了,实际上根据函数签名是否`noexcept`,是否`const`,会产生不同的结果,需要分别实现出对应的`function_ref`特化,这里可以参阅标题的链接.
