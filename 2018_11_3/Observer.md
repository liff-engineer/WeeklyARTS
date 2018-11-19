# 模板技术在C++中实现观察者模式的应用

观察者模式是设计模式中的一种,实现起来相对比较简单,但是在C++的世界里,总有那么点儿不一样,你自然是可以用Java等语言的写法来实现观察者模式,也可以借用C++的能力采用不同的方式实现,比较典型的就是Qt的信号与槽,没有继承关系,只有接口约束,甚至说借用`std::bind`以及`Lambda`等,接口约束也不是必须的.

当然Qt的信号与槽虽然强大,毕竟不是存粹的C++语言实现,如果寻求标准C++实现,也有很多候选项,`Boost.Signals2`是`Boost`库中对应的实现。

而在这里,将展示如何利用模板技术更为便利地使用信号与槽.

## 问题

假设要为GUI应用程序实现个`Window`类,那么不可避免地,需要有观察者需要关注`Window`是否可见,关闭时能否关闭:

```C++
class Window {
public:
    void show();
    bool close(bool force_close = false);
};
```

那么如果用`Boost.Signals2`来实现呢? 需要为其声明两个信号,然后提供触发信号操作,由外部注册:

```C++

class Window {
public:
    boost::signals2::signal<void> show_signal;
    boost::signals2::signal<bool(bool)> close_signal;

private:
    void notifyShow() {
        return show_signal();
    }

    std::optional<bool> notifyClose(bool force_close) {
        return close_signal(force_close);
    }
};

void example(Observer& observer,Window& window){
    window.show_signal.connect([&](){ observer.onWindowShow(); });
    window.close_signal.connect([&](bool b){ return observer.onWindowClose(b); });
}
```

可以看到,一旦信号多起来,命名、连接、触发都会变得繁琐,能否有办法使得信号与槽使用起来更为简单?

## 问题分析

信号与槽处理规律性非常强,就是声明信号、连接信号与槽、触发信号,不同之处在于信号、槽的参数类型和返回值不同,如果能够将不同的信号作为相同的元素存储和操作,即可实现一致的接口,能够提供出通用的基类,假设信号均为`void(void)`,那么可以采用类似如下实现:

```C++

class Signals
{
public:
    void register_slot(int signal_id,std::function<void(void)> slot){
        signals_[signal_id].connect(slot);
    }
    void notify(int signal_id){
        return signals_[signal_id]();
    }
    std::vector<boost::signals2::signal<void(void)> signals_;
};
```

这样只需要继承自`Signals`即可拥有触发多个信号与槽的能力,考虑到信号的原型不一样,可以用`Mixin`和可变参数模板将其改写成可配置形式:

```C++

//配置示例
struct example_signals
{
    enum signal_id
    {
        signal0,
        signal1,
        signal2
    };

    using signal_type = boost::signals2::signal<void(void)>;
    using result_type = typename signal_type::result_type;
};

template<typename T>
class Signal
{
    using signal_type =typename T::signal_type;
    using result_type =typename T::result_type;
public:
    template<typename Fn>
    void register_slot(int signal_id,Fn && fn){
        signals_[signal_id].connect(fn);
    }

    template<typename... Args>
    result_type notify(int signal_id,Args&&... args){
        return signals_[signal_id](std::forward<Args>(args)...);
    }

    std::vector<signal_type> signals_;
};

class example_class:public Signals<example_signals>{
    ;//可以注册信号和发出通知
}
```

需要注意的是,`Signals`的很多内容均可以在编译期确定,而且借用`std::tuple`能够存储不同类型的`signal`,那么改如何实现?

## 使用`std::tuple`及模板技术

实际上可能会触发各种信号,信号的类型不尽相同,那么如何存储这些信号呢?答案是`std::tuple`,譬如之前`Window`的`show`和`close`:

```C++
struct example_signals
{
    enum signal_id{
        show = 0,
        close = 1,
    };
    std::tuple<boost::signals2::signal<void(void)>,boost::signals2::signal<bool(bool)>> signals;
};
```

这样,通过使用`std::get<show>(signals)`即可得到`show`的信号,从而进行连接、触发等操作。

为了获取信号类型和返回结果方便,将信号进行封装：

```C++
template<typename Signature>
struct Observer
{
    using Signal = boost::signals2::signal<Signature>;
    using SignalResult = typename Signal::result_type;
    Signal signal_;
};
```

这时可以将`example_signals`定义如下:

```C++
struct example_signals
{
    enum {
        show = 0,
        close = 1,
    };
    using signals_table = std::tuple<Observer<void(),Observer<bool(bool)>>;
};
```

