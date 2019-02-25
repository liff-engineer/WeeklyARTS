# [一些模板元编程的测试/调试技巧](https://cukic.co/2019/02/19/tmp-testing-and-debugging-templates/)

在模板元编程中,即使我们犯了很小的错误,编译器也会爆出大量错误信息,这里有一些小技巧来利用错误信息帮助我们识别问题.

模板元编程中最典型的错误就是非预期的类型,编译器推导出的类型并不是我们想要的类型.这时候的错误信息感觉就像在代码随机位置出现.

## 打印调试

就像在调试问题时使用`print`打印值一样,而在模板元编程的调试过程中打印类型也会很有用.

这里有一个 C++的`meta-function`:

```C++
template<typename... Ts>
struct print_types;
```

这个`meta-function`接受几个参数,但是没有实现.这就意味着每次我们尝试使用它,编译器就会报错,同时附带一些关于`Ts...`参数的信息.

例如,如果我们想要知道`std::vector<bool>::reference`等的确切类型,可以这样做:

```C++
print_types<
    std::vector<bool>::reference,
    std::vector<bool>::value_type,
    std::vector<bool>::iterator
    >{};
```

这时编译器就会打印出类似如下的信息:

```TXT
invalid use of incomplete type 'class print_types<
    std::_Bit_reference,
    bool,
    std::_Bit_iterator
    >'
```

可以看到,编译器打印出了我们想要的三个类型信息.

## 打印类型数次

之前的方法的问题在于只能运行一次`print_types`,一旦编译器运行,就会发生错误,然后停止编译.

如果我们不想触发错误,只是想要看到信息,那么可以通过触发编译器警告来实现.

触发警告最简单的就是`deprecation`警告-简单地将`print_types`类标记为`[[depreacted]]`:

```C++
template <typename... Ts>
struct [[deprecated]] print_types {};
```

通过这种方式,我们可以多次使用,编译器会为每一次使用都生成一个警告信息.

## 类型断言

当书写`TMP`代码时,断言一些类型满足所需要的属性是很有用的.

例如如果你希望模板参数都是值类型的,就可以创建一个如下断言宏来使用:

```C++
#define assert_value_type(T)                            \
    static_assert(                                      \
        std::is_same_v<T, std::remove_cvref_t<T>>,      \
        "Not a value type")
```

养成添加断言的习惯能够使得你的生活变得更见简单.

## 类型测试

就如我们最初实现的`print_types`一样,`static_assert`一旦失败就会停止编译.

那么如果我们只是想在测试失败时获取通知,而不是停止编译呢.

我们可以使用之前允许`print_types`调用多次的技巧,使用`[[depreacted]]`注解来获取警告替代`static_assert`的错误.

可以通过多种方式来实现,以下是其中一种实现:

```C++
template <typename T>
struct static_test {
    static_test(std::true_type) {}
};

template <>
struct [[deprecated]] static_test {
    static_test(std::false_type) {}
};

template <typename T>
static_test(T x) -> static_test<T>;
```

使用方式也非常简单:

```C++
static_test int_is_int { std::is_same<int, int>::type{} };
```

当测试返回`std::false_type`时会获取`deprecation`警告.

## 总结

模板元编程很有趣,这些调试技巧对于我们书写模板元编程代码会非常有帮助.当然,如果是针对值的模板元编程,则可以考虑`constexpr`.
