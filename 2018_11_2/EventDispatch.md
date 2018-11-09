# [C++中事件分发模板实现](https://godbolt.org/z/NBIuvb)

刷Twitter发现了一些针对事件分发的模板实现及其对比,还是很有意思的,其中应用的模板技术值得学习,分析总结一下.

## 需求是什么

事件分发机制在Qt中就有实例,所有的事件继承自一个基类`QEvent`,每个事件尤其唯一的`id`和不同的数据,在处理事件时将`QEvent`转换为具体的事件进行处理,而分发时是单个接口直接分发事件`dispatch(QEvent event)`.

那么如果事件类型是编译期能够确定,完全可以采用模板来实现,接口如下:

```C++
dispatch<event1,event2,event3>(event_id,event_handler,event_data);
```

其中`event_handler`根据不同的事件类型分发给不同的事件处理例程,`event_data`即为事件附加数据.

## 事件的定义

```C++
struct Event
{
    static constexpr auto id = __COUNTER__;
    const char**data{};
};
```

其中`id`即为事件的唯一ID,编译期决定且唯一,由于事件不需要持久化,这里其具体值并不影响.

以下是示例:

```C++
struct Event0 {
  static constexpr auto id = __COUNTER__;
  const char **data{};
};

struct Event1 {
  static constexpr auto id = __COUNTER__;
  const char **data{};
};

struct Event2 {
  static constexpr auto id = __COUNTER__;
  const char **data{};
};
```

## `茴`字有几种写法?

这里有四种写法:

- `if-else`
- `switch`
- 跳表
- C++17的fold expr

### `if_else`

需要在编译期判断ID是否一致,不一致继续展开:

```C++
template <class TEvent, class... TEvents, class TExpr, class T>
constexpr auto dispatch(int const id, TExpr const &expr, T const &data) {
  if (TEvent::id == id) {
    expr(TEvent{data});
  } else {
    if constexpr (sizeof...(TEvents) > 0)
      dispatch<TEvents...>(id, expr, data);
  }
}
```

使用`constexpr`使其能够在编译期将原本运行期的`if else`在编译期生成。

### `switch`

`switch`的实现也是借用`constexpr`和`if constexpr`,递归调用`dispatch`:

```C++
template <class TEvent, class... TEvents, class TExpr, class T>
constexpr auto dispatch(int const id, TExpr const &expr, T const &data) {
  switch (id) {
  default:
    if constexpr (sizeof...(TEvents) > 0)
      dispatch<TEvents...>(id, expr, data);
    break;
  case TEvent::id:
    expr(TEvent{data});
    break;
  }
}
```

### 跳表

构造函数数组,以`id`为索引,根据不同的`id`调用不同的函数:

```C++
template <class... TEvents, class TExpr, class T>
constexpr auto dispatch(int const id, TExpr const &expr, T const &data) {
  constexpr void (*jump_table[])(TExpr const &, T const &) = {
      [](TExpr const &expr, T const &data) { expr(TEvents{data}); }...};
  jump_table[id](expr, data);
}
```

### `fold expr`

使用`fold expression`可以将其根据`events`展开成`if xxx;if xxx;...`等形式:

```C++
template <class... TEvents, class TExpr, class T>
constexpr auto dispatch(int const id, TExpr const &expr, T const &data) {
  (([&] { if (TEvents::id == id) expr(TEvents{data}); }()), ...);
}
```

## 总结

C++11起,C++语言发生了很多变化,模板得到了增强,constexpr特性更使得代码模糊了编译期和运行期,有了更多的可能性,如何落地应用,还是需要多多思考。