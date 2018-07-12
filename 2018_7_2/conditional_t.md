# [std::conditional_t](https://en.cppreference.com/w/cpp/types/conditional)的实现与启示

> 参考自[SCARY metafunctions](https://quuxplusone.github.io/blog/2018/07/09/scary-metafunctions/)

一种实现方式如下:

```C++
template<bool B,class T,class F>
struct conditional {
    using type = T;
};

template<class T,class F>
struct conditional<false,T,F> {
    using type = F;
};

template<bool B,class T,class F>
using conditional_t = typename conditional<B,T,F>::type;
```

定义了`conditional`模板,默认`type`为`T`,然后偏特化`B`来调整`type`,最终用模板别名取出对应的类型。

而效率更高的方式如下：

```C++
template<bool B,class T,class F>
struct conditional {
    template<class T,class F>
    using f = T;
};

template<class T,class F>
struct conditional<false,T,F> {
    template<class T,class F>
    using f = F;
};

template<bool B,class T,class F>
using conditional_t = typename conditional<B>::template f<T,F>;
```

那么为什么第二种实现方式效率高呢?

- 第一种需要为每种不同的使用都实例化`conditional`类型

```C++
conditional_t<true,T1,T2>; //1 -> conditional<true,T1,T2>
conditional_t<false,T1,T2>; //2 -> conditional<false,T1,T2>
conditional_t<true,T3,T4>; //3 -> conditional<true,T3,T4>
conditional_t<false,T3,T4>; //4 -> conditional<false,T3,T4>
```

- 第二种只需要实例化两种`conditional`类型

```C++
conditional_t<true,T1,T2>; //1 -> conditional<true>
conditional_t<false,T1,T2>; //2 -> conditional<false>
conditional_t<true,T3,T4>; //1 -> conditional<true>
conditional_t<false,T3,T4>; //2-> conditional<false>
```

在使用模板元编程时不仅仅要关注实现,也需要关注性能,尽量减少类型实例化是其中一个手段。