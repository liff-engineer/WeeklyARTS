# ADL及其应用

- [What is “Argument-Dependent Lookup” (aka ADL, or “Koenig Lookup”)?](https://stackoverflow.com/questions/8111677/what-is-argument-dependent-lookup-aka-adl-or-koenig-lookup)
- [6.4.2 Argument-dependent name lookup](http://eel.is/c++draft/basic.lookup.argdep)
- [Argument-dependent lookup](https://en.cppreference.com/w/cpp/language/adl)
- [GotW #30 Name Lookup](http://www.gotw.ca/gotw/030.htm)

## 释义

C++标准中描述如下：
> 6.4.2 Argument-dependent name lookup [basic.lookup.argdep]
>
> When the postfix-expression in a function call is an unqualified-id, other namespaces not considered during the usual unqualified lookup may be searched, and in those namespaces, namespace-scope friend function or function template declarations ([class.friend]) not otherwise visible may be found. These modifications to the search depend on the types of the arguments (and for template template arguments, the namespace of the template argument).
>

简单理解起来就是:

> You don’t have to qualify the namespace for functions if one or more argument types are defined in the namespace of the function.

意思是说,如果函数的参数类型与函数处于同一命名空间,那么调用函数时可以不指定函数命名空间,根据参数类型即可查找到相应的函数,示例如下：

```C++
namespace MyNamespace
{
    class MyClass{};
    void doSomething(MyClass);
}

struct OtherClass{};
void doSomething(OtherClass);

void demo(){
    MyNamespace::MyClass obj;
    doSomething(obj);
}
```

在`demo`里,编译器可以根据`obj`的类型确定需要调用`MyNamespace::doSomething`,而不是当前命名空间的`doSomething`。

**在C++标准里描述的是当函数没有限定命名空间-`unqualified`,则可以将查找范围扩大到参数类型所在命名空间。**

## 应用

根据这个函数调用的特性,ADL通常被模板库作者用来支持扩展,例如:

```C++
//库实现
namespace framework
{
    template<typename T>
    void f(T);

    template<typename T>
    void process(T v){
        f(v);
    }
}

//用户定义
namespace user_impl
{
    template<typename T>
    struct object_t{};
}

//用户实现
namespace user_impl
{
    template<typename T>
    void f(object_t<T>);

    inline void f(object_t<bool>);
}

int main(){
    int i = 0;
    user_impl::object_t<int> oi;
    user_impl::object_t<bool> ob;

    framework::process(i);    //调用 framework::f(int)
    framework::process(oi);   //调用 user_impl::f<int>(int)
    framework::process(ob);   //调用 user_impl::f(object_t<bool>)
}
```

从示例中可以看到,`framework`提供了功能和默认实现,而`user_impl`可以通过调整参数类型的方式替换掉`frame_work`的默认实现,从而支持扩展。

## 真实世界的例子

### `operator<<`

`std::ostream`支持用户自定义类型的输出:

```C++
namespace stduser
{
    struct object_t{ };
    std::ostream& operator<<(std::ostream&,const object_t& o);
}

int main(){
    stduser::object_t o;
    std::cout<<o;  //ADL:根据o查找到 stduser::operator<<
}
```

### [Copy-and-swap](https://en.wikibooks.org/wiki/More_C%2B%2B_Idioms/Copy-and-swap)

> [What is the copy-and-swap idiom?](https://stackoverflow.com/questions/3279543/what-is-the-copy-and-swap-idiom/3279550#3279550)

```C++
class object
{
    object_impl impl;//具体实现
public:
    object& operator=(const object& other){
        if(this != &other){
            object(other).swap(*this);//利用复制构造和异常安全swap
        }
        return *this;
    }
    //swap版本1
    void swap(object& other){
        std::swap(impl,other.impl);//利用std的swap来进行内部信息交换
    }
    //swap版本2
    void swap(object& other){
        swap(impl,other.impl);
    }
    //swap版本3
    void swap(object& other){
        using std::swap;
        swap(impl,other.impl); //利用ADL,使得不局限于有std::swap的实现
    }

};
```

在上述三种`swap`实现中,通常建议使用第3种,既能使用`std::swap`实现,也能利用`ADL`根据参数类型调用特定的`swap`实现。

### [boost::intrusive_ptr](https://www.boost.org/doc/libs/1_67_0/libs/smart_ptr/doc/html/smart_ptr.html#intrusive_ptr)

`boost::intrusive_ptr`为了支持扩展,提供了`intrusive_ref_counter`等模板类来支持自定义类型：

```C++
using sp_adl_block::intrusive_ref_counter;
using sp_adl_block::thread_unsafe_counter;
using sp_adl_block::thread_safe_counter;
```
