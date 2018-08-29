# 如何隐藏构造函数

在一些场景下需要隐藏构造函数,通过其它类来构造相应的对象,譬如如下类：

```C++
class object_t
{
public:
    void report();
};

class object_factory_t
{
public:
    object_t create();
};
```

希望`object_t`无法直接构造,只能通过`object_factory_t`进行构造。

那么该如何实现?

## 隐藏构造相关实现

首先就是要将构造函数隐藏掉,这样就无法直接创建`object_t`了:

```C++
class object_t
{
private:
    object_t(){};
    object_t(object_t const&)=default;
};
```

## 方法1:使用friend

通过将`object_factory_t`设置为`object_t`的友元,这样`object_factory_t`可以访问被隐藏的构造函数：

```C++
class object_t{
    friend class object_factory_t;
};
```

但是这种方法有个问题,`object_factory_t`能够访问`object_t`的所有成员,而我们只是希望可以通过`object_factory_t`来构造,开放访问可能带来安全隐患。

## 方法2:The passkey idiom

这种方法通过为`object_t`构造方法提供特定的辅助类,而辅助类只能用`object_factory_t`来构造：

```C++
class object_t {
    class key_t {
        friend class object_factory_t;
    private:
        key_t(){};
        key_t(key_t const&) = default;
    };
public:
    explicit object_t(key_t);
};
```

由于构造`object_t`需要`key_t`,而`key_t`在`object_t`,只有`object_factory_t`能够访问,`object_factory_t`能够访问的也只有`key_t`,从而解决了`friend`方法会开放`object_t`的问题。

但是这个方法也存在问题,除了`object_t`要有`key_t`,构造函数也要调整。

## 方法3: 辅助构造工厂类

方法2是从`object_t`类入手,这种方法从`object_factory_t`入手,提供一个模板工厂类`factory_t`:

```C++
template<typename T>
class factory_t{
    friend class object_factory_t;//是否有必要

    factory_t(){};

    template<typename... Args>
    T create(Args... args){
        return T{args};
    }
};
```

而`object_t`则以`factory_t<object_t>`为`friend`:

```C++
class object_t{
    friend class factory_t<object_t>;

    object_t(){};
public:
    void report();
};
```

而`object_factory_t`则可以借用`factory_t`来构造`object_t`:

```C++
object_t object_factory_t::create(){
    return factory_t<object_t>{}.create();
}
```

## 总结

相对来讲,第3种方法最接近要求,代码也相对简洁;模板真是奇妙的特性。

## 参考

- [Passkey Idiom: More Useful Empty Classes](https://arne-mertz.de/2016/10/passkey-idiom/)

- [Friendship and the Attorney-Client](https://en.wikibooks.org/wiki/More_C%2B%2B_Idioms/Friendship_and_the_Attorney-Client)

- [Unforgettable Factory Registration](http://www.nirfriedman.com/2018/04/29/unforgettable-factory/)