而之前的`Signals`可以改写为如下形式:

```C++
template<typename Signals>
class Observable
{
    using signals_table = typename Signals::signals_table;
public:
    template<std::size_t SignalId,typename Fn>
    boost::signals2::connection register_slot(Fn&& fn){
        return std::get<SignalId>(signals_).signal_.connect(std::forward<Fn>(fn));
    }

    template<std::size_t SignalId,typename... Args>
    typename std::tuple_element_t<SignalId,signals_table>::SignalResult notify(Args&&... args){
        return std::get<SignalId>(signals_).signal_(std::forward<Args>(args)...);
    }

    signals_table signals_;
}
```

## 完整实现及样例

```C++
#include <boost/signals2.hpp>
#include <tuple>
#include <utility>

template<typename Signature>
class Observer {
public:
    Observer(Observer const&) = delete;
    Observer& operator=(Observer const&) = delete;
    Observer() = default;
private:
    template<typename Observers>
    friend class Observable;

    using Signal = boost::signals2::signal<Signature>;
    using SignalResult = typename Signal::result_type;
    Signal signal_;
};

template<typename Observers>
class Observable
{
private:
    using ObserverTable = typename Observers::ObserverTable;
public:
    template<std::size_t ObserverId,typename F>
    boost::signals2::connection Register(F&& f) {
        return std::get<ObserverId>(signals_).signal_.connect(std::forward<F>(f));
    }
protected:
    Observable() = default;

    template<std::size_t ObserverId,typename... Args>
    typename std::tuple_element_t<ObserverId, ObserverTable>::SignalResult Notify(Args&&... args) const {
        return std::get<ObserverId>(signals_).signal_(std::forward<Args>(args)...);
    }
private:
    ObserverTable signals_;
};

#include <iostream>
#include <optional>

struct WindowObservers {
    enum { ShowEvent,CloseEvent };
    using ObserverTable = std::tuple<Observer<void()>, Observer<bool(bool force_close)>>;
};


class Window :public Observable<WindowObservers>
{
public:
    void Show() {
        std::cout << "Window::Show called." << std::endl;

        Notify<WindowObservers::ShowEvent>();

        std::cout << "Window::Show handled." << std::endl << std::endl;
    }

    bool Close(bool force_close = false) {
        std::cout << "Window::Close called: force_close == "
            << std::boolalpha << force_close << "." << std::endl;

        const std::optional<bool> can_close{
            Notify<WindowObservers::CloseEvent>(force_close)
        };

        std::cout << "Window::Close handled. can_close == "
            << std::boolalpha << (!can_close || *can_close) << "."
            << std::endl << std::endl;

        const bool closing{ force_close || !can_close || *can_close };
        if (closing) {

        }
        return closing;
    }

};

class Application {
public:
    explicit Application(Window& window) :window_(window) {

        window_.Register<WindowObservers::ShowEvent>([this]() { OnWindowShow(); });
        window_.Register<WindowObservers::CloseEvent>([this](bool force_close) { return OnWindowClose(force_close); });
    }
private:
    void OnWindowShow() {
        std::cout << "Application::OnWindowShow called." << std::endl;
    }

    bool OnWindowClose(bool force_close) {
        std::cout << "Application::WindowClose called: force_close == "
            << std::boolalpha << force_close << "." << std::endl;
        return force_close;
    }

    Window& window_;
};

void example_signals() {
    Window window;
    Application application{ window };

    window.Show();
    window.Close(false);
    window.Close(true);
}

```

## 总结

通过使用模板技术,可以大量减少样板代码,能够提供表达能力更强的实现,值得好好学习和摸索.

## 参考及来源

- [Observer vs Pub-Sub pattern](https://hackernoon.com/observer-vs-pub-sub-pattern-50d3b27f838c)
- [Publish–subscribe pattern](https://en.wikipedia.org/wiki/Publish%E2%80%93subscribe_pattern#Message_filtering)
- [Observer pattern](https://en.wikipedia.org/wiki/Observer_pattern)
- [Event-Carried State Transfer Pattern](http://www.grahambrooks.com/event-driven-architecture/patterns/stateful-event-pattern/)

- [Messaging and Signaling in C++](https://meetingcpp.com/blog/items/messaging-and-signaling-in-cplusplus.html)
- [Performance of a C++11 Signal System](https://testbit.eu/2013/cpp11-signal-system-performance)
- [Boost.Signals2](https://www.boost.org/doc/libs/1_68_0/doc/html/signals2/tutorial.html)
- [**Making Boost.Signals2 More OOP‐Friendly**](https://thehermeticvault.com/software-development/making-boost-signals2-more-oop-friendly)
