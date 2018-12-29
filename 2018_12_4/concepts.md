# `Concepts` 简介

千呼万唤始出来,C++20 终于要带来`Concepts`了,让我们跟随作者的脚步简单了解一下`Concepts`:

- [A brief introduction to Concepts – Part 1](https://blog.feabhas.com/2018/12/a-brief-introduction-to-concepts-part-1/)
- [A brief introduction to Concepts – Part 2](https://blog.feabhas.com/2018/12/a-brief-introduction-to-concepts-part-2/)

## 一言难尽的模板

了解 C++的都知道模板的强大,也直到其"恐怖","听说你懂 C++?":
![听说你懂C++](https://pbs.twimg.com/media/DRqZ64fWsAE8Rtu.jpg:large)

其"恐怖"之处不是说比较难用、或者说比较难写,只是一旦出错了,即使富有经验的开发者面对庞大复杂的错误提示也难有头绪.

泛型代码的问题在于它并不是真正泛型.也就是说,我们不能期望泛型代码在任意可能的类型上都能正常工作.泛型代码通常都会对可替换类型有一些约束,譬如类型的特征、语义或者行为.不幸的是,在你发现无法满足要求之前都没办法找出这些约束,这通常发生在实例化期间,错误的地方通常是远离你的代码,位于其它复杂深入的库代码中.

而`Concepts`的设想已经存在了许多年,`Concepts`能够让我们在模板类型上表达约束,使得模板代码可以:

- 更易使用
- 更易调试
- 更易书写

以下将会展示`Concepts`的基本概念,其语法及使用方式.

## 不那么泛型的代码

假设我们要实现一个固定长度的 FIFO 缓冲,简单起见我们使用`std::array`实现:

```C++
template <typename T, size_t sz>
class Buffer {
public:
    void push(const T& in_val);
    T    pop();
    bool empty() const;

private:
    using Container = std::array<T, sz>;
    using Iterator  = typename Container::iterator;

    Container buffer    { };
    Iterator  write     { std::begin(buffer) };
    Iterator  read      { std::begin(buffer) };
    size_t    num_items { 0 };
};
```

在这里,我们忽略其内部实现.我们可以在客户端代码中创建不同类型的缓存:

```C++
#include "Buffer.h"

int main()
{
    Buffer<int, 16>   int_buf { };
    Buffer<double, 8> dbl_buf { };

    int_buf.push(100);

    // etc...
}
```

这时如果我将自定义类型应用到`Buffer`模板类上呢:

```C++
// Some Abstract Data Type
//
class ADT {
public:
    ADT(int init);

    void op_A() const;
    void op_B();
    void op_C();

private:
    // Attributes...
};

int main()
{
    Buffer<ADT, 16> adt_buffer { };   // 能够正常使用么..?
}
```

如果你熟悉模板代码,你可能已经猜出来问题所在了.这很有用,因为编译器爆出的错误提示并没有太大帮助.

对于那些不那么熟悉模板的人,错误出在编译器尝试构造 ADT 数组时.在没有任何其它信息的情况下,编译器试图调用 ADT 类的默认构造函数.我们的 ADT 忽略了默认构造函数,只有一个非默认构造函数.

如果编译器能够更有意义的诊断信息,这将会非常有用,我们就能很清楚问题出在哪里,为什么出错了.这就是模板`requirement`的来源.

注意:gcc 已经提供了`Concepts`提案的对应实现,以下代码示例开启了 gcc 的`Concepts`支持.

## `Requirements`

为了能够使用`Buffer`,模板参数必须是默认可构造的,也就是说必须能够在没有传递任何参数的情况下构造出对象,因而,我们必须有默认构造函数,或者为构造参数提供默认值.

我们可以将这些附加约束作为`Requirements`作用于模板类.`Requirements`是编译器布尔表达式.只有所有的要求都满足的情况下模板才会被实例化.

标准库提供了`std::is_default_constructible`来帮助我们判断类型是否是默认可构造的:

```C++
#include <type_traits>


template <typename T, size_t sz>
    requires std::is_default_constructible<T>::value
class Buffer {
public:
    void push(const T& in_val);
    T    pop();
    bool empty() const;

private:
    using Container = std::array<T, sz>;
    using Iterator  = typename Container::iterator;

    Container buffer    { };
    Iterator  write     { std::begin(buffer) };
    Iterator  read      { std::begin(buffer) };
    size_t    num_items { 0 };
};
```

这时在回到我们的 ADT 使用场景,错误信息相对就清晰多了:

```C++
int main()
{
    Buffer<ADT, 16> adt_buffer { };
}
```

```BASH
src/main.cpp:169:19: error: template constraint failure
     Buffer<ADT, 16> buffer { };
                   ^
src/main.cpp:169:19: note:   constraints not satisfied
src/main.cpp:169:19: note: 'std::is_default_constructible::value'
                           evaluated to false
```

向 ADT 类提供默认构造函数,这个错误信息就会消失.所以现在一切都好了么?

不尽然.

我们来看一下`Buffer`成员函数的实现:

```C++
template <typename T, size_t sz>
void Buffer<T, sz>::push(const T& in_val)
{
    if (num_items == sz) throw std::out_of_range { "Buffer full!" };

    *write = in_val;     // <= Insert by copy
    ++num_items;
    ++write;
    if (write == std::end(buffer)) write = std::begin(buffer);
}


template <typename T, size_t sz>
T Buffer<T, sz>::pop()
{
    if (num_items == 0) throw std::out_of_range { "Buffer empty!" };

    auto temp = *read;  // <= Extract by copy
    --num_items;
    ++read;
    if (read == std::end(buffer)) read = std::begin(buffer);

    return temp;
}
```

如果我们出于一些原因要使我们的 ADT 类不可复制,这时就出现了问题:

```C++
class ADT {
public:
    ADT(int init);

    void op_A() const;
    void op_B();
    void op_C();

    // ADTs are non-copyable
    //
    ADT(const ADT&)            = delete;
    ADT& operator=(const ADT&) = delete;

private:
    // Attributes...
};


int main()
{
    Buffer<ADT, 16> adt_buffer { };  // OK

    adt_buffer.push(ADT { });
}
```

```BASH
src/main.cpp: In instantiation of 'void Buffer<T, sz>::push(const T&)
[with T = ADT; long unsigned int sz = 16]':

src/main.cpp:175:24:   required from here
src/main.cpp:49:12: error: use of deleted function
'ADT& ADT::operator=(const ADT&)'

     *write = in_val;
     ~~~~~~~^~~~~~~~

src/main.cpp:86:10: note: declared here
     ADT& operator=(const ADT&) = delete;
          ^~~~~~~~
```

在这个示例中,错误信息还是相对直接的.但是在生产代码中,模板依赖于其它模板,其它模板又基于另外一些模板,这就无法保证针对大多数程序员错误信息能够被理解.

针对我们的`Buffer`模板类来说,我们不仅要求模板参数是默认可构造的,而且要求其可以拷贝构造和拷贝赋值:

```C++
template <typename T, size_t sz>
    requires std::is_default_constructible<T>::value &&
             std::is_copy_assignable<T>::value       &&
             std::is_copy_constructible<T>::value
class Buffer {
public:
    void push(const T& in_val);
    T    pop();
    bool empty() const;

private:
    using Container = std::array<T, sz>;
    using Iterator  = typename Container::iterator;

    Container buffer    { };
    Iterator  write     { std::begin(buffer) };
    Iterator  read      { std::begin(buffer) };
    size_t    num_items { 0 };
};
```

这时我们的错误诊断信息就变成了:

```C++
src/concepts.cpp: In function 'int main()':
src/concepts.cpp:297:19: error: template constraint failure

Buffer<ADT, 16> adt_buffer { }; // OK
^
src/concepts.cpp:297:19: note: constraints not satisfied

src/concepts.cpp:297:19: note: 'std::is_copy_assignable::value'
evaluated to false

src/concepts.cpp:297:19: note: 'std::is_copy_constructible::value'
evaluated to false

src/concepts.cpp:299:16: error: request for member 'push' in
'adt_buffer', which is of non-class type 'int'
adt_buffer.push(ADT { });
^~~~
```

## `中场`总结

真正泛型可以在任何类型情况下工作的代码是少数的,大多数场景下总会对模板参数有一些要求.通常这些约束是隐形的,只有在模板实例化的时候才会发现.

向模板参数添加显性要求有两个好处:

- 要求模板设计者考虑并文档化在模板参数上施加的约束.
- 为模板使用者提供有用的诊断信息;表达出他们代码缺少的部分.

我认为当你书写模板代码时,文档化你对参数的要求是好的实践.

但是在你的参数上显式列出所有需求会使得代码迅速变得复杂.并且,非常普遍,将要求包含到集合中来定义类型特性得抽象,这个就是`Concepts`想法的源头.

## 模板参数的约束

之前我们通过一个简单的示例对模板参数添加了一些小的要求来引入语法和语义.在现实情况下,施加到模板参数上的约束一般是以下内容的组合:

- 类型特征
- 所需的类型别名
- 所需的成员属性
- 所需的成员函数

明确列出每个模板参数的所有要求,那么模板函数或者模板类很快就会变得繁重.

为了简化这些约束的格式我们有了`Concepts`.

## `Concepts`

`Concept`定义了特定的模板类型必须支持的约束集合.在第一次介绍时,可以将`Concept`视为元类型,单这个不是精确的描述.你可以将`Concept`视为描述类型集合的语义,或者类型集合的特征.

`Concepts`以模板定义的方式书写,为特定类型指定一系列的要求.

```C++
template <typename T>
concept bool Bufferable =
requires(T) {
  requires std::is_default_constructible<T>::value;
  requires std::is_copy_assignable<T>::value;
  requires std::is_copy_constructible<T>::value;
};
```

我们将以前的一系列要求集合成为一个带有名称、可重用的`entity`.

注意`concept`的类型-`bool`.事实上,所有`Concepts`类型都是`bool`,所以可以省略;之所以留着`bool`是因为 C++中定义必须有类型.

这时将这个`Concept`应用到`Buffer`类上:

```C++
template <typename T, size_t sz>
    requires Bufferable<T>
class Buffer {
public:
    void push(const T& in_val);
    T    pop();
    bool empty() const;

private:
    using Container = std::array<T, sz>;
    using Iterator  = typename Container::iterator;

    Container buffer    { };
    Iterator  write     { std::begin(buffer) };
    Iterator  read      { std::begin(buffer) };
    size_t    num_items { 0 };
};
```

事实上,对于展示一个`Concept`来讲,这不是一个好的示例,`Bufferable`并不是类型的特征,甚至不是一个明确的语义.我只是拿这个例子作为:

- 一个展示语法的示例
- 因为现在我没有想到更好的示例
- 有更多好的例子你现在能够欣赏了

让我们使用另外一个不同的例子来展示我们可能会如何使用`Concepts`.`Scope-locked`惯用法使用 RAII 来保证资源锁定以避免死锁.以下是一个简单的实现:

```C++
template <typename T>
class Scope_lock {
public:
    Scope_lock(const T& lockable) : lock { lockable }
    {
        lock.lock();   // <= Lock on construction
    }

    ~Scope_lock()
    {
        lock.unlock(); // <= Unlock on destruction
    }

private:
  T lock;
};
```

为了能够使用`Scope_lock`,模板类型必须支持两种方法:`lock()`和`unlock()`.

我们使用一个`Concept`来定义这个约束:

```C++
template <typename T>
concept bool Lockable =
requires(T t) {
    { t.lock() }   -> void;
    { t.unlock() } -> void;
};
```

注意我们使用一个`实例`(并非真实实例)来表示`T`必须支持的方法.

之后我们就可以使用这个来约束`Scope_lock`的模板参数:

```C++
template <typename T>
    requires Lockable<T>
class Scope_lock {
public:
    Scope_lock(const T& lockable) : lock { lockable }
    {
        lock.lock();
    }

    ~Scope_lock()
    {
        lock.unlock();
    }

private:
  T lock;
};
```

针对以下互斥机制:

```C++
class Mutex {
public:
    void lock();
    bool try_lock();
    void unlock();
};


class Recursive_mutex {
public:
    void lock();
    bool try_lock();
    void unlock();
};


class Semaphore {
public:
    void give();
    void take();
};
```

我们可以得到以下预期结果:

```C++
int main()
{
    Mutex           mutex { };
    Recursive_mutex rec_mutex { };
    Semaphore       semphr { };

    Scope_lock lock1 { mutex };      // OK
    Scope_lock lock2 { rec_mutex };  // OK
    Scope_lock lock3 { semphr };     // FAIL
}
```

```BASH
src/main.cpp: In function 'int main()':
src/main.cpp:179:25: error: template constraint failure

     Scope_lock<Semaphore>       lock3 { semphr };     // FAIL
                         ^

src/main.cpp:179:25: note:   constraints not satisfied
src/main.cpp:95:14: note: within 'template<class T> concept
const bool Lockable<T> [with T = Semaphore]'

 concept bool Lockable =
              ^~~~~~~~

src/main.cpp:95:14: note:     with 'Semaphore t'
src/main.cpp:95:14: note: the required expression
't.lock()' would be ill-formed

src/main.cpp:95:14: note: the required expression
't.unlock()' would be ill-formed
```

## 使用`Concepts`指定接口而不是类型

C++提供了语法糖来更简便地表达,譬如:

```C++
template <typename T>
    requires Lockable<T>
class Scope_lock {
    // ...
};
```

可以写成如下形式:

```C++
template <Lockable T>
class Scope_lock {
    // ...
};
```

这种方式不仅仅可以应用到模板类上,模板参数也一样,譬如:

```C++
emplate <typename T>
    requires Lockable<T>
void lock(const T& in_val);
```

可以写作:

```C++
template <Lockable T>
void lock(const T& in_val);
```

甚至是:

```C++
void lock(const Lockable& in_val);
```

这种附加的语法使得我们可以写出富有表达力而且良好定义的接口:

```C++
// Supports any type
//
template <typename T>
void process_any(const T& in);


// Supports any type that fulfils the Lockable concept
//
void process_some(const Lockable& in);


// Only supports Mutex (or sub-types)
//
void process_one(const Mutex& in);


int main()
{
    Mutex mtx { };
    process_any(mtx);            // OK
    process_some(mtx);           // OK
    process_one(mtx);            // OK

    Recursive_mutex rec_mtx { };
    process_any(rec_mtx);        // OK
    process_some(rec_mtx);       // OK
    process_one(rec_mtx);        // FAIL

    Semaphore semphr { };
    process_any(semphr);         // OK
    process_some(semphr);        // FAIL
    process_one(semphr);         // FAIL
}
```

## TO BE FINISH
