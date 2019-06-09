# [`function_ref`:可调用对象的非持有引用](http://www.open-std.org/jtc1/sc22/wg21/docs/papers/2018/p0792r3.html)

## 摘要

本文提出在标准库中添加`function_ref<R(Args...)>`,作为`Callable`对象的非持有引用"词汇类型".

## 概述

自从 C++11 发布以来,编写更为函数式风格的代码变得容易:函数式编程范式和惯用法成为 C++开发者工具集的强大补充.**高阶函数**是函数式范式的主要思想,简单来说,高阶函数以函数作为参数并/或者以函数为返回结果.

在编写函数式风格的 C++代码时,经常需要引用现有的`Callable`对象,但是很不幸标准库并没有提供如此灵活的设施来这么做.让我们看一看现有的方式:

- **函数指针**只有在它们指向的是无状态(例如非成员函数或者无捕获 lambda)是才有用,其它情况下使用它们非常麻烦.而且`Callable`的概念需要能够处理**成员函数指针**和**成员变量指针**.

- **`std::function`**能够与`Callable`对象完美契合,但是它是"通用用途多态函数包装器",因而可能引入没有必要的`overhead`,而且其**持有**它所存储的`Callable`对象.当需要持有类型擦除包装器时时非常好的选择,但它经常被滥用在不需要所有权语义和灵活性的场景中.

  - 注意,当`std::function`通过`std::reference_wrapper`进行构造或者赋值时,它拥有引用语义.
  - 另一个`std::function`的限制是,其存储的`Callable`必须是可以拷贝构造的.

- **模板**在希望避免不必要的损耗,以及统一处理任意`Callable`对象时使用,但是它们很难约束具体的签名,并且强制代码在头文件中定义.

本文提出引入一个新的`function_ref`类模板,和`std::string_view`比较类似.本文将`std::function_ref`描述为一种任意可调用对象的**非持有轻量包装器**.

## 动机示例

这里将展示一个示例来看一看如何从*高阶函数*获取受益:一个`retry(n,f)`函数试图异步调用`f`最多`n`次直到成功.示例是模拟反复查询 Web 服务的真实场景.

```C++
struct payload { /* ... */ };

// Repeatedly invokes `action` up to `times` repetitions.
// Immediately returns if `action` returns a valid `payload`.
// Returns `std::nullopt` otherwise.
std::optional<payload> retry(std::size_t times, /* ????? */ action);
```

传递的`action`应当是可调用对象,这个对象是无参的,需要返回`std::optional<payload>`.让我们看一看如何以各种即使实现`retry`:

- 使用*函数指针*:

  ```C++
  std::optional<payload> retry(std::size_t times,
                           std::optional<payload>(*action)())
  {
      /* ... */
  }
  ```

  - 优势:
    - 易于实现:不需要使用模板或者其它显式约束(例如`std::enable_if_t<...>`).指针的类型确切地指定了可以传递的函数,不需要额外约束.
    - 最小开销:没有内存申请,没有异常,`action`只有一个指针大小.
      - 现代编译期能够完全内联调用`action`,产生优化的汇编.
  - 劣势:
    - 该技术不支持状态`Callable`对象.

- 使用模板:

  ```C++
  template <typename F>
  auto retry(std::size_t times, F&& action)
  -> std::enable_if_t<std::is_invocable_r_v<std::optional<payload>, F&&>,
  std::optional<payload>>
  {
  /_ ... _/
  }
  ```

  - 优势:
    - 支持任意可调用对象,即使是有状态闭包
    - 零开销:没有内存申请,没有异常,没有间接性
  - 劣势:
    - 实现比较困难而且不易读:用户必须使用`std::enable_if_t`和`std::invocable_r_v`来保证`action`的签名被正确约束.
    - `retry`必须定义到头文件中.在尝试最小化编译时间时,可能是无法接受的.

