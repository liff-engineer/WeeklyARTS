# `std::any`实现技术解析

之前我介绍过`std::any`及其用法,这个对于不了个各种 C++库设计技巧的开发者来讲略微有点儿不可思议,是如何做到能够任何类型值的?

这里我将介绍一下`std::any`的可能实现方法,以及其中使用的各种技术.

## 实现思路

首先需要解决如何存储的问题,这里依然利用`void*`,还有堆栈存储技巧,这也是 SBO 常用实现技巧:

```C++
union storage
{
    void* dynamic; //堆存储
    std::aligned_storage_t<Len,Align> stack;//栈存储
};
```

既然要能够存储任意类型,就需要利用到自行实现的 vtable 技术.即约定好类型必须的各种操作,然后提供函数表实现,譬如针对`std::any`的场景,我们需要提供销毁、赋值、移动、交换、获取类型等几个基本操作:

```C++
struct vtable
{
    const std::type_info&(*type)() noexcept;
    void(*destory)(storage&) noexcept;
    void(*copy)(const storage& src, storage& dst);
    void(*move)(storage& src, storage& dst) noexcept;
    void(*swap)(storage& lhs, storage& rhs) noexcept;
};
```

之后根据要存储的类型不同,分别构造不同的`vtable`,从而使得后续操作不再依赖于类型.

## 动态和静态`vtable`实现

针对动态`vtable`相对比较简单易懂,我们只需要使用常规的操作方式操作`storage.dynamic`,完成类型指针与`void*`的互相转换即可:

```C++
template<typename T>
struct vtable_dynamic
{
    static const std::type_info& type() noexcept {
        return typeid(T);
    }

    static void destory(storage& m) noexcept {
        delete reinterpret_cast<T*>(m.dynamic);
    }

    static void copy(const storage& src, storage& dst) {
        dst.dynamic = new T(*reinterpret_cast<const T*>(src.dynamic));
    }

    static void move(storage& src, storage& dst) noexcept {
        dst.dynamic = src.dynamic;
        src.dynamic = nullptr;
    }

    static void swap(storage& lhs, storage& rhs) noexcept {
        std::swap(lhs.dynamic, rhs.dynamic);
    }
};
```

