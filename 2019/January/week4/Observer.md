# C++中观察者模式的一种实现

通常 C++中实现的观察者模式都是参考 Java 等实现而作的,但是面临一些耦合等等问题,而 C++针对其有一些特别的解决办法,譬如 Qt 的信号与槽.

第三方库中类似 Qt 的信号与槽机制,在 Boost 里就有`Boost.Signal2`,而在 C++11 之后,有了可变参数模板和类型擦除技术来支持,我们可以根据自己需求实现简易的信号与槽.

在这里我们还是遵照"传统"实现来更为灵活的观察者.

## 目标

```C++
subject<> signal;
signal.subscribe(functor);

signal();
signal.notify();

auto conn = signal.subscribe(lambda);
//...

conn.unsubscribe();
```

这里使用`subject`模板类来定义可观察对象,观察者通过`subject.subscribe`来注册,这样当`subject.notify`时就可以接收到通知来采取动作.

如果需要取消观察,可以在使用`subscribe`时记录结果`subscription`,然后调用`subscription.unsubscribe`取消观察.

## 初步实现

这里使用`std::function`来记录观察者方法.使用`std::vector<std::function<>>`来存储观察者.暂时先不考虑取消注册.

```C++
template <typename... Args>
class subject
{
  public:
    using observer_type = void(Args...);

  public:
    template <typename Callable>
    auto subscribe(Callable &&observer)
    {
        static_assert(std::is_convertible_v<Callable, std::function<observer_type>>,
                      "The provided observer object is not callable or not compatible with subject");
        observers_.emplace(observer);
    }

    void notify(Args &&... args) const
    {
        for (auto &&kv : observers_)
        {
            kv(std::forward<Args>(args)...);
        }
    }

    void operator()(Args &&... args) const
    {
        return notify(std::forward<Args>(args)...);
    }

    auto size() const noexcept
    {
        return observers_.size();
    }

  public:
    subject() = default;
    subject(subject const &) = delete;
    subject &operator=(subject const &) = delete;
    subject(subject &&) = default;
    subject &operator=(subject &&) = default;

  private:
    std::vector<std::function<observer_type>> observers_;
};
```

## 实现取消注册

这里定义`subscription`来存储取消注册的方法:

```C++
class subscription
{
  public:
    subscription(subscription const &) = default;
    subscription &operator=(subscription const &) = default;
    subscription(subscription &&) = default;
    subscription &operator=(subscription &&) = default;

    void unsubscribe() const
    {
        if (!action_)
            return;
        action_();
    }

    explicit operator bool() const
    {
        return !!action_;
    }

  protected:
    template <typename... Args>
    friend class subject;

    subscription() = default;

    subscription(std::function<void()> const &fn) : action_{fn} {};

  private:
    std::function<void()> action_{};
};
```

通过为每个观察者生成唯一 ID,来支持取消注册:

```C++
    template <typename Callable>
    auto subscribe(Callable &&observer) -> subscription
    {
        static_assert(std::is_convertible_v<Callable, std::function<observer_type>>,
                      "The provided observer object is not callable or not compatible with subject");
        auto key = next();
        observers_.emplace(key, observer);
        return subscription{[this, key]() {
            unsubscribe(key);
        }};
    }

    void notify(Args &&... args) const
    {
        for (auto &&kv : observers_)
        {
            kv.second(std::forward<Args>(args)...);
        }
    }
  private:
    //取消注册
    void unsubscribe(int key) noexcept
    {
        observers_.erase(key);
    }

    //运行时唯一ID生成
    int next() const
    {
        static int v = 0;
        return v++;
    }

  private:
    std::map<int, std::function<observer_type>> observers_;
```

## 辅助注销类

使用 RAII 技术可以实现退出作用域自动取消观察,这样可以将`subscription`对象作为成员变量,对象析构时自动取消观察,从而避免手动取消.

```C++
class scope_subscription
{
  public:
    scope_subscription() = default;
    explicit scope_subscription(subscription &&sub) : target_{sub} {};

    ~scope_subscription()
    {
        if (!target_)
            return;
        try
        {
            target_.unsubscribe();
        }
        catch (...)
        {
        }
    }

    scope_subscription(scope_subscription const &) = delete;
    scope_subscription &operator=(scope_subscription const &) = delete;
    scope_subscription(scope_subscription &&) = default;
    scope_subscription &operator=(scope_subscription &&) = default;

  private:
    subscription target_{};
};
```

以如下方式使用:

```C++
subject<> signal;

{
    auto conn = scope_subscription{
        signal.subscribe(functor)
    };

    signal.notify();
}
//conn退出作用域自动注销
signal.notify();
```

## 更便利的实现

