# [C++中如何模拟实现多态](https://mropert.github.io/2017/11/30/polymorphic_ducks/)

> C++更倾向于静态多态.但是有些场景下,确实需要动态多态,这时我们就会发现我们陷入了`virtual`耗子洞.不要绝望,这里有一些方法可以避免这种疯狂.

我讨厌`virtual`关键字.继承让我感到恐惧.我总能引出很多技术原因来解释为什么.那些比我聪明许多的人们已经讨论过为什么这是最糟糕的一种组合形式.

但是从内心深处,真正原因是当我第一次使用 C++来替代 C,我制作了一张很好的 UML 类图,然后以编写了数个不同层次的类,却只有一个具体实现(并且目前来讲可能依然如此).我们都有自己的问题(原话为圣经里的,类似于我们都有自己的十字架要背负).

直到今天,我都尽量避免动态多态,不过毕竟有些场景下这是恰当的工具.当你发现没有办法再编译期知道概念的具体实现,或者你希望你的业务逻辑可以单独测试,并且不想将所有内容都放到模板中时,最终你需要使用它.

问题不在于范式,而在于具体实施.我们只希望为我们所使用的付出代价,虽然我们只需要运行时多态(付出虚函数调用的代价),我们却得到了更紧密的耦合以及丢失常规类型信息作为"奖赏".这非常糟糕.

## 传统继承的问题

考虑一下代码:

```c++
class Drawable {
public:
   virtual ~Drawable() {}
   virtual void draw(Display& display) const = 0;
};
```

我们有一堆对象想要进行绘制.我们无法知道在运行时有哪些对象,只有在特定的时间我们遍历他们,并通过`draw()`将其绘制到`Display`上.这就是我们所关心的.但是我们为我们的麻烦付出了更多.

所有的可绘制对象必须继承自`Drawable`,实现`draw()`,这就意味着它们需要知道如何绘制自己(或者保存、加载、计算之类的).这明显与分离关注点的原则相冲突.我可以不再继续将问题列出来,毕竟已经这就以及使得我们的实现耦合起来无法回头了.

但是问题还在继续:

- 我们无法对对象进行复制构造或者复制赋值,除非我们可以在所有地方实现`clone()`虚方法.
- 我们无法拥有对象列表(数组、集合等等),我们需要使用`Drawable*`列表.这阻止了我们使用那些期望是值而不是指针的标准算法.
- 我们无法以值方式存储它们,持有容器必须`new`出来这些对象,而不能将其放到连续的缓冲或者堆栈上.这对现代 CPU 的缓存不友好.
- 我们的代码被打乱了,每次我们需要创建 drawable 必须使用`new`或者`std::make_unique`.

## 备选方案

Louis Dionne 在他的[CppCon 2017 演讲](https://www.youtube.com/watch?v=gVGtNFg4ay0)中展示了一系列备选方案来解决这个问题,我发现确实很有趣,但是都比较复杂.

因而,我建议我们简单地使用经过时间验证过的技术-WWSPD:Sean Parent 会怎么做(What Would Sean Parent Do)?

如果你的答案是`std::rotate()`,不错的尝试,不过这次这个不是正确的答案.正确的答案在他的演讲中展示了:[Better Code: Runtime Polymorphism](https://www.youtube.com/watch?v=QGcVXgEVMJg).以下是如何实现:

### 擦除类型

首先我们建立我们想要使用的概念,并提供接口,就像我们以最初的方式实现的那样:

```C++
struct concept_t {
   virtual ~concept_t() {}
   virtual void draw() const = 0;
};
```

经过之前我所描述的问题,你可能会感到受到了欺骗.但是请耐心等待,接下来我们创建一个模板实现:

```C++
template <typename T>
struct model_t : public concept_t {
  model_t() = default;
  model_t(const T& v) : m_data(v) {}
  model_t(T&& v) : m_data(std::move(v)) {}

  void draw() const { m_data.draw(); }

  T m_data;
};
```

看起来已经走上正轨了,不过依然感觉还差一些东西......让我们通过将其包裹到类中来完成类型擦除:

```C++
class drawable {
  struct concept_t { /* ... */ };
  template <typename T> struct model_t : public concept_t { /* ... */ };
public:
  drawable() = default;

  drawable(const drawable&) = delete;
  drawable(drawable&&) = default;

  template <typename T>
  drawable(T&& impl)
    : m_impl(new model_t<std::decay_t<T>>(std::forward<T>(impl))) {}

  drawable& operator=(const drawable&) = delete;
  drawable& operator=(drawable&&) = default;

  template <typename T>
  drawable& operator=(T&& impl) {
    m_impl.reset(new model_t<std::decay_t<T>>(std::forward<T>(impl)));
    return *this;
  }

  void draw() const { m_impl->draw(); }

private:
  std::unique_ptr<concept_t> m_impl;
};
```

最终我们可以以多态常规对象的方式来操作对象:

```C++
std::vector<drawable> objects;
objects.push_back(Rectangle(12, 42));
objects.push_back(Circle(10));
objects.push_back(Sprite("assets/monster.png"));

for (const auto& o : objects)
   o.draw();
```

### 摆脱成员函数

这样很好,但是我们依然没有完成我们最重要的需求:将对象从它们的绘制实现中解耦.幸运的是,这个现在非常容易实现.我们只需要使用函数调用来替换掉成员函数调用:

```C++
class drawable {
  struct concept_t {
    virtual ~concept_t() {}
    virtual void do_draw() const = 0;
  };
  template <typename T>
  struct model_t : public concept_t {
    model_t() = default;
    model_t(const T& v) : m_data(v) {}
    model_t(T&& v) : m_data(std::move(v)) {}

    void do_draw() const override { draw(m_data); }

    T m_data;
  };
public:
  drawable() = default;

  drawable(const drawable&) = delete;
  drawable(drawable&&) = default;

  template <typename T>
  drawable(T&& impl)
    : m_impl(new model_t<std::decay_t<T>>(std::forward<T>(impl))) {}

  drawable& operator=(const drawable&) = delete;
  drawable& operator=(drawable&&) = default;

  template <typename T>
  drawable& operator=(T&& impl) {
    m_impl.reset(new model_t<std::decay_t<T>>(std::forward<T>(impl)));
    return *this;
  }

  friend void draw(const drawable& d) { d.m_impl->do_draw(); }

private:
  std::unique_ptr<concept_t> m_impl;
};
```

我们使用[ADL](http://en.cppreference.com/w/cpp/language/adl)来完成剩下的事情.只要编译期能够找到`draw(const T&)`函数,这个就能正常工作.下一步我们可以思考该如何添加参数.

最终我们的调用代码可能是如下形式:

```C++
for (const auto& o : objects)
   draw(o, display);
```

### 组合起来

我们展示了如何打破对象表示以及那些使用它们的函数之间的依赖.我们实现了运行时多态,并且没有影响到我们的设计.但是我们依然有一些承诺没有达成:

- 仍然无法复制对象
- 我们通过`new`将我们的对象保存在容器外面
- 需要写一些样板代码,针对每种概念可能都需要大量的复制黏贴操作

在后面的文章中,将会看一看我们是否以及如何解决这些问题,但是首先必须要解决一个更为重要的问题:我们该如何称呼这种技术? 幸运的是我在[Twitter](https://twitter.com/MatRopert/status/936362895000076288)中提问并得到了解答.

所以下一次你看到继承和`virtual`来达成运行时多态,感谢 TEPS(Type Erasure Parent Style)!

你可以在[这里](https://godbolt.org/g/9PZALq)找到最终源代码.