而针对静态`vtable`,我们首先需要了解[`new`表达式中的`Placement new`操作](https://en.cppreference.com/w/cpp/language/new),`Placement new`使得我们可以在已经申请好的内存中初始化特定对象,采用这种技术,我们就可以在栈上构造对象:

```C++
template<typename T>
struct vtable_stack
{
    static const std::type_info& type() noexcept {
        return typeid(T);
    }

    static void destory(storage& m) noexcept {
        reinterpret_cast<T*>(&m.stack)->~T();
    }

    static void copy(const storage& src, storage& dst) {
        new (&dst.stack) T(reinterpret_cast<const T&>(src.stack));
    }

    static void move(storage& src, storage& dst) noexcept {
        new (&dst.stack) T(std::move(reinterpret_cast<T&>(src.stack)));
        destory(src);
    }

    static void swap(storage& lhs, storage& rhs) noexcept {
        storage m;
        move(rhs, m);
        move(lhs, rhs);
        move(m, lhs);
    }
};
```

注意析构的语法是调用`~T()`,即调用类型的析构函数.其中`Placement new`表现为`new (&dst.stack) T`.

通过上述设施,我们可以存储堆/栈上内容,同时准备好了对应的操作`vtable`实现,下面我们看一下如何确定要存储到哪里.

## 类型存储方式判断

假设我们提供的 SBO 识别大小为两个`void*`指针,那么存储类型定义为:

```C++
union storage
{
    using stack_storage_t = std::aligned_storage_t<2 * sizeof(void*), std::alignment_of<void*>::value>;
    void* dynamic;
    stack_storage_t stack;
};
```

然后就需要判断类型`T`是否能够放入`stack`中.而且在[`std::any`的规格说明](https://en.cppreference.com/w/cpp/utility/any)中明确要去`T`必须满足`std::is_nothrow_move_constructible`才使用 SBO. 那么我们通过如下模板类来完成判断:

```C++
template<typename T>
struct require_allocation :std::integral_constant<bool,
    !(std::is_nothrow_move_constructible<T>::value &&
        sizeof(T) <= sizeof(storage::stack) &&
        std::alignment_of<T>::value <= std::alignment_of<storage::stack_storage_t>::value)>
{};
```

针对特定的类型就可以使用`require_allocation<T>::value`判断是否需要在堆上申请了.

## 为类型实现构造操作

有了上述的`require_allocation`模板,我们可以为特定类型提供`vtable`:

```C++
template<typename T>
static vtable* vtable_for_type() {
    using vtable_type = std::conditional_t<require_allocation<T>::value, vtable_dynamic<T>, vtable_stack<T>>;
    static vtable table{
        vtable_type::type,vtable_type::destory,
        vtable_type::copy,vtable_type::move,
        vtable_type::swap
    };
    return &table;
}
```

然后使用`std::enable_if`为类型提供构造操作:

```C++
private:
    storage m_;
    vtable* table_{ nullptr };

    //堆构造
    template<typename VT, typename T>
    std::enable_if_t<require_allocation<T>::value> do_construct(VT&& v) {
        m_.dynamic = new T(std::forward<VT>(v));
    }

    //栈构造
    template<typename VT, typename T>
    std::enable_if_t<!require_allocation<T>::value> do_construct(VT&& v) {
        new (&m_.stack) T(std::forward<VT>(v));
    }
```

需要注意,类型可能会添加修饰,我们需要通过`std::decay_t`获取真正的类型,这也是为什么有`VT`和`T`两种模板参数.

我们将上述两种操作合并成一个构造实现:

```C++
//构造并填充VTable
template<typename VT>
void construct(VT&& v) {
    using T = std::decay_t<VT>;
    this->table_ = vtable_for_type<T>();
    do_construct<VT, T>(std::forward<VT>(v));
}
```

## 实现`五件套`

然后为`any`类实现构造、拷贝、赋值、析构等操作:

构造实现如下:

```C++
any() = default;

holdeanyr(const any& other)
    :table_(other.table_)
{
    if (!other.empty()) {
        other.table_->copy(other.m_, this->m_);
    }
}

any(any&& other)
    :table_(other.table_)
{
    if (!other.empty()) {
        other.table_->move(other.m_, this->m_);
        other.table_ = nullptr;
    }
}

template<typename VT, typename = std::enable_if_t<!std::is_same<std::decay_t<VT>, any>::value>>
any(VT&& v)
{
    static_assert(std::is_copy_constructible<std::decay_t<VT>>::value,
        "T should satisfy the CopyConstructible requirements.");
    this->construct(std::forward<VT>(v));
}

any& operator=(any const& other) {
    any(other).swap(*this);
    return *this;
}

any& operator=(any&& other) noexcept {
    any(std::move(other)).swap(*this);
    return *this;
}

template<typename VT, typename = std::enable_if_t<!std::is_same<std::decay_t<VT>, any>::value>>
any& operator=(VT&& v) {
    static_assert(std::is_copy_constructible<std::decay_t<VT>>::value,
        "T should satisfy the CopyConstructible requirements.");
    any(std::forward<VT>(v)).swap(*this);
    return *this;
}

~any() {
    this->clear();
}

void clear() noexcept {
    if (!empty()) {
        this->table_->destory(m_);
        this->table_ = nullptr;
    }
}

bool empty() const noexcept {
    return this->table_ == nullptr;
}
```

除了上述常规操作,还提供了`empty`来判断是否有值.注意从类型构造使用了`std::enable_if`来区分`any`类型和其他类型.

## 其它

在完成上述操作之后,其它内容就相对比较简单了,譬如将`any`转换为其它类型,就是通过类型判断,然后使用`reinterpret_cast`转换.详情可见[Implementation of std::experimental::any](https://github.com/thelink2012/any/blob/master/any.hpp).

## 总结

从`any`的实现,可以看到 C++中 SBO 的实现方式,类型擦除的方法,其中使用到的各种技术也很有启示.不过如果有现成的 STL 使用还是尽量避免自己造轮子.毕竟技术门槛相对来讲还是较高的.