上述虽然用起来比较简单了,但是一旦可观察对象多起来就会特别繁琐,要写很多冗余代码.我们可以通过模板技术来简化.

这里的主要思路就是要实现配置类来配置多个可观察对象及其索引,使用`std::tuple`存储多个可观察对象,然后通过`subscribe<INDEX>()`以及`notify<INDEX>()`来进行注册和通知.

```C++
template <typename... Args>
class observer
{
  public:
    observer() = default;

    observer(observer const &) = delete;
    observer &operator=(observer const &) = delete;

  private:
    template <typename T>
    friend class observable;

    using signal = subject<Args...>;
    signal signal_;
};

template <typename T>
class observable
{
  private:
    using observers_enum = typename T::observers_enum;
    using observers_table = typename T::observers_table;

  public:
    template <observers_enum K, typename Fn>
    auto subscribe(Fn &&fn)
    {
        return std::get<static_cast<std::size_t>(K)>(signals_).signal_.subscribe(std::forward<Fn>(fn));
    }

  protected:
    observable() = default;

    template <observers_enum K, typename... Args>
    void notify(Args... args) const
    {
        return std::get<static_cast<std::size_t>(K)>(signals_).signal_(std::forward<Args>(args)...);
    }

  private:
    observers_table signals_;
};
```

类通过继承自`observable<T>`来获取可观察能力,而`T`则需要配置如下信息:

```C++
struct T
{
    using observers_enum = enum class type;
    using observers_table = std::tuple<observer...>;
};
```

使用示例如下:

```C++
enum class signal
{
    show=0,
    close
};

struct Signals
{
    using observers_enum = signal;
    using observers_table = std::tuple<observer<>, observer<bool>>;
};

class Viewer : public observable<ViewSignals>
{
    void  show(){
        notify<signal::show>();//通知订阅者
    }
};

class Application
{
  public:
    explicit Application(Viewer &view) : viewer_{view}
    {
        //订阅
        viewer_.subscribe<signal::show>([this]() {
            onViewShow();
        });
    }

  private:
    void onViewShow()
    {
        std::cout << "Application::onViewShow called." << std::endl;
    }
};
```

## 观察者完整实现

```C++
#pragma once

#include <functional>
#include <map>
#include <type_traits>

template <typename... Args>
class subject;
class scope_subscription;

class subscription
{
  public:
    subscription(subscription const &) = default;
    subscription &operator=(subscription const &) = default;
    subscription(subscription &&) = default;
    subscription &operator=(subscription &&) = default;

    void unsubscribe() const
    {
        if (!action_)
            return;
        action_();
    }

    explicit operator bool() const
    {
        return !!action_;
    }

  protected:
    friend class scope_subscription;
    template <typename... Args>
    friend class subject;

    subscription() = default;

    subscription(std::function<void()> const &fn) : action_{fn} {};

  private:
    std::function<void()> action_{};
};

class scope_subscription
{
  public:
    scope_subscription() = default;
    explicit scope_subscription(subscription &&sub) : target_{sub} {};

    ~scope_subscription()
    {
        if (!target_)
            return;
        try
        {
            target_.unsubscribe();
        }
        catch (...)
        {
        }
    }

    scope_subscription(scope_subscription const &) = delete;
    scope_subscription &operator=(scope_subscription const &) = delete;
    scope_subscription(scope_subscription &&) = default;
    scope_subscription &operator=(scope_subscription &&) = default;

  private:
    subscription target_{};
};

template <typename... Args>
class subject
{
  public:
    using observer_type = void(Args...);

  public:
    template <typename Callable>
    auto subscribe(Callable &&observer) -> subscription
    {
        static_assert(std::is_convertible_v<Callable, std::function<observer_type>>,
                      "The provided observer object is not callable or not compatible with subject");
        auto key = next();
        observers_.emplace(key, observer);
        return subscription{[this, key]() {
            unsubscribe(key);
        }};
    }

    void notify(Args &&... args) const
    {
        for (auto &&kv : observers_)
        {
            kv.second(std::forward<Args>(args)...);
        }
    }

    void operator()(Args &&... args) const
    {
        return notify(std::forward<Args>(args)...);
    }

    auto size() const noexcept
    {
        return observers_.size();
    }

  public:
    subject() = default;
    subject(subject const &) = delete;
    subject &operator=(subject const &) = delete;
    subject(subject &&) = default;
    subject &operator=(subject &&) = default;

  private:
    void unsubscribe(int key) noexcept
    {
        observers_.erase(key);
    }

    int next() const
    {
        static int v = 0;
        return v++;
    }

  private:
    std::map<int, std::function<observer_type>> observers_;
};
```

## 总结

C++语言由于模板特性,可以在编码实现上采取更多措施来获取观察者模式的收益,同时又避免其它语言实现所存在的问题.