- 使用`std::function`:

  ```C++
  std::optional<payload> retry(std::size_t times,
                             std::function<std::optional<payload>()> action)
  {
    /* ... */
  }
  ```

  - 优势:
    - 支持任意可调用对象,即使是有状态闭包
    - 易于实现:不需要使用模板或者显式约束.该类型完全约束了可以传递的内容.
  - 劣势:
    - 不明确的所有权语义:`action`可以持有存储的`Callable`,或者引用现有的`Callable`(通过`std::reference_wrapper`方式初始化).
    - 可能会有很大开销:
      - 即使实现方式使用了 SBO(_small buffer optimization_),如果存储的对象足够大,`std::function`也可能会申请内存.这需要在构造/赋值上有额外分支处理,一个潜在的动态分配,并使得`action`与内部缓存区大小一样.
      - 如果实现不使用 SBO,`std::function`将总是在构造/赋值时申请内存.
      - 现代编译器无法内联`std::function`,对比之前的技术,经常会产生糟糕的汇编.
    - 强制使用异常:`std::function`在内存分配时可能会抛出异常,如果调用对象没有设置,则调用时会抛出`std::bad_function_call`.

- 使用本文的`function_ref`：

  ```C++
  std::optional<payload> retry(std::size_t times,
  function_ref<std::optional<payload>()> action)
  {
  /_ ... _/
  }
  ```

  - 优势:
    - 支持任意可调用对象,即使是有状态闭包
    - 易于实现:不需要使用模板或者显式约束.该类型完全约束了可以传递的内容.
    - 清晰的所有权语义:`action`是现存`Callable`的非持有引用
    - 小开销:没有分配,没有异常,`action`是两个指针大小
      - 现代编译期能够完全内联调用`action`,产生优化的汇编.

## 概要

```C++
namespace std
{
    template <typename Signature>
    class function_ref
    {
        void* object; // exposition only

        R(*erased_function)(Args...) qualifiers; // exposition only
        // `R`, `Args...`, and `qualifiers` are the return type, the parameter-type-list,
        // and the sequence "cv-qualifier-seq-opt noexcept-specifier-opt" of the function
        // type `Signature`, respectively.

    public:
        constexpr function_ref(const function_ref&) noexcept = default;

        template <typename F>
        constexpr function_ref(F&&);

        constexpr function_ref& operator=(const function_ref&) noexcept = default;

        template <typename F>
        constexpr function_ref& operator=(F&&);

        constexpr void swap(function_ref&) noexcept;

        R operator()(Args...) const noexcept-qualifier;
        // `R`, `Args...`, and `noexcept-qualifier` are the return type, the parameter-type-list,
        // and the sequence "noexcept-specifier-opt" of the function type `Signature`,
        // respectively.
    };

    template <typename Signature>
    constexpr void swap(function_ref<Signature>&, function_ref<Signature>&) noexcept;

    template <typename R, typename... Args>
    function_ref(R (*)(Args...)) -> function_ref<R(Args...)>;

    template <typename R, typename... Args>
    function_ref(R (*)(Args...) noexcept) -> function_ref<R(Args...) noexcept>;

    template <typename F>
    function_ref(F&&) -> function_ref<see below>;
}
```

## 示例实现

示例实现参见[GitHub 上的示例](https://github.com/SuperV1234/Experiments/blob/master/function_ref.cpp).

## 存在的问题

在常见使用场景中,`function_ref`接受临时值非常有用,将临时值作为函数参数,例如:

```C++
void foo(function_ref<void()>);

int main()
{
    foo([]{ });
}
```

以上使用是完全安全的:通过 lambda 生成的临时闭包在`foo`调用过程中能够保证存在.不幸的是,这也会导致以下代码会产生未定义行为:

```C++
int main()
{
    function_ref<void()> f{[]{ }};
    // ...
    f(); // undefined behavior
}
```

上述闭包是临时值,当`function_ref`构造完成,生命周期就结束了.`function_ref`持有了一个"死"闭包的地址,一旦调用就会产生未定义行为.作为示例,`AddressSanitizer`能够检测到无效内存访问.注意这个问题并非`function_ref`独有,最近标准化的`std::string_view`也有一样的问题.

我坚信接受临时值对于`function_ref`和`std::string_view`来说是"必要的恶",因为它们有无数有用的场景.悬挂引用的问题一致存在于语言之中.而 Herb Sutter 和 Neil Macintosh 的生命周期追踪即使可以防止错误,而不会限制视图/引用类型的使用.